export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    const { champion, topScorer, secret } = reqBody;

    // Prosta autoryzacja (opcjonalnie, można pominąć jeśli nie ma sekretu)
    // if (secret !== "TWOJ_SEKRET") {
    //   return new Response("Unauthorized", { status: 401 });
    // }

    if (!champion || !topScorer) {
      return new Response(JSON.stringify({ message: "Brak mistrza lub króla strzelców w żądaniu." }), { status: 400 });
    }

    // 1. Pobranie aktualnego stanu rozliczenia
    const currentFinal = await db.prepare("SELECT champion, topScorer FROM ChampionBet LIMIT 1").first();

    // Jeśli już rozliczono te same dane, nie rób nic
    if (currentFinal && currentFinal.champion === champion && currentFinal.topScorer === topScorer) {
      return new Response(JSON.stringify({ message: "Wyniki są już rozliczone z tymi samymi danymi." }), { status: 200 });
    }

    // 2. Pobierz wszystkich użytkowników
    const { results: users } = await db.prepare("SELECT ID, championBet, topScorerBet FROM UserScores").all();

    const batchStatements = [];
    let settledCount = 0;

    for (const user of users) {
      let pointsToAdd = 0;

      // Sprawdzamy czy użytkownik trafił (ignorujemy wielkość liter)
      if (user.championBet && user.championBet.toLowerCase().trim() === champion.toLowerCase().trim()) {
        pointsToAdd += 15;
      }

      if (user.topScorerBet && user.topScorerBet.toLowerCase().trim() === topScorer.toLowerCase().trim()) {
        pointsToAdd += 10;
      }

      if (pointsToAdd > 0) {
        batchStatements.push(
          db.prepare("UPDATE UserScores SET points = points + ? WHERE ID = ?")
            .bind(pointsToAdd, user.ID)
        );
        settledCount++;
      }
    }

    // 3. Aktualizacja tabeli ChampionBet
    if (currentFinal) {
      batchStatements.push(
        db.prepare("UPDATE ChampionBet SET champion = ?, topScorer = ?")
          .bind(champion, topScorer)
      );
    } else {
      batchStatements.push(
        db.prepare("INSERT INTO ChampionBet (ID, champion, topScorer) VALUES (0, ?, ?)")
          .bind(champion, topScorer)
      );
    }

    if (batchStatements.length > 0) {
      await db.batch(batchStatements);
    }

    return new Response(JSON.stringify({
      message: `Pomyślnie rozliczono typy długoterminowe. Punkty przyznano ${settledCount} użytkownikom.`,
      champion: champion,
      topScorer: topScorer
    }), {
      status: 201,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}
