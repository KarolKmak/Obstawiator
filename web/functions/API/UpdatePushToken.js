export async function onRequestPost(context) {
  try {
    const reqBody = await context.request.json();
    const db = context.env.obstawiatorDB;
    let sessionToken = context.request.headers.get("Authorization");
    if (!sessionToken && reqBody.sessionToken) sessionToken = reqBody.sessionToken;

    const userID = parseInt(reqBody.ID);
    const pushToken = reqBody.pushToken;
    const platform = reqBody.platform || 'unknown';

    if (!userID || !sessionToken || !pushToken) {
      return new Response(JSON.stringify({ message: "Brak danych" }), { status: 400 });
    }

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ?")
      .bind(userID, sessionToken).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Nieautoryzowany" }), { status: 401 });
    }

    // Używamy tabeli UserPushTokens, aby wspierać wiele urządzeń jednego użytkownika
    // Najpierw usuwamy ten sam token jeśli istniał pod innym ID (rzadkie, ale możliwe)
    await db.prepare("DELETE FROM UserPushTokens WHERE pushToken = ?").bind(pushToken).run();

    // Wstawiamy nowy token lub aktualizujemy czas ostatniego użycia
    await db.prepare("INSERT INTO UserPushTokens (userID, pushToken, platform, lastUpdated) VALUES (?, ?, ?, ?)")
      .bind(userID, pushToken, platform, Date.now()).run();

    return new Response(JSON.stringify({ message: "Token zsynchronizowany" }), { status: 200 });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500 });
  }
}
