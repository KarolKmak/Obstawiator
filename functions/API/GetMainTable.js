export function onRequestGet()
{
  const stmt = env.obstawiatorDB.prepare("SELECT UserScores.championBet, UserScores.topScorerBet, UserScores.points, Users.name FROM UserScores INNER JOIN Users ON UserScores.userID=Users.ID ORDER BY UserScores.points DESC"); 
  const returnValue = await stmt.run();
  return Response.json(returnValue.results)
}
