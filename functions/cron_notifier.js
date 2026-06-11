/**
 * Cloudflare Worker - Cron Trigger Notifier
 * Uruchamia się cyklicznie, sprawdza brakujące zakłady i wysyła powiadomienia Push przez FCM v1.
 */

export default {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(handleScheduled(env));
  },
};

function b64url(input) {
  return btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

async function handleScheduled(env) {
  const db = env.obstawiatorDB;
  const now = Date.now();
  const twelveHoursInMs = 12 * 60 * 60 * 1000;

  // 1. Znajdź użytkowników, którzy nie obstawili nadchodzących meczów (w ciągu najbliższych 12h)
  // i nie otrzymali jeszcze powiadomienia dla danego meczu.
  // Założenie: tabelę `sent_notifications` należy utworzyć:
  // CREATE TABLE sent_notifications (userID INTEGER, matchID INTEGER, sentAt INTEGER, PRIMARY KEY(userID, matchID));
  const query = `
    SELECT
      U.ID as userID,
      M.ID as matchID,
      M.host,
      M.guest,
      T.pushToken
    FROM Matches M
    CROSS JOIN Users U
    INNER JOIN UserPushTokens T ON U.ID = T.userID
    LEFT JOIN BetMatch B ON M.ID = B.matchID AND U.ID = B.userID
    LEFT JOIN sent_notifications N ON M.ID = N.matchID AND U.ID = N.userID
    WHERE M.matchStart > ?
      AND M.matchStart <= ?
      AND B.ID IS NULL
      AND N.userID IS NULL
  `;

  const { results } = await db.prepare(query)
    .bind(now, now + twelveHoursInMs)
    .all();

  if (!results || results.length === 0) return;

  // 2. Pobierz Access Token dla FCM v1 (OAuth2)
  // Wymaga wgrania klucza Service Account do env (np. jako sekrety)
  const accessToken = await getFcmAccessToken(env);

  // 3. Wyślij powiadomienia równolegle
  const notificationPromises = results.map(async (row) => {
    try {
      const payload = {
        message: {
          token: row.pushToken,
          notification: {
            title: "Zapomniałeś o zakładzie! ⚽",
            body: `Mecz ${row.host} vs ${row.guest} zaczyna się niedługo. Postaw swój typ!`,
          },
          data: {
            matchID: row.matchID.toString(),
            type: "reminder"
          },
          android: {
            priority: "high",
            notification: {
              click_action: "FLUTTER_NOTIFICATION_CLICK"
            }
          },
          webpush: {
            headers: {
              Urgency: "high"
            },
            fcm_options: {
              link: "https://obstawiator.pages.dev/#/matches"
            }
          }
        }
      };

      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        // Zaznacz, że powiadomienie zostało wysłane, aby nie wysyłać go ponownie w kolejnym cyklu
        await db.prepare("INSERT INTO sent_notifications (userID, matchID, sentAt) VALUES (?, ?, ?)")
          .bind(row.userID, row.matchID, Date.now())
          .run();
      } else {
        const errData = await response.json();
        console.error(`FCM Error for user ${row.userID}:`, errData);
      }
    } catch (e) {
      console.error(`Failed to send notification to user ${row.userID}:`, e);
    }
  });

  await Promise.all(notificationPromises);
}

/**
 * Generuje token OAuth2 dla Google API bez Node.js (JWT RS256).
 */
async function getFcmAccessToken(env) {
  // Oczekujemy sekretów: FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY (zaczynający się od -----BEGIN PRIVATE KEY-----)
  const clientEmail = env.FIREBASE_CLIENT_EMAIL;
  const privateKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');

  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '');
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, '');
  const unsignedToken = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  
  // Podpisywanie kluczem prywatnym przy użyciu Web Crypto API
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey.substring(pemHeader.length, privateKey.length - pemFooter.length).replace(/\s/g, '');
  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const encodedSignature = b64url(String.fromCharCode(...new Uint8Array(signature)));

  const jwt = `${unsignedToken}.${encodedSignature}`;

  // Wymiana JWT na Access Token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`,
  });

  const data = await response.json();
  if (!data.access_token) {
    throw new Error(`OAuth error: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}
