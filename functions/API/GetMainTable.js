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
    const stmt = context.env.obstawiatorDB.prepare("SELECT UserScores.championBet, UserScores.topScorerBet, UserScores.points, Users.name FROM UserScores INNER JOIN Users ON UserScores.userID=Users.ID ORDER BY UserScores.points DESC"); 
    const returnValue = await stmt.run();
    return Response.json(returnValue.results)
  }
  else
  {
    return Response.json({message:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 401});
  }
}
