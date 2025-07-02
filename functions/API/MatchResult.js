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
  const updateMatch = context.env.obstawiatorDB.prepare("UPDATE Matches SET homeScore = ?, awayScore = ? WHERE ID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.matchID);
  const updateMatchResult = await updateMatch.run();

  const getUsers = context.env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM Users");
  const getUsersResult = await getUsers.run();
  const usersAmount = getUsersResult.results[0].ID;

  if(reqBody.homeScore > reqBody.awayScore)
  {var winner = 0;}
  else if(reqBody.homeScore < reqBody.awayScore)
  {var winner = 1;}
  else
  {var winner = 2;}

  var goalDifference = reqBody.homeScore - reqBody.awayScore;

  for(let i = 0; i <= usersAmount; i++)
  {
    var points = 0;
    const getUserBet = context.env.obstawiatorDB.prepare("SELECT homeScore, awayScore FROM BetMatch WHERE userID = ? AND matchID = ?").bind(i, reqBody.matchID);
    const getUserBetResult = await getUserBet.run();
    if(getUserBetResult.results.length>0)
    {
        const userBet = getUserBetResult.results[0];
        if(userBet.homeScore > userBet.awayScore)
        {var userWinner = 0;}
        else if(userBet.homeScore < userBet.awayScore)
        {var userWinner = 1;}
        else
        {var userWinner = 2;}

        var userGoalDifference = userBet.homeScore - userBet.awayScore;


        if(userWinner == winner){points+=1;}
        if(userGoalDifference == goalDifference){points+=1;}
        if(reqBody.homeScore == userBet.homeScore && reqBody.awayScore == userBet.awayScore){points+=3;}

        const updatePoints = context.env.obstawiatorDB.prepare("UPDATE UserScores SET points = points + ? WHERE ID = ?").bind(points, i);
        const updatePointsResult = await updatePoints.run();
    }
  }
  return Response.json({message:"Pomyślnie zaktualizowano punkty"}, {status: 201});
}