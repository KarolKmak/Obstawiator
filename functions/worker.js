export default
{
  async fetch(request, env, ctx)
  {

    async function isEmailEmpty(email)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT name FROM Users WHERE email = ?").bind(email);
      const returnValue = await stmt.run();
      return returnValue.results.length;
    }
    async function isNameEmpty(name)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT name FROM Users WHERE name=?").bind(name);
      const returnValue = await stmt.run();
      return returnValue.results.length;
    }
    async function getNewUserID()
    {
      const stmt = env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM Users");
      const returnValue = await stmt.run();
      return returnValue.results[0].ID+5435821;
    }
    async function getUserID(email, password)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE email = ? AND password = ?").bind(email, password);
      const returnValue = await stmt.run();
      return returnValue.results[0].ID;
    }
    async function checkLoginPassword(email,password)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE email = ? AND password = ?").bind(email, password);
      const returnValue = await stmt.run();
      return returnValue.results.length;
    }
    function sniff()
    {
      console.log({messege: "Someone tried to sniff this API... Redirected to Rick Astley", country: request.cf.country, city: request.cf.city, region: request.cf.region});
    }
    async function isMainBetPlaced(userID)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT userID FROM UserScores WHERE userID = ?").bind(userID);
      const returnValue = await stmt.run()
      return returnValue.results.length;
    }
    async function getUserScoresID(userID)
    {
      if(!await isMainBetPlaced(userID))
      {
        const stmt = env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM UserScores");
        const returnValue = await stmt.run();
        return returnValue.results[0].ID+1;
      }
      else
      {
        const stmt = env.obstawiatorDB.prepare("SELECT ID FROM UserScores WHERE userID = ?").bind(userID);
        const returnValue = await stmt.run();
        return returnValue.results[0].ID;
      }
    }
    async function getMatchStart(matchID)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT matchStart FROM Matches WHERE ID = ?").bind(matchID);
      const returnValue = await stmt.run();
      return returnValue.results[0].matchStart;
    }
    async function checkID(userID)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE ID = ?").bind(userID);
      const returnValue = await stmt.run();
      return returnValue.results.length;
    }
    async function isMatchBetPlaced(matchID,userID)
    {
      const stmt = env.obstawiatorDB.prepare("SELECT userID FROM BetMatch WHERE matchID = ? AND userID = ?").bind(matchID,userID);
      const returnValue = await stmt.run();
      return returnValue.results.length;
    }
    async function getMatchBetID(matchID,userID)
    {
      if(!await isMatchBetPlaced(matchID,userID))
      {
        const stmt = env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM BetMatch").bind(matchID,userID);
        const returnValue = await stmt.run();
        return returnValue.results.results[0].ID+1
      }
      const stmt = env.obstawiatorDB.prepare("SELECT ID FROM BetMatch WHERE matchID = ? AND userID = ?").bind(matchID,userID);
      const returnValue = await stmt.run();
      return returnValue.results.results[0].ID
    }    



    const path = new URL(request.url).pathname;
    let reqBody = {};
    try
    {
    reqBody = await request.json();
    }
    catch(e)
    {
      sniff();
      return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
    }



    switch(path)
    {

      case '/register':
        {
          if (request.method === "POST")
          {
            if(await isEmailEmpty(reqBody.email))
            {
              return Response.json({message: 'Zarejestrowano już użytkownika pod takim adresem e-mail',result: '1'}, {status: 403});
            }
            if(await isNameEmpty(reqBody.name))
            {
              return Response.json({messege: "Nazwa użytkownika już zajęta", result: 2}, {status: 403});
            }
            const registration = env.obstawiatorDB.prepare("INSERT INTO Users ('ID','email','name','password') VALUES (?,?,?,?)").bind(await getNewUserID(),reqBody.email,reqBody.name,reqBody.password)
            await registration.run();
            const ID = await getUserID(reqBody.email, reqBody.password);
            return Response.json({messege:"Zarejestrowano użytkownika", result: 0, userID: ID}, {status: 201});
          }
          else{sniff();return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);}
        }

      case '/login':
        {
          if(request.method === "POST")
          {
            if(await checkLoginPassword(reqBody.email,reqBody.password))
            {
              const ID = await getUserID(reqBody.email, reqBody.password);
              return Response.json({messege:"Zalogowano pomyślnie", userID: ID}, {status: 200});
            }
            return Response.json({messege:"Nieprawdiłowy e-mail, lub hasło"}, {status: 404});
          }
          else{sniff();return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);}
        }
      
      case '/betChampionTopScorer':
      {
        if (request.method === "POST")
        {
          //Dodać kontrolę prawidłowego userID
          //Rozdzielić na dwa endpointy
          //Dodać kontrolę zalogowania użytkownika
          if(!await isMainBetPlaced(reqBody.ID))
          {
            const placeBet = env.obstawiatorDB.prepare("INSERT INTO UserScores ('ID','userID','championBet','topScorerBet') VALUES (?,?,?,?)").bind(await getUserScoresID(reqBody.ID),reqBody.ID,reqBody.champion,reqBody.topScorer);
            await placeBet.run();
            return Response.json({messege:"Dodano pomyślnie zakład", result:0}, {status: 201});
          }
          else
          {
            const placeBet = env.obstawiatorDB.prepare("UPDATE UserScores SET championBet = ?, topScorerBet = ? WHERE userID = ?").bind(reqBody.champion,reqBody.topScorer,reqBody.ID);
            await placeBet.run();
            return Response.json({messege:"Zauktualizowano pomyślnie zakład", result:0}, {status: 201});
          }
        }
        else{sniff();return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);}
      }

      case '/betMatch':
        {
          if (request.method === "POST")
          {
            if(Date.now()>await getMatchStart(reqBody.matchID))
            {
              Response.json({message: "Nie udało się dodać zakładu, za późno", result: 1}, {status: 403});
            }
            else
            {
              if(await isMatchBetPlaced(reqBody.matchID,reqBody.userID))
              {
                const placeBet = env.obstawiatorDB.prepare("UPDATE BetMatch SET homeScore = ?, AwayScore = ? WHERE matchID = ? AND userID = ?").bind(reqBody.homeScore,reqBody.awayScore,reqBody.matchID,reqBody.userID);
                await placeBet.run();
                return Response.json({message:"Zauktualizowano pomyślnie zakład", result:0}, {status: 201});
              }
              else
              {
                const placeBet = env.obstawiatorDB.prepare("INSERT INTO BetMatch ('ID','userID','matchID','homeScore','awayScore') VALUES (?,?,?,?,?)").bind(await getMatchBetID(reqBody.matchID,reqBody.userID),reqBody.userID,reqBody.matchID,reqBody.homeScore,reqBody.awayScore);
                await placeBet.run();
                return Response.json({message:"Dodano pomyślnie zakład", result:0}, {status: 201});
              }
            }
            return Response.json({message: "Zapisano zakład"}, {status: 201});
          }
          else{sniff();return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);}
        }

        //Zostawić na później
      case '/betSpecial':
        return new Response('betSpecial');

      case '/getMainTable':
        {
          if (request.method === "POST")
          {
            if(await checkID(reqBody.ID)>0)
            {
              const stmt = env.obstawiatorDB.prepare("SELECT UserScores.championBet, UserScores.topScorerBet, UserScores.points, Users.name FROM UserScores INNER JOIN Users ON UserScores.userID=Users.ID ORDER BY UserScores.points DESC"); 
              const returnValue = await stmt.run();
              return Response.json(returnValue.results)
            }
            else
            {
              return Response.json({messege:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 404});
            }
            
          }
          else{sniff();return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);}
        }

      case '/getMatches':
        {
          if (request.method === "POST")
          {
            if(await checkID(reqBody.ID)>0)
            {
              const stmt = env.obstawiatorDB.prepare("SELECT ID, matchName, matchStart FROM Matches WHERE matchFinished = 1 ORDER BY matchStart ASC LIMIT 10"); 
              const returnValue = await stmt.run();
              return Response.json(returnValue.results)
            }
            else
            {
              return Response.json({messege:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 404});
            }
            
          }
          else{sniff();return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);}
        }

        //Zostawić na później
      case '/getMatchDetail':
        return new Response('getMatchDetail');
        
      default:
        {
          sniff();
          return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
        }

    }
  },
};
