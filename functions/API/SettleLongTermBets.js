export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    const { champion, topScorer } = reqBody;

    if (!champion || !topScorer) {
      return new Response(JSON.stringify({ message: "Brak mistrza lub króla strzelców w żądaniu." }), { status: 400 });
    }

    // 1. Pobranie aktualnego stanu rozliczenia (starych wyników)
    const oldResults = await db.prepare("SELECT champion, topScorer FROM ChampionBet LIMIT 1").first();

    // Jeśli już rozliczono te same dane, nie rób nic
    if (oldResults && oldResults.champion === champion && oldResults.topScorer === topScorer) {
      return new Response(JSON.stringify({ message: "Wyniki są już rozliczone z tymi samymi danymi." }), { status: 200 });
    }

    // 2. Pobierz wszystkich użytkowników, którzy mają jakiekolwiek typy lub punkty
    const { results: users } = await db.prepare("SELECT ID, championBet, topScorerBet FROM UserScores").all();

    const batchStatements = [];
    let updatedCount = 0;

    for (const user of users) {
      let pointsToAdjust = 0;

      // --- KROK A: COFNIĘCIE STARYCH PUNKTÓW ---
      if (oldResults) {
        if (user.championBet && oldResults.champion && user.championBet.toLowerCase().trim() === oldResults.champion.toLowerCase().trim()) {
          pointsToAdjust -= 15;
        }
        if (user.topScorerBet && oldResults.topScorer && user.topScorerBet.toLowerCase().trim() === oldResults.topScorer.toLowerCase().trim()) {
          pointsToAdjust -= 10;
        }
      }

      // --- KROK B: NALICZENIE NOWYCH PUNKTÓW ---
      if (user.championBet && user.championBet.toLowerCase().trim() === champion.toLowerCase().trim()) {
        pointsToAdjust += 15;
      }
      if (user.topScorerBet && user.topScorerBet.toLowerCase().trim() === topScorer.toLowerCase().trim()) {
        pointsToAdjust += 10;
      }

      // Jeśli suma zmian jest niezerowa, dodajemy do batcha
      if (pointsToAdjust !== 0) {
        batchStatements.push(
          db.prepare("UPDATE UserScores SET points = points + ? WHERE ID = ?")
            .bind(pointsToAdjust, user.ID)
        );
        updatedCount++;
      }
    }

    // 3. Aktualizacja tabeli ChampionBet (zapisanie nowych oficjalnych wyników)
    if (oldResults) {
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
      message: `Pomyślnie zaktualizowano typy długoterminowe. Skorygowano punkty dla ${updatedCount} użytkowników.`,
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
