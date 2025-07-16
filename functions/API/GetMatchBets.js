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

    const getMatchBets = context.env.obstawiatorDB.prepare("SELECT BetMatch.homeScore, BetMatch.awayScore, Users.name BetMatch.winner FROM BetMatch INNER JOIN Users ON BetMatch.userID=Users.ID WHERE BetMatch.matchID = ? AND BetMatch.userID != ?").bind(reqBody.matchID, reqBody.ID);
    const getMatchBetsResult = await getMatchBets.run();

    const getUserBet = context.env.obstawiatorDB.prepare("SELECT homeScore, awayScore, winner FROM BetMatch WHERE userID = ? AND matchID = ?").bind(reqBody.ID, reqBody.matchID);
    const getUserBetResult = await getUserBet.run();

    return Response.json({userBet: getUserBetResult.results[0], matchBets: getMatchBetsResult.results}, {status: 200});

  }
  else
  {
    return Response.json({message:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 401});
  }
}
