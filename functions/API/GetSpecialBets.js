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

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(userID, sessionToken, Date.now()).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const matchID = reqBody.matchID ? parseInt(reqBody.matchID) : null;

    let query = `
      SELECT
        sb.ID, sb.matchID, sb.betType, sb.betName, sb.options, sb.betTimeLimit, sb.betFinished, sb.pointsWin, sb.pointsLoss,
        bs.bet as userBet, bs.pointsAwarded
      FROM SpecialBets sb
      LEFT JOIN BetSpecial bs ON sb.ID = bs.specialBetID AND bs.userID = ?
    `;

    let params = [userID];

    if (matchID) {
      query += " WHERE sb.matchID = ? OR sb.matchID IS NULL";
      params.push(matchID);
    }

    query += " ORDER BY sb.betTimeLimit ASC";

    const { results } = await db.prepare(query).bind(...params).all();

    // Parsowanie opcji (JSON) jeśli istnieją
    const formattedResults = results.map(row => ({
      ...row,
      options: row.options ? JSON.parse(row.options) : null
    }));

    return new Response(JSON.stringify(formattedResults), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}
