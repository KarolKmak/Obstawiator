export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    let sessionToken = context.request.headers.get("Authorization");
    if (!sessionToken && reqBody.sessionToken) sessionToken = reqBody.sessionToken;

    const userID = parseInt(reqBody.ID);

    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(userID, sessionToken, Date.now()).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const { results: matchResults } = await db.prepare("SELECT matchStart, matchFinished FROM Matches WHERE ID = ?").bind(reqBody.matchID).all();

    if (matchResults.length === 0) {
      return new Response(JSON.stringify({ message: "Mecz nie istnieje" }), { status: 404 });
    }

    // Sprawdzanie czy mecz nie jest już zakończony
    if (matchResults[0].matchFinished === 1) {
      return new Response(JSON.stringify({ message: "Mecz został już zakończony, nie można zmieniać zakładów" }), { status: 403 });
    }

    // Sprawdzanie czy gra się jeszcze nie rozpoczęła
    if (Date.now() > matchResults[0].matchStart) {
      return new Response(JSON.stringify({ message: "Nie udało się dodać zakładu, za późno", result: 1 }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    const { results: betPlacedResults } = await db.prepare("SELECT userID FROM BetMatch WHERE userID = ? AND matchID = ?").bind(userID, reqBody.matchID).all();

    if (betPlacedResults.length > 0) {
      let placeBet;
      if (reqBody.winner === 0 || reqBody.winner === 1) {
        placeBet = db.prepare("UPDATE BetMatch SET homeScore = ?, awayScore = ?, winner = ? WHERE userID = ? AND matchID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.winner, userID, reqBody.matchID);
      } else {
        placeBet = db.prepare("UPDATE BetMatch SET homeScore = ?, awayScore = ? WHERE userID = ? AND matchID = ?").bind(reqBody.homeScore, reqBody.awayScore, userID, reqBody.matchID);
      }
      await placeBet.run();
      return new Response(JSON.stringify({ message: "Pomyślnie zaktualizowano zakład" }), { status: 201, headers: { "Content-Type": "application/json" } });
    } else {
      const getNewID = db.prepare("SELECT MAX(ID) as ID FROM BetMatch");
      const getNewIDResult = await getNewID.run();
      const newID = (getNewIDResult.results[0].ID || 0) + 1;

      const placeBet = db.prepare("INSERT INTO BetMatch (userID, matchID, homeScore, awayScore, ID, winner) VALUES (?, ?, ?, ?, ?, ?)")
        .bind(userID, reqBody.matchID, reqBody.homeScore, reqBody.awayScore, newID, reqBody.winner);

      await placeBet.run();
      return new Response(JSON.stringify({ message: "Pomyślnie dodano zakład" }), { status: 201, headers: { "Content-Type": "application/json" } });
    }
  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
