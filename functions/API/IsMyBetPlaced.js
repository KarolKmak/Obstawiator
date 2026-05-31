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

    const { results } = await db.prepare("SELECT matchID FROM BetMatch WHERE userID = ? AND matchID = ?").bind(reqBody.ID, reqBody.matchID).all();

    if (results.length > 0) {
      return new Response(JSON.stringify({ userBet: results[0] }), { status: 200, headers: { "Content-Type": "application/json" } });
    } else {
      return new Response(JSON.stringify({ userBet: null }), { status: 200, headers: { "Content-Type": "application/json" } });
    }

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
