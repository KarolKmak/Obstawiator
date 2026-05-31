export async function onRequestPost(context) {
  let reqBody = {};
  try {
    reqBody = await context.request.json();
  } catch (e) {
    return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
  }

  const { email, password, name, token } = reqBody;

  // Walidacja
  if (token != 1234) {
    return Response.json({ message: "Niepoprawny token", result: 3 }, { status: 403 });
  }
  if (!email || !email.includes('@')) {
    return Response.json({ message: "Niepoprawny adres e-mail" }, { status: 400 });
  }
  if (!password || password.length < 6) {
    return Response.json({ message: "Hasło musi mieć co najmniej 6 znaków" }, { status: 400 });
  }

  const db = context.env.obstawiatorDB;

  // Sprawdzanie czy użytkownik istnieje
  const checkEmail = await db.prepare("SELECT 1 FROM Users WHERE email = ?").bind(email.toLowerCase()).first();
  if (checkEmail) {
    return Response.json({ message: 'Ten adres e-mail jest już zajęty', result: '1' }, { status: 403 });
  }

  const checkUser = await db.prepare("SELECT 1 FROM Users WHERE name = ?").bind(name).first();
  if (checkUser) {
    return Response.json({ message: "Nazwa użytkownika już zajęta", result: 2 }, { status: 403 });
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

  // Zapis do bazy
  await db.prepare("INSERT INTO Users (ID, name, email, password) VALUES (?, ?, ?, ?)")
    .bind(newID, name, email.toLowerCase(), hashedPassword).run();

  await db.prepare("INSERT INTO UserScores (ID, userID, points) VALUES (?, ?, ?)")
    .bind(newID, newID, 0).run();

  return Response.json({ message: "Zarejestrowano użytkownika", result: 0, userID: newID }, { status: 201 });
}
