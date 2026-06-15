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

    if (user) {
      const limit = parseInt(reqBody.limit) || 10;
      const offset = reqBody.offset !== undefined ? parseInt(reqBody.offset) : (reqBody.finishedMatchesOffset !== undefined ? parseInt(reqBody.finishedMatchesOffset) : 0);
      const finished = reqBody.finished === true || reqBody.finished === 1 || reqBody.finished === "true" || reqBody.finishedMatchesOffset !== undefined;

      if (finished) {
        const { results } = await db.prepare("SELECT Matches.ID, host, guest, matchStart, Matches.homeScore, Matches.awayScore, betVisible, isGroupStage, Matches.winner, (BetMatch.homeScore IS NOT NULL) as hasBet FROM Matches LEFT JOIN BetMatch ON Matches.ID = BetMatch.matchID AND BetMatch.userID = ? WHERE matchFinished = 1 ORDER BY matchStart DESC LIMIT ? OFFSET ?").bind(userID, limit, offset).all();
        return new Response(JSON.stringify(results), { status: 200, headers: { "Content-Type": "application/json" } });
      } else {
        const { results } = await db.prepare("SELECT Matches.ID, host, guest, matchStart, homeScore, awayScore, betVisible, isGroupStage, (BetMatch.homeScore IS NOT NULL) as hasBet FROM Matches LEFT JOIN BetMatch ON Matches.ID = BetMatch.matchID AND BetMatch.userID = ? WHERE matchFinished = 0 ORDER BY matchStart ASC LIMIT ? OFFSET ?").bind(userID, limit, offset).all();
        return new Response(JSON.stringify(results), { status: 200, headers: { "Content-Type": "application/json" } });
      }
    } else {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }
  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
