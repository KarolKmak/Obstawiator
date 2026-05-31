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

    if (!sessionToken) {
      return new Response(JSON.stringify({ message: "Brak autoryzacji" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła lub nieprawidłowa. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const getTime = db.prepare("SELECT matchStart FROM Matches WHERE ID = ?").bind(reqBody.matchID);
    const getTimeResult = await getTime.run();

    // Sprawdzanie czy gra się jeszcze nie rozpoczęła
    if (Date.now() > getTimeResult.results[0].matchStart) {
      return new Response(JSON.stringify({ message: "Nie udało się dodać zakładu, za późno", result: 1 }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    const checkIfBetPlaced = db.prepare("SELECT userID FROM BetMatch WHERE userID = ? AND matchID = ?").bind(reqBody.ID, reqBody.matchID);
    const checkIfBetPlacedResult = await checkIfBetPlaced.run();

    if (checkIfBetPlacedResult.results.length > 0) {
      let placeBet;
      if (reqBody.winner === 0 || reqBody.winner === 1) {
        placeBet = db.prepare("UPDATE BetMatch SET homeScore = ?, awayScore = ?, winner = ? WHERE userID = ? AND matchID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.winner, reqBody.ID, reqBody.matchID);
      } else {
        placeBet = db.prepare("UPDATE BetMatch SET homeScore = ?, awayScore = ? WHERE userID = ? AND matchID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.ID, reqBody.matchID);
      }
      await placeBet.run();
      return new Response(JSON.stringify({ message: "Pomyślnie zaktualizowano zakład" }), { status: 201, headers: { "Content-Type": "application/json" } });
    } else {
      const getNewID = db.prepare("SELECT MAX(ID) as ID FROM BetMatch");
      const getNewIDResult = await getNewID.run();
      const newID = (getNewIDResult.results[0].ID || 0) + 1;

      const placeBet = db.prepare("INSERT INTO BetMatch (userID, matchID, homeScore, awayScore, ID, winner) VALUES (?, ?, ?, ?, ?, ?)")
        .bind(reqBody.ID, reqBody.matchID, reqBody.homeScore, reqBody.awayScore, newID, reqBody.winner);

      await placeBet.run();
      return new Response(JSON.stringify({ message: "Pomyślnie dodano zakład" }), { status: 201, headers: { "Content-Type": "application/json" } });
    }
  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
