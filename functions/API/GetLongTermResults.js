export async function onRequestPost(context) {
  try {
    const db = context.env.obstawiatorDB;

    // Pobierz aktualne wyniki z tabeli ChampionBet
    // Tabela ChampionBet przechowuje ostateczne rozstrzygnięcia
    const result = await db.prepare("SELECT champion, topScorer FROM ChampionBet LIMIT 1").first();

    if (!result) {
      return new Response(JSON.stringify({
        champion: null,
        topScorer: null,
        isSettled: false
      }), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      });
    }

    return new Response(JSON.stringify({
      champion: result.champion,
      topScorer: result.topScorer,
      isSettled: !!(result.champion || result.topScorer)
    }), {
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
