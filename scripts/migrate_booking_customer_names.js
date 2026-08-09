const firebaseToolsRoot =
  "C:/Users/sthan/AppData/Roaming/npm/node_modules/firebase-tools/lib";
const { getAccessToken } = require(`${firebaseToolsRoot}/auth`);
const { configstore } = require(`${firebaseToolsRoot}/configstore`);

const projectId = "wedding-essentials-app-01";
const databaseRoot =
  `https://firestore.googleapis.com/v1/projects/${projectId}` +
  "/databases/(default)/documents";

function stringField(document, field) {
  return document?.fields?.[field]?.stringValue?.trim() || "";
}

async function request(url, token, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...options.headers,
    },
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${await response.text()}`);
  }
  return response.status === 204 ? null : response.json();
}

async function listDocuments(collection, token) {
  const documents = [];
  let pageToken = "";
  do {
    const url = new URL(`${databaseRoot}/${collection}`);
    url.searchParams.set("pageSize", "300");
    if (pageToken) url.searchParams.set("pageToken", pageToken);
    const page = await request(url, token);
    documents.push(...(page.documents || []));
    pageToken = page.nextPageToken || "";
  } while (pageToken);
  return documents;
}

async function loadCustomerName(customerId, token) {
  for (const collection of ["customers", "users"]) {
    const response = await fetch(
      `${databaseRoot}/${collection}/${encodeURIComponent(customerId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (response.status === 404) continue;
    if (!response.ok) throw new Error(`${response.status} ${await response.text()}`);
    const name = stringField(await response.json(), "name");
    if (name) return name;
  }
  return "";
}

async function main() {
  const refreshToken = configstore.get("tokens")?.refresh_token;
  if (!refreshToken) throw new Error("Firebase CLI is not signed in.");
  const credentials = await getAccessToken(
    refreshToken,
    configstore.get("loginScopes") || [],
  );
  const token = credentials.access_token;
  const bookings = await listDocuments("bookings", token);
  const nameCache = new Map();
  const namesByEmail = new Map();
  let updated = 0;

  for (const booking of bookings) {
    const currentName = stringField(booking, "customerName");
    const customerId = stringField(booking, "customerId");
    const customerEmail = stringField(booking, "customerEmail").toLowerCase();
    if (customerId && !nameCache.has(customerId)) {
      nameCache.set(customerId, await loadCustomerName(customerId, token));
    }
    const profileName = nameCache.get(customerId) || "";
    const customerName = profileName ||
      (currentName && !currentName.includes("@") ? currentName : "Customer");
    if (customerEmail) namesByEmail.set(customerEmail, customerName);
    if (currentName === customerName) continue;
    const url = new URL(booking.name.replace(
      `projects/${projectId}/databases/(default)/documents`,
      databaseRoot,
    ));
    url.searchParams.append("updateMask.fieldPaths", "customerName");
    await request(url, token, {
      method: "PATCH",
      body: JSON.stringify({
        fields: { customerName: { stringValue: customerName } },
      }),
    });
    updated += 1;
  }

  const notifications = await listDocuments("notifications", token);
  let notificationsUpdated = 0;
  for (const notification of notifications) {
    const message = stringField(notification, "message");
    let updatedMessage = message;
    for (const [email, customerName] of namesByEmail) {
      updatedMessage = updatedMessage.replaceAll(email, customerName);
    }
    if (updatedMessage === message) continue;
    const url = new URL(notification.name.replace(
      `projects/${projectId}/databases/(default)/documents`,
      databaseRoot,
    ));
    url.searchParams.append("updateMask.fieldPaths", "message");
    await request(url, token, {
      method: "PATCH",
      body: JSON.stringify({
        fields: { message: { stringValue: updatedMessage } },
      }),
    });
    notificationsUpdated += 1;
  }

  console.log(
    `Checked ${bookings.length} bookings; updated ${updated}. ` +
      `Checked ${notifications.length} notifications; updated ${notificationsUpdated}.`,
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
