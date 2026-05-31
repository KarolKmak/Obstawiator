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
    const getTime = context.env.obstawiatorDB.prepare("SELECT matchStart FROM Matches WHERE ID = ?").bind(reqBody.matchID);
    const getTimeResult = await getTime.run();
    //Sprawdzanie czy gra się jeszcze nie rozpoczęła
    if(Date.now() > getTimeResult.results[0].matchStart)
    {
      return Response.json({message: "Nie udało się dodać zakładu, za późno", result: 1}, {status: 403});
    }
    const checkIfBetPlaced = context.env.obstawiatorDB.prepare("SELECT userID FROM BetMatch WHERE userID = ? AND matchID = ?").bind(reqBody.ID, reqBody.matchID);
    const checkIfBetPlacedResult = await checkIfBetPlaced.run();
    if(checkIfBetPlacedResult.results.length>0)
    {
      let placeBet;
      if(reqBody.winner == 0 || reqBody.winner == 1)
      {
        placeBet = context.env.obstawiatorDB.prepare("UPDATE BetMatch SET homeScore = ?, awayScore = ?, winner = ? WHERE userID = ? AND matchID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.winner, reqBody.ID, reqBody.matchID);
      }
      else
      {
        placeBet = context.env.obstawiatorDB.prepare("UPDATE BetMatch SET homeScore = ?, awayScore = ? WHERE userID = ? AND matchID = ?").bind(reqBody.homeScore, reqBody.awayScore, reqBody.ID, reqBody.matchID);
      }
      const placeBetResult = await placeBet.run();
      return Response.json({message:"Pomyślnie zaktualizowano zakład"}, {status: 201});
    }
    else
    {
      const getNewID = context.env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM BetMatch");
      const getNewIDResult = await getNewID.run();
      const newID = getNewIDResult.results[0].ID + 1;
      let placeBet;     
        placeBet = context.env.obstawiatorDB.prepare("INSERT INTO BetMatch (userID, matchID, homeScore, awayScore, ID, winner) VALUES (?, ?, ?, ?, ?, ?)").bind(reqBody.ID, reqBody.matchID, reqBody.homeScore, reqBody.awayScore, newID, reqBody.winner);
      //POPRAWIĆ!!!!!!!!!!!!!!!!!!!!!!!!!
      const placeBetResult = await placeBet.run();
      return Response.json({message:"Pomyślnie dodano zakład"}, {status: 201});
    }
  }
  else
  {
    return Response.json({message:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 401});
  }
}
