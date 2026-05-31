export async function verifySession(context, reqBody) {
  const db = context.env.obstawiatorDB;
  const sessionToken = context.request.headers.get("Authorization");

  if (!sessionToken) {
    return null;
  }

  const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

  return user || null;
}
