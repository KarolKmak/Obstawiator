export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const { email, password } = reqBody;
    if (!email || !password) {
      return new Response(JSON.stringify({ message: "E-mail i hasło są wymagane" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const db = context.env.obstawiatorDB;
    const user = await db.prepare("SELECT ID, password FROM Users WHERE email = ?").bind(email.toLowerCase()).first();

    if (!user || !user.password) {
      return new Response(JSON.stringify({ message: "Nieprawidłowy e-mail lub hasło" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Weryfikacja hasła (PBKDF2)
    try {
      const combined = new Uint8Array(atob(user.password).split("").map(c => c.charCodeAt(0)));
      const salt = combined.slice(0, 16);
      const storedHash = combined.slice(16);

      const encoder = new TextEncoder();
      const baseKey = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
      const derivedBuffer = await crypto.subtle.deriveBits({
        name: "PBKDF2",
        salt: salt,
        iterations: 100000,
        hash: "SHA-256",
      }, baseKey, 256);

      const derivedHash = new Uint8Array(derivedBuffer);
      const isValid = crypto.subtle.timingSafeEqual(storedHash, derivedHash);

      if (isValid) {
        // Generowanie nowego tokena sesji
        const sessionToken = crypto.randomUUID();
        const expiresAt = Date.now() + (30 * 24 * 60 * 60 * 1000); // 30 dni w ms

        await db.prepare("UPDATE Users SET sessionToken = ?, tokenExpires = ? WHERE ID = ?")
            .bind(sessionToken, expiresAt, user.ID).run();

        return new Response(JSON.stringify({ message: "Zalogowano pomyślnie", userID: user.ID, sessionToken: sessionToken }), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }
    } catch (e) {
      console.error("Login verification error:", e);
    }

    return new Response(JSON.stringify({ message: "Nieprawidłowy e-mail lub hasło" }), { status: 401, headers: { "Content-Type": "application/json" } });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
}
