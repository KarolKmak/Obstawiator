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
  const checkIDResult = await checkID.run();
  if(Date.now() > 1751472000000)
  {
    if(Date.now() < 1752692400000 && checkIDResult.results.length>0)
    {
        const checkIfChanged = context.env.obstawiatorDB.prepare("SELECT betChanged FROM UserScores WHERE ID = ?").bind(reqBody.ID);
        const checkIfChangedResult = await checkIfChanged.run();
        if(checkIfChangedResult.results[0].betChanged == 0 || checkIfChangedResult.results[0].betChanged == null)
        {
            const stmt = context.env.obstawiatorDB.prepare("UPDATE UserScores SET betChanged = 1, points = points - 5, championBet = ? WHERE ID = ?").bind(reqBody.championBet, reqBody.ID);
            const result = await stmt.run();
            return Response.json({message:"Pomyślnie aktualizowano zakład, odjęto 5pkt"}, {status: 201});
        }
        const stmt = context.env.obstawiatorDB.prepare("UPDATE UserScores SET championBet = ? WHERE ID = ?").bind(reqBody.championBet, reqBody.ID);
        const result = await stmt.run();
        return Response.json({message:"Pomyślnie aktualizowano zakład"}, {status: 201});
    }

    return Response.json({message: "Nie udało się dodać zakładu, za późno"}, {status: 403});
  }

  if(checkIDResult.results.length>0)
  {
      const stmt = context.env.obstawiatorDB.prepare("UPDATE UserScores SET championBet = ?, topScorerBet = ? WHERE ID = ?").bind(reqBody.championBet, reqBody.topScorerBet, reqBody.ID);
      const result = await stmt.run();
      return Response.json({message:"Pomyślnie dodano zakład"}, {status: 201});
  }
  else
  {
    return Response.json({message: "Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 401});
  }

}