export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    let sessionToken = context.request.headers.get("Authorization");
    if (!sessionToken && reqBody.sessionToken) sessionToken = reqBody.sessionToken;

    const userID = parseInt(reqBody.ID);
    const specialBetID = parseInt(reqBody.specialBetID);
    const userBetValue = reqBody.bet; // surowa wartość od użytkownika

    // 1. Weryfikacja sesji
    const user = await db.prepare("SELECT ID FROM Users WHERE ID = ? AND sessionToken = ? AND tokenExpires > ?")
      .bind(userID, sessionToken, Date.now()).first();

    if (!user) {
      return new Response(JSON.stringify({ message: "Sesja wygasła. Zaloguj się ponownie." }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // 2. Pobranie definicji zakładu i sprawdzenie czasu
    const specialBet = await db.prepare("SELECT * FROM SpecialBets WHERE ID = ?")
      .bind(specialBetID).first();

    if (!specialBet) {
      return new Response(JSON.stringify({ message: "Zakład nie istnieje." }), { status: 404 });
    }

    if (Date.now() > specialBet.betTimeLimit) {
      return new Response(JSON.stringify({ message: "Czas na obstawianie tego zakładu minął." }), { status: 403 });
    }

    if (specialBet.betFinished === 1) {
      return new Response(JSON.stringify({ message: "Zakład został już zakończony." }), { status: 403 });
    }

    // 3. Walidacja typu zakładu
    let validatedBet = userBetValue;
    if (userBetValue === null || userBetValue === undefined) {
       return new Response(JSON.stringify({ message: "Wartość zakładu nie może być pusta." }), { status: 400 });
    }

    switch (specialBet.betType) {
      case 'YES_NO':
        if (userBetValue !== 'yes' && userBetValue !== 'no') {
          return new Response(JSON.stringify({ message: "Nieprawidłowa wartość dla zakładu TAK/NIE." }), { status: 400 });
        }
        break;
      case 'NUMBER':
      case 'NUMBER_CLOSEST':
        if (isNaN(parseFloat(userBetValue))) {
          return new Response(JSON.stringify({ message: "Wartość musi być liczbą." }), { status: 400 });
        }
        validatedBet = userBetValue.toString();
        break;
      case 'CHOICE':
        const options = JSON.parse(specialBet.options || "[]");
        if (!options.includes(userBetValue)) {
          return new Response(JSON.stringify({ message: "Wybrana opcja nie jest dostępna." }), { status: 400 });
        }
        break;
      case 'EVENT':
        if (userBetValue !== 'yes') {
           return new Response(JSON.stringify({ message: "Dla typu EVENT dozwolona jest tylko wartość 'yes'." }), { status: 400 });
        }
        break;
    }

    // 4. Zapis zakładu (UPSERT)
    await db.prepare(`
      INSERT INTO BetSpecial (userID, specialBetID, bet, updatedAt)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(userID, specialBetID) DO UPDATE SET
        bet = excluded.bet,
        updatedAt = excluded.updatedAt
    `).bind(userID, specialBetID, validatedBet, Date.now()).run();

    return new Response(JSON.stringify({ message: "Zakład został zapisany." }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}
