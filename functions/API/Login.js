export async function onRequestPost(context) {
  let reqBody = {};
  try {
    reqBody = await context.request.json();
  } catch (e) {
    return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
  }

  const { email, password } = reqBody;
  if (!email || !password) {
    return Response.json({ message: "E-mail i hasło są wymagane" }, { status: 400 });
  }

  const db = context.env.obstawiatorDB;
  const user = await db.prepare("SELECT ID, password FROM Users WHERE email = ?").bind(email.toLowerCase()).first();

  if (!user || !user.password) {
    return Response.json({ message: "Nieprawidłowy e-mail lub hasło" }, { status: 401 });
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
      const expiresAt = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60); // 30 dni

      await db.prepare("UPDATE Users SET sessionToken = ?, tokenExpires = ? WHERE ID = ?")
          .bind(sessionToken, expiresAt, user.ID).run();

      return Response.json({ message: "Zalogowano pomyślnie", userID: user.ID, sessionToken: sessionToken }, { status: 200 });
    }
  } catch (e) {
    console.error("Login verification error:", e);
  }

  return Response.json({ message: "Nieprawidłowy e-mail lub hasło" }, { status: 401 });
}
