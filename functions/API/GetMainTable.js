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

    // Fallback: sprawdź czy token jest w body (na wszelki wypadek)
    if (!sessionToken && reqBody.sessionToken) {
      sessionToken = reqBody.sessionToken;
    }

    const userID = parseInt(reqBody.ID);

    if (isNaN(userID) || !sessionToken) {
      return new Response(JSON.stringify({
        message: "Sesja wygasła. Zaloguj się ponownie.",
        debug: { receivedID: reqBody.ID, hasToken: !!sessionToken }
      }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(userID, sessionToken, Date.now()).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Pobieranie tabeli - obsługa obu możliwych nazw kolumn (ID lub userID) dla elastyczności
    const { results } = await db.prepare(`
      SELECT
        U.ID,
        S.championBet,
        S.topScorerBet,
        S.points,
        U.name
      FROM Users U
      INNER JOIN UserScores S ON U.ID = S.ID
      ORDER BY S.points DESC
    `).all();

    // Pobierz oficjalne wyniki turnieju
    const longTermResults = await db.prepare("SELECT champion, topScorer FROM ChampionBet LIMIT 1").first();
    const settledData = longTermResults ? {
      champion: longTermResults.champion,
      topScorer: longTermResults.topScorer,
      isSettled: !!(longTermResults.champion || longTermResults.topScorer)
    } : null;

    return new Response(JSON.stringify({
      standings: results,
      longTermResults: settledData
    }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
