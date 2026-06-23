export async function onRequestPost(context) {
  try {
    let reqBody = {};
    try {
      reqBody = await context.request.json();
    } catch (e) {
      return new Response("Invalid JSON", { status: 400 });
    }

    const db = context.env.obstawiatorDB;
    const specialBetID = parseInt(reqBody.specialBetID);
    const betResult = reqBody.betResult; // Wynik faktyczny (np. "yes", "2", "Lewandowski")

    // 1. Pobranie definicji zakładu
    const specialBet = await db.prepare("SELECT * FROM SpecialBets WHERE ID = ?")
      .bind(specialBetID).first();

    if (!specialBet) {
      return new Response(JSON.stringify({ message: "Zakład nie istnieje." }), { status: 404 });
    }

    if (specialBet.betFinished === 1) {
      return new Response(JSON.stringify({ message: "Zakład został już rozliczony." }), { status: 400 });
    }

    // 2. Pobranie wszystkich zakładów użytkowników dla tego specialBetID
    const userBets = await db.prepare("SELECT userID, bet FROM BetSpecial WHERE specialBetID = ? AND pointsAwarded IS NULL")
      .bind(specialBetID).all();

    if (userBets.results.length === 0) {
      // Brak zakładów do rozliczenia, ale oznaczamy jako zakończony
      await db.prepare("UPDATE SpecialBets SET betResult = ?, betFinished = 1 WHERE ID = ?")
        .bind(betResult.toString(), specialBetID).run();
      return new Response(JSON.stringify({ message: "Brak zakładów do rozliczenia. Zakład zamknięty." }), { status: 200 });
    }

    const updates = [];
    const pointsWin = specialBet.pointsWin || 0;
    const pointsLoss = specialBet.pointsLoss || 0;

    if (specialBet.betType === 'NUMBER_CLOSEST') {
      const targetValue = parseFloat(betResult);
      let minDiff = Infinity;

      // Filtrujemy tylko poprawne liczby, by uniknąć NaN w obliczeniach
      const validUserBets = userBets.results.filter(ub => !isNaN(parseFloat(ub.bet)));

      if (validUserBets.length === 0) {
        await db.prepare("UPDATE SpecialBets SET betResult = ?, betFinished = 1 WHERE ID = ?")
          .bind(betResult.toString(), specialBetID).run();
        return new Response(JSON.stringify({ message: "Brak poprawnych zakładów liczbowych do rozliczenia. Zakład zamknięty." }), { status: 200 });
      }

      // Znajdź najmniejszą różnicę
      validUserBets.forEach(ub => {
        const diff = Math.abs(parseFloat(ub.bet) - targetValue);
        if (diff < minDiff) minDiff = diff;
      });

      // Przyznaj punkty tym, którzy byli najbliżej
      for (const ub of validUserBets) {
        const diff = Math.abs(parseFloat(ub.bet) - targetValue);
        const awarded = (diff === minDiff) ? pointsWin : pointsLoss;
        updates.push({ userID: ub.userID, points: awarded });
      }
    } else {
      // Standardowe porównanie dla EVENT, YES_NO, NUMBER, CHOICE
      for (const ub of userBets.results) {
        const isWinner = (ub.bet === betResult.toString());
        const awarded = isWinner ? pointsWin : pointsLoss;
        updates.push({ userID: ub.userID, points: awarded });
      }
    }

    // 3. Wykonanie aktualizacji (Batch)
    const batchStatements = [];

    // Aktualizacja punktów użytkowników
    for (const update of updates) {
      if (update.points !== 0) {
        batchStatements.push(
          db.prepare("UPDATE UserScores SET points = points + ? WHERE ID = ?")
            .bind(update.points, update.userID)
        );
      }
      // Oznaczenie zakładu jako rozliczony u użytkownika
      batchStatements.push(
        db.prepare("UPDATE BetSpecial SET pointsAwarded = ? WHERE userID = ? AND specialBetID = ?")
          .bind(update.points, update.userID, specialBetID)
      );
    }

    // Oznaczenie zakładu głównego jako zakończony
    batchStatements.push(
      db.prepare("UPDATE SpecialBets SET betResult = ?, betFinished = 1 WHERE ID = ?")
        .bind(betResult.toString(), specialBetID)
    );

    await db.batch(batchStatements);

    return new Response(JSON.stringify({
      message: `Pomyślnie rozliczono ${updates.length} zakładów.`,
      settledCount: updates.length
    }), { status: 200 });

  } catch (error) {
    return new Response(JSON.stringify({ message: "Błąd serwera: " + error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}
