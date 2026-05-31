export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    const sessionToken = context.request.headers.get("Authorization");

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Date.now()).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Blokada czasowa (jeśli dotyczy Twojej logiki biznesowej)
    if (Date.now() > 1781204400000) {
      if (Date.now() < 1782673200000) {
        const checkIfChanged = await db.prepare("SELECT betChanged FROM UserScores WHERE ID = ?").bind(reqBody.ID).first();

        if (!checkIfChanged || checkIfChanged.betChanged == 0) {
          await db.prepare("UPDATE UserScores SET betChanged = 1, points = points - 5, championBet = ? WHERE ID = ?")
            .bind(reqBody.championBet, reqBody.ID).run();
          return new Response(JSON.stringify({ message: "Pomyślnie aktualizowano zakład, odjęto 5pkt" }), { status: 201, headers: { "Content-Type": "application/json" } });
        }

        await db.prepare("UPDATE UserScores SET championBet = ? WHERE ID = ?").bind(reqBody.championBet, reqBody.ID).run();
        return new Response(JSON.stringify({ message: "Pomyślnie aktualizowano zakład" }), { status: 201, headers: { "Content-Type": "application/json" } });
      }
      return new Response(JSON.stringify({ message: "Nie udało się dodać zakładu, za późno" }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    // Standardowa aktualizacja
    await db.prepare("UPDATE UserScores SET championBet = ?, topScorerBet = ? WHERE ID = ?")
      .bind(reqBody.championBet, reqBody.topScorerBet, reqBody.ID).run();

    return new Response(JSON.stringify({ message: "Pomyślnie dodano zakład" }), { status: 201, headers: { "Content-Type": "application/json" } });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
