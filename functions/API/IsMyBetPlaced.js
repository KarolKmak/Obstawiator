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
  // Check if user exists
  const checkUserID = context.env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE ID = ?").bind(reqBody.ID);
  const checkResult = await checkUserID.run();
  console.log(checkResult.results);
  // If user exists
  if(checkResult.results.length>0)
  {
    // Check if user has placed a bet for the given match
    const getUserBet = context.env.obstawiatorDB.prepare("SELECT matchID, winner FROM BetMatch WHERE userID = ? AND matchID = ?").bind(reqBody.ID, reqBody.matchID);
    const getUserBetResult = await getUserBet.run();
    // If user has placed a bet
    if(getUserBetResult.results.length>0)
    {
        // Return the bet
        return Response.json({userBet: getUserBetResult.results[0]}, {status: 200});
    }
    else
    {
      return Response.json({userBet: null}, {status: 200});
    }
  }
  else
  {
    return Response.json({message:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 401});
  }
}