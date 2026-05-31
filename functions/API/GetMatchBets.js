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

    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const getMatchBets = db.prepare("SELECT BetMatch.homeScore, BetMatch.awayScore, Users.name, BetMatch.winner FROM BetMatch INNER JOIN Users ON BetMatch.userID=Users.ID WHERE BetMatch.matchID = ? AND BetMatch.userID != ?").bind(reqBody.matchID, reqBody.ID);
    const getMatchBetsResult = await getMatchBets.run();

    const getUserBet = db.prepare("SELECT homeScore, awayScore, winner FROM BetMatch WHERE userID = ? AND matchID = ?").bind(reqBody.ID, reqBody.matchID);
    const getUserBetResult = await getUserBet.run();

    return new Response(JSON.stringify({ userBet: getUserBetResult.results[0], matchBets: getMatchBetsResult.results }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
