export default {
  async fetch(request, env, ctx) {
    // --- Security Helpers (Point 2) ---

    /**
     * Hashes a password using PBKDF2 with a random salt.
     * Returns a base64 string containing [salt(16 bytes)][hash(32 bytes)].
     */
    async function hashPassword(password) {
      const salt = crypto.getRandomValues(new Uint8Array(16));
      const encoder = new TextEncoder();
      const baseKey = await crypto.subtle.importKey(
        "raw",
        encoder.encode(password),
        "PBKDF2",
        false,
        ["deriveBits"]
      );
      const hashBuffer = await crypto.subtle.deriveBits(
        {
          name: "PBKDF2",
          salt: salt,
          iterations: 100000,
          hash: "SHA-256",
        },
        baseKey,
        256
      );
      const hashArray = new Uint8Array(hashBuffer);
      const combined = new Uint8Array(salt.length + hashArray.length);
      combined.set(salt);
      combined.set(hashArray, salt.length);
      return btoa(String.fromCharCode(...combined));
    }

    /**
     * Verifies a password against a stored base64 string.
     */
    async function verifyPassword(password, stored) {
      try {
        const combined = new Uint8Array(
          atob(stored)
            .split("")
            .map((c) => c.charCodeAt(0))
        );
        const salt = combined.slice(0, 16);
        const storedHash = combined.slice(16);

        const encoder = new TextEncoder();
        const baseKey = await crypto.subtle.importKey(
          "raw",
          encoder.encode(password),
          "PBKDF2",
          false,
          ["deriveBits"]
        );
        const derivedBuffer = await crypto.subtle.deriveBits(
          {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256",
          },
          baseKey,
          256
        );
        const derivedHash = new Uint8Array(derivedBuffer);

        if (storedHash.length !== derivedHash.length) return false;
        return crypto.subtle.timingSafeEqual(storedHash, derivedHash);
      } catch (e) {
        return false;
      }
    }

    // --- Database Helpers ---

    async function userExistsByEmail(email) {
      const stmt = env.obstawiatorDB.prepare("SELECT name FROM Users WHERE email = ?").bind(email);
      const res = await stmt.run();
      return res.results.length > 0;
    }

    async function userExistsByName(name) {
      const stmt = env.obstawiatorDB.prepare("SELECT name FROM Users WHERE name=?").bind(name);
      const res = await stmt.run();
      return res.results.length > 0;
    }

    async function getNewUserID() {
      const stmt = env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM Users");
      const res = await stmt.run();
      return (res.results[0]?.ID || 0) + 5435821;
    }

    async function getUserIDByEmail(email) {
      const stmt = env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE email = ?").bind(email);
      const res = await stmt.run();
      return res.results[0]?.ID;
    }

    async function validateLogin(email, password) {
      const stmt = env.obstawiatorDB.prepare("SELECT password FROM Users WHERE email = ?").bind(email);
      const res = await stmt.run();
      if (res.results.length === 0) return false;
      return await verifyPassword(password, res.results[0].password);
    }

    function sniff() {
      console.log({
        message: "Someone tried to sniff this API... Redirected to Rick Astley",
        country: request.cf?.country,
        city: request.cf?.city,
        region: request.cf?.region
      });
    }

    async function isMainBetPlaced(userID) {
      const stmt = env.obstawiatorDB.prepare("SELECT userID FROM UserScores WHERE userID = ?").bind(userID);
      const res = await stmt.run();
      return res.results.length > 0;
    }

    async function getNextUserScoreID() {
      const stmt = env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM UserScores");
      const res = await stmt.run();
      return (res.results[0]?.ID || 0) + 1;
    }

    async function getMatchStart(matchID) {
      const stmt = env.obstawiatorDB.prepare("SELECT matchStart FROM Matches WHERE ID = ?").bind(matchID);
      const res = await stmt.run();
      return res.results[0]?.matchStart;
    }

    async function isValidUserID(userID) {
      const stmt = env.obstawiatorDB.prepare("SELECT ID FROM Users WHERE ID = ?").bind(userID);
      const res = await stmt.run();
      return res.results.length > 0;
    }

    async function isMatchBetPlaced(matchID, userID) {
      const stmt = env.obstawiatorDB.prepare("SELECT userID FROM BetMatch WHERE matchID = ? AND userID = ?").bind(matchID, userID);
      const res = await stmt.run();
      return res.results.length > 0;
    }

    async function getNextMatchBetID() {
      const stmt = env.obstawiatorDB.prepare("SELECT MAX(ID) as ID FROM BetMatch");
      const res = await stmt.run();
      return (res.results[0]?.ID || 0) + 1;
    }

    // --- Main Router ---

    const path = new URL(request.url).pathname;
    let reqBody = {};
    try {
      if (request.method === "POST") reqBody = await request.json();
    } catch (e) {
      sniff();
      return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
    }

    switch (path) {
      case '/register': {
        if (request.method !== "POST") return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);

        // Basic Validation
        const email = reqBody.email?.toLowerCase();
        const password = reqBody.password;
        const name = reqBody.name;

        if (!email || !email.includes('@')) return Response.json({ message: "Nieprawidłowy adres e-mail" }, { status: 400 });
        if (!password || password.length < 6) return Response.json({ message: "Hasło musi mieć co najmniej 6 znaków" }, { status: 400 });
        if (!name || name.trim().length < 2) return Response.json({ message: "Nazwa użytkownika jest za krótka" }, { status: 400 });

        if (await userExistsByEmail(email)) return Response.json({ message: 'Ten e-mail jest już zarejestrowany', result: '1' }, { status: 403 });
        if (await userExistsByName(name)) return Response.json({ message: "Nazwa użytkownika jest już zajęta", result: 2 }, { status: 403 });

        const hashedPassword = await hashPassword(password);
        const insertStmt = env.obstawiatorDB.prepare("INSERT INTO Users ('ID','email','name','password') VALUES (?,?,?,?)")
          .bind(await getNewUserID(), email, name, hashedPassword);
        await insertStmt.run();

        const ID = await getUserIDByEmail(email);
        return Response.json({ message: "Zarejestrowano użytkownika", result: 0, userID: ID }, { status: 201 });
      }

      case '/login': {
        if (request.method !== "POST") return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);

        const email = reqBody.email?.toLowerCase();
        if (await validateLogin(email, reqBody.password)) {
          const ID = await getUserIDByEmail(email);
          return Response.json({ message: "Zalogowano pomyślnie", userID: ID }, { status: 200 });
        }
        return Response.json({ message: "Nieprawidłowy e-mail lub hasło" }, { status: 401 });
      }

      case '/betChampionTopScorer': {
        if (request.method !== "POST") return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
        if (!reqBody.ID || !await isValidUserID(reqBody.ID)) return Response.json({ message: "Nieautoryzowany dostęp" }, { status: 401 });

        if (!await isMainBetPlaced(reqBody.ID)) {
          const stmt = env.obstawiatorDB.prepare("INSERT INTO UserScores ('ID','userID','championBet','topScorerBet') VALUES (?,?,?,?)")
            .bind(await getNextUserScoreID(), reqBody.ID, reqBody.champion, reqBody.topScorer);
          await stmt.run();
          return Response.json({ message: "Dodano pomyślnie zakład", result: 0 }, { status: 201 });
        } else {
          const stmt = env.obstawiatorDB.prepare("UPDATE UserScores SET championBet = ?, topScorerBet = ? WHERE userID = ?")
            .bind(reqBody.champion, reqBody.topScorer, reqBody.ID);
          await stmt.run();
          return Response.json({ message: "Zaktualizowano pomyślnie zakład", result: 0 }, { status: 200 });
        }
      }

      case '/betMatch': {
        if (request.method !== "POST") return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
        if (!reqBody.userID || !await isValidUserID(reqBody.userID)) return Response.json({ message: "Nieautoryzowany dostęp" }, { status: 401 });

        const matchStart = await getMatchStart(reqBody.matchID);
        if (!matchStart || Date.now() > matchStart) return Response.json({ message: "Nie udało się dodać zakładu, za późno", result: 1 }, { status: 403 });

        if (await isMatchBetPlaced(reqBody.matchID, reqBody.userID)) {
          const stmt = env.obstawiatorDB.prepare("UPDATE BetMatch SET homeScore = ?, AwayScore = ? WHERE matchID = ? AND userID = ?")
            .bind(reqBody.homeScore, reqBody.awayScore, reqBody.matchID, reqBody.userID);
          await stmt.run();
          return Response.json({ message: "Zaktualizowano pomyślnie zakład", result: 0 }, { status: 200 });
        } else {
          const stmt = env.obstawiatorDB.prepare("INSERT INTO BetMatch ('ID','userID','matchID','homeScore','awayScore') VALUES (?,?,?,?,?)")
            .bind(await getNextMatchBetID(), reqBody.userID, reqBody.matchID, reqBody.homeScore, reqBody.awayScore);
          await stmt.run();
          return Response.json({ message: "Dodano pomyślnie zakład", result: 0 }, { status: 201 });
        }
      }

      case '/getMainTable': {
        if (request.method !== "POST") return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
        if (await isValidUserID(reqBody.ID)) {
          const stmt = env.obstawiatorDB.prepare("SELECT UserScores.championBet, UserScores.topScorerBet, UserScores.points, Users.name FROM UserScores INNER JOIN Users ON UserScores.userID=Users.ID ORDER BY UserScores.points DESC");
          const returnValue = await stmt.run();
          return Response.json(returnValue.results);
        }
        return Response.json({ message: "Nieznany użytkownik" }, { status: 401 });
      }

      case '/getMatches': {
        if (request.method !== "POST") return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
        if (await isValidUserID(reqBody.ID)) {
          const stmt = env.obstawiatorDB.prepare("SELECT ID, matchName, matchStart FROM Matches WHERE matchFinished = 1 ORDER BY matchStart ASC LIMIT 10");
          const returnValue = await stmt.run();
          return Response.json(returnValue.results);
        }
        return Response.json({ message: "Nieznany użytkownik" }, { status: 401 });
      }

      default:
        sniff();
        return Response.redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302);
    }
  },
};
