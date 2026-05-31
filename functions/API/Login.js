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
  const checkUser = context.env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE email = ? AND password = ?").bind(reqBody.email, reqBody.password);
  const checkResult = await checkUser.run();
  console.log(checkResult.results);
  if(checkResult.results.length>0)
  {
    return Response.json({message:"Zalogowano użytkownika", userID: checkResult.results[0].ID}, {status: 200});
  }
  else
  {
    return Response.json({message:"Nieznany użytkownik. Zarejestruj się, lub zaloguj na prawidłowego użytkownika"}, {status: 401});
  }
}