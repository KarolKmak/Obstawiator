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

    const { results: matchBets } = await db.prepare("SELECT BetMatch.homeScore, BetMatch.awayScore, Users.name, BetMatch.winner FROM BetMatch INNER JOIN Users ON BetMatch.userID=Users.ID WHERE BetMatch.matchID = ? AND BetMatch.userID != ?").bind(reqBody.matchID, userID).all();

    const { results: userBetResults } = await db.prepare("SELECT homeScore, awayScore, winner FROM BetMatch WHERE userID = ? AND matchID = ?").bind(userID, reqBody.matchID).all();

    return new Response(JSON.stringify({ userBet: userBetResults[0], matchBets: matchBets }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
