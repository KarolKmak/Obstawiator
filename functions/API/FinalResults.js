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
  const updateFinal = context.env.obstawiatorDB.prepare("UPDATE ChampionBet SET rowid = 0, ID = 0, champion = ?, topScorer = ?").bind(reqBody.champion, reqBody.topScorer);
  const updateFinalResult = await updateFinal.run();

  const getUsers = context.env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM Users");
  const getUsersResult = await getUsers.run();
  const usersAmount = getUsersResult.results[0].ID;
  const champion = reqBody.champion;
  const topScorer = reqBody.topScorer;


  for(let i = 0; i <= usersAmount; i++)
  {
    var points = 0;
    const getUserBet = context.env.obstawiatorDB.prepare("SELECT championBet, topScorerBet FROM UserScores WHERE userID = ?").bind(i);
    const getUserBetResult = await getUserBet.run();
    if(getUserBetResult.results.length>0)
    {
        const userBet = getUserBetResult.results[0];
        const userChampion = userBet.championBet;
        const userTopScorer = userBet.topScorerBet;

        if(userChampion == champion){points+=10;}
        if(userTopScorer == topScorer){points+=5;}

        const updatePoints = context.env.obstawiatorDB.prepare("UPDATE UserScores SET points = points + ? WHERE ID = ?").bind(points, i);
        const updatePointsResult = await updatePoints.run();
    }
  }
  return Response.json({message:"Pomyślnie zaktualizowano punkty"}, {status: 201});
}