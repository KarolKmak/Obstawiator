export async function onRequestPost(context) {
  try {
    const reqBody = await context.request.json();
    const db = context.env.obstawiatorDB;
    let sessionToken = context.request.headers.get("Authorization");
    if (!sessionToken && reqBody.sessionToken) sessionToken = reqBody.sessionToken;

    const userID = parseInt(reqBody.ID);
    const pushToken = reqBody.pushToken;

    if (!userID || !sessionToken || !pushToken) {
      return new Response(JSON.stringify({ message: "Brak danych" }), { status: 400 });
    }

    // Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ?")
      .bind(userID, sessionToken).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Nieautoryzowany" }), { status: 401 });
    }

    // Zapisz token w bazie (używamy REPLACE lub INSERT/UPDATE w zależności od silnika, tu SQLite w D1)
    // Zakładamy, że mamy kolumnę pushToken w Users lub oddzielną tabelę.
    // Dla uproszczenia dodajemy do tabeli Users lub aktualizujemy jeśli istnieje.
    await db.prepare("UPDATE Users SET pushToken = ? WHERE ID = ?")
      .bind(pushToken, userID).run();

    return new Response(JSON.stringify({ message: "Token zaktualizowany" }), { status: 200 });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd: " + error.message }), { status: 500 });
  }
}
