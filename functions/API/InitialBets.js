export async function onRequestPost(context)
{
  let reqBody = {};
  //Pobieranie danych z requesta
  try
  {
    reqBody = await context.request.json();
  }
  catch(e)
  {
    return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
  }
  const checkID = context.env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE ID = ?").bind(reqBody.ID);
  const checkIDResult = await checkUser.run();
  if(checkIDResult.results.length>0)
  {
      const stmt = context.env.obstawiatorDB.prepare("UPDATE UserScores SET championBet = ?, topScorerBet = ? WHERE ID = ?").bind(reqBody.championBet, reqBody.topScorerBet, reqBody.ID);
      const result = await stmt.run();
      return Response.json({message:"Pomyślnie dodano zakład"}, {status: 201});
  }
  else
  {
    return Response.json({message: "Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 403});
  }

}