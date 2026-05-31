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

    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

    if (user) {
      if (reqBody.finishedMatchesOffset !== undefined && reqBody.finishedMatchesOffset !== null) {
        const { results } = await db.prepare("SELECT ID, host, guest, matchStart, homeScore, awayScore, betVisible, isGroupStage, winner FROM Matches WHERE matchFinished = 1 ORDER BY matchStart DESC LIMIT 10 OFFSET ?").bind(reqBody.finishedMatchesOffset).all();
        return new Response(JSON.stringify(results), { status: 200, headers: { "Content-Type": "application/json" } });
      } else {
        const { results } = await db.prepare("SELECT ID, host, guest, matchStart, homeScore, awayScore, betVisible, isGroupStage FROM Matches WHERE matchFinished = 0 ORDER BY matchStart ASC LIMIT 10").all();
        return new Response(JSON.stringify(results), { status: 200, headers: { "Content-Type": "application/json" } });
      }
    } else {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }
  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
