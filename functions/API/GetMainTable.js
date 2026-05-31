export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    // Nagłówki są case-insensitive, ale .get() obsłuży to za nas
    const sessionToken = context.request.headers.get("Authorization");

    if (!sessionToken) {
      return new Response(JSON.stringify({ message: "Brak nagłówka autoryzacji" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const stmt = db.prepare("SELECT UserScores.ID, UserScores.championBet, UserScores.topScorerBet, UserScores.points, Users.name FROM UserScores INNER JOIN Users ON UserScores.ID=Users.ID ORDER BY UserScores.points DESC");
    const returnValue = await stmt.run();

    return new Response(JSON.stringify(returnValue.results), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
