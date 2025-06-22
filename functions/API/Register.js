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
  //Sprawdzanie czy token jest poprawny
  if(reqBody.token!=1234)
  {
    return Response.json({message: "Niepoprawny token", result: 3}, {status: 403});
  }
  //Sprawdzanie czy użytkownik istnieje
  const checkEmail = context.env.obstawiatorDB.prepare("SELECT name FROM Users WHERE email = ?").bind(reqBody.email);
  const checkEmailResult = await checkEmail.run();
  console.log(checkEmailResult.results);
  if(checkEmailResult.results.length>0)
  {
    return Response.json({message: 'Zarejestrowano już użytkownika pod takim adresem e-mail',result: '1'}, {status: 403});
  }
  //Sprawdzanie czy nazwa użytkownika jest zajęta
  const checkUser = context.env.obstawiatorDB.prepare("SELECT name FROM Users WHERE name = ?").bind(reqBody.name);
  const checkUserResult = await checkUser.run();
  if(checkUserResult.results.length>0)
  {
    return Response.json({message: "Nazwa użytkownika już zajęta", result: 2}, {status: 403});
  }
  //Wyszukiwanie ID
  const getNewID = context.env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM Users");
  const getNewIDResult = await getNewID.run();
  const newID = getNewIDResult.results[0].ID + 1;
  //Dodawanie do bazy danych
  const stmt = context.env.obstawiatorDB.prepare("INSERT INTO Users (ID, name, email, password) VALUES (?, ?, ?, ?)").bind(newID, reqBody.name, reqBody.email, reqBody.password);
  const result = await stmt.run();
  //Dodawanie użytkownika do tabeli UserScores
  const stmt2 = context.env.obstawiatorDB.prepare("INSERT INTO UserScores (ID, points) VALUES (?, ?)").bind(newID, 0);
  const result2 = await stmt2.run();
  return Response.json({message:"Zarejestrowano użytkownika", result: 0, userID: newID}, {status: 201});
}