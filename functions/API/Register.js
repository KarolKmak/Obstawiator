export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const { email, password, name, token } = reqBody;

    // Walidacja
    if (token != 1234) {
      return new Response(JSON.stringify({ message: "Niepoprawny token", result: 3 }), { status: 403, headers: { "Content-Type": "application/json" } });
    }
    if (!email || !email.includes('@')) {
      return new Response(JSON.stringify({ message: "Niepoprawny adres e-mail" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }
    if (!password || password.length < 6) {
      return new Response(JSON.stringify({ message: "Hasło musi mieć co najmniej 6 znaków" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const db = context.env.obstawiatorDB;

    // Sprawdzanie czy użytkownik istnieje
    const checkEmail = await db.prepare("SELECT 1 FROM Users WHERE email = ?").bind(email.toLowerCase()).first();
    if (checkEmail) {
      return new Response(JSON.stringify({ message: 'Ten adres e-mail jest już zajęty', result: '1' }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    const checkUser = await db.prepare("SELECT 1 FROM Users WHERE name = ?").bind(name).first();
    if (checkUser) {
      return new Response(JSON.stringify({ message: "Nazwa użytkownika już zajęta", result: 2 }), { status: 403, headers: { "Content-Type": "application/json" } });
    }

    // Hashowanie hasła (PBKDF2)
    const salt = crypto.getRandomValues(new Uint8Array(16));
    const encoder = new TextEncoder();
    const baseKey = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
    const hashBuffer = await crypto.subtle.deriveBits({
      name: "PBKDF2",
      salt: salt,
      iterations: 100000,
      hash: "SHA-256",
    }, baseKey, 256);

    const combined = new Uint8Array(salt.length + hashBuffer.byteLength);
    combined.set(salt);
    combined.set(new Uint8Array(hashBuffer), salt.length);
    const hashedPassword = btoa(String.fromCharCode(...combined));

    // Wyszukiwanie nowego ID
    const lastUser = await db.prepare("SELECT MAX(ID) as ID FROM Users").first();
    const newID = (lastUser?.ID || 0) + 1;

    // Generowanie tokena sesji (ważny miesiąc)
    const sessionToken = crypto.randomUUID();
    const expiresAt = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60); // 30 dni

    // Zapis do bazy
    await db.batch([
      db.prepare("INSERT INTO Users (ID, name, email, password, sessionToken, tokenExpires) VALUES (?, ?, ?, ?, ?, ?)")
        .bind(newID, name, email.toLowerCase(), hashedPassword, sessionToken, expiresAt),
      db.prepare("INSERT INTO UserScores (ID, points, betChanged) VALUES (?, ?, ?)")
        .bind(newID, 0, 0)
    ]);

    return new Response(JSON.stringify({ message: "Zarejestrowano użytkownika", result: 0, userID: newID, sessionToken: sessionToken }), {
      status: 201,
      headers: { "Content-Type": "application/json" }
    });
  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}
