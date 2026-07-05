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

    const callerID = parseInt(reqBody.ID);
    const targetUserID = parseInt(reqBody.targetUserID);

    if (isNaN(callerID) || isNaN(targetUserID) || !sessionToken) {
      return new Response(JSON.stringify({ message: "Brak wymaganych parametrów." }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    // Weryfikacja sesji dzwoniącego
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(callerID, sessionToken, Date.now()).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Pobierz imię docelowego gracza
    const targetUser = await db.prepare("SELECT name FROM Users WHERE ID = ?").bind(targetUserID).first();
    if (!targetUser) {
      return new Response(JSON.stringify({ message: "Użytkownik nie istnieje." }), { status: 404, headers: { "Content-Type": "application/json" } });
    }

    // Pobierz mecze i zakłady
    // Filtrowanie: jeśli to nie moje zakłady, pokazuj tylko te które się zaczęły, skończyły lub są oznaczone jako widoczne
    const isSelf = callerID === targetUserID;

    let query = `
      SELECT
        M.ID as matchID, M.host, M.guest, M.matchStart, M.homeScore as actualHome, M.awayScore as actualAway,
        M.matchFinished, M.betVisible, M.isGroupStage, M.winner as actualWinner,
        B.homeScore as betHome, B.awayScore as betAway, B.winner as betWinner
      FROM Matches M
      LEFT JOIN BetMatch B ON M.ID = B.matchID AND B.userID = ?
    `;

    if (!isSelf) {
      query += ` WHERE M.matchFinished = 1 OR M.matchStart < ? OR M.betVisible = 1 `;
    }

    query += ` ORDER BY M.matchStart DESC `;

    const stmt = isSelf
      ? db.prepare(query).bind(targetUserID)
      : db.prepare(query).bind(targetUserID, Date.now());

    const { results } = await stmt.all();

    // Przetwórz wyniki i oblicz punkty
    const processedResults = results.map(row => {
      let points = 0;
      let calculated = false;

      if (row.matchFinished && row.betHome !== null && row.betAway !== null) {
        calculated = true;

        const actualHome = row.actualHome;
        const actualAway = row.actualAway;
        const betHome = row.betHome;
        const betAway = row.betAway;
        const isGroupStage = row.isGroupStage === 'true' || row.isGroupStage === 1 || row.isGroupStage === true;

        if (isGroupStage) {
          // Logika punktacji grupowej
          let actualW;
          if (actualHome > actualAway) actualW = 0;
          else if (actualHome < actualAway) actualW = 1;
          else actualW = 2;

          let betW;
          if (betHome > betAway) betW = 0;
          else if (betHome < betAway) betW = 1;
          else betW = 2;

          const actualDiff = actualHome - actualAway;
          const betDiff = betHome - betAway;

          if (actualW === betW) points += 1;
          if (actualDiff === betDiff) points += 1;
          if (actualHome === betHome && actualAway === betAway) points = 5; // Dokładny wynik = 5 pkt
        } else {
          // Logika punktacji pucharowej
          if (row.betWinner !== null && row.actualWinner !== null && row.betWinner === row.actualWinner) {
            points += 2;
          }
          if (actualHome === betHome && actualAway === betAway) {
            points += 4;
          }
        }
      }

      return {
        matchID: row.matchID,
        host: row.host,
        guest: row.guest,
        matchStart: row.matchStart,
        actualHome: row.actualHome,
        actualAway: row.actualAway,
        matchFinished: row.matchFinished,
        betHome: row.betHome,
        betAway: row.betAway,
        betWinner: row.betWinner,
        isGroupStage: row.isGroupStage === 'true' || row.isGroupStage === 1 || row.isGroupStage === true,
        actualWinner: row.actualWinner,
        points: calculated ? points : null,
        isFuture: row.matchStart > Date.now() && !row.matchFinished
      };
    });

    return new Response(JSON.stringify({
      userName: targetUser.name,
      bets: processedResults
    }), { status: 200, headers: { "Content-Type": "application/json" } });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
