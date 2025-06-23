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
  const checkUserID = context.env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE ID = ?").bind(reqBody.ID);
  const checkResult = await checkUserID.run();
  console.log(checkResult.results);
  if(checkResult.results.length>0)
  {
    const stmt = context.env.obstawiatorDB.prepare("SELECT ID, host, guest, matchStart, homeScore, awayScore FROM Matches WHERE matchFinished = 1 ORDER BY matchStart ASC LIMIT 10");
    const returnValue = await stmt.run();
    return Response.json(returnValue.results)
  }
  else
  {
    return Response.json({message:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 403});
  }
}