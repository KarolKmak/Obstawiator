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
  const updateMatch = context.env.obstawiatorDB.prepare("UPDATE Matches SET homeScore = ?, awayScore = ?, winner = ?, matchFinished = 1 WHERE ID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.winner, reqBody.matchID);
  const updateMatchResult = await updateMatch.run();

  const getUsers = context.env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM Users");
  const getUsersResult = await getUsers.run();
  const usersAmount = getUsersResult.results[0].ID;
  const winner = reqBody.winner;


  for(let i = 0; i <= usersAmount; i++)
  {
    var points = 0;
    const getUserBet = context.env.obstawiatorDB.prepare("SELECT homeScore, awayScore, winner FROM BetMatch WHERE userID = ? AND matchID = ?").bind(i, reqBody.matchID);
    const getUserBetResult = await getUserBet.run();
    if(getUserBetResult.results.length>0)
    {
        const userBet = getUserBetResult.results[0];
        const userWinner = userBet.winner;

        if(userWinner == winner){points+=2;}
        if(reqBody.homeScore == userBet.homeScore && reqBody.awayScore == userBet.awayScore){points+=4;}

        const updatePoints = context.env.obstawiatorDB.prepare("UPDATE UserScores SET points = points + ? WHERE ID = ?").bind(points, i);
        const updatePointsResult = await updatePoints.run();
    }
  }
  return Response.json({message:"Pomyślnie zaktualizowano punkty"}, {status: 201});
}