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

    if (!sessionToken || !reqBody.ID) {
      return new Response(JSON.stringify({ message: "Brak danych autoryzacyjnych (ID lub token)" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const { results } = await db.prepare("SELECT UserScores.ID AS ID, UserScores.championBet, UserScores.topScorerBet, UserScores.points, Users.name FROM UserScores INNER JOIN Users ON UserScores.ID=Users.ID ORDER BY UserScores.points DESC").all();

    return new Response(JSON.stringify(results), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
