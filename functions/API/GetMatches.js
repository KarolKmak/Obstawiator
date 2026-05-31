export async function onRequestPost(context)
{
  let reqBody = {};
  try
  {
    reqBody = await context.request.json();
  }
  catch(e)
  {
    return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
  }
  const db = context.env.obstawiatorDB;
  const sessionToken = context.request.headers.get("Authorization");

  const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(reqBody.ID, sessionToken, Math.floor(Date.now() / 1000)).first();

  if(user)
  {
    if(reqBody.finishedMatchesOffset != null) // Check if finishedMatchesOffset is explicitly provided and not just falsy (like 0)
    {
      const stmt = db.prepare("SELECT ID, host, guest, matchStart, homeScore, awayScore, betVisible, isGroupStage, winner FROM Matches WHERE matchFinished = 1 ORDER BY matchStart DESC LIMIT 10 OFFSET ?").bind(reqBody.finishedMatchesOffset);
      const returnValue = await stmt.run();
      return Response.json(returnValue.results)
    }
    else
    {
      const stmt = db.prepare("SELECT ID, host, guest, matchStart, homeScore, awayScore, betVisible, isGroupStage FROM Matches WHERE matchFinished = 0 ORDER BY matchStart ASC LIMIT 10");
      const returnValue = await stmt.run();
      return Response.json(returnValue.results)
    }
  }
  else
  {
    return Response.json({message:"Sesja wygasła. Zaloguj się ponownie."}, {status: 401});
  }
}
