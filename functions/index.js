const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();

const ADMIN_EMAIL = "weddingessentials03@gmail.com";
const ALLOWED_ACTIONS = new Set([
  "activate",
  "suspend",
  "delete",
  "approveVendor",
  "rejectVendor",
]);

exports.manageUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Admin sign-in is required.");
  }

  const db = getFirestore();
  const adminSnapshot = await db.collection("users").doc(request.auth.uid).get();
  const admin = adminSnapshot.data();
  const callerEmail = (request.auth.token.email || "").toLowerCase();
  if (
    callerEmail !== ADMIN_EMAIL ||
    admin?.role !== "admin" ||
    admin?.status !== "active"
  ) {
    throw new HttpsError(
        "permission-denied",
        "Only the active administrator can manage accounts.",
    );
  }

  const userId = String(request.data?.userId || "").trim();
  const action = String(request.data?.action || "").trim();
  if (!userId || !ALLOWED_ACTIONS.has(action)) {
    throw new HttpsError("invalid-argument", "Invalid user or account action.");
  }
  if (userId === request.auth.uid) {
    throw new HttpsError(
        "failed-precondition",
        "The administrator account cannot manage itself.",
    );
  }

  const userRef = db.collection("users").doc(userId);
  if (action === "delete") {
    try {
      await getAuth().deleteUser(userId);
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }
    const batch = db.batch();
    batch.delete(userRef);
    batch.delete(db.collection("customers").doc(userId));
    batch.delete(db.collection("vendors").doc(userId));
    await batch.commit();
    return {success: true};
  }

  const disabled = action === "suspend" || action === "rejectVendor";
  try {
    await getAuth().updateUser(userId, {disabled});
    if (disabled) {
      await getAuth().revokeRefreshTokens(userId);
    }
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
          "not-found",
          "The Firebase Authentication account no longer exists.",
      );
    }
    throw error;
  }

  if (action === "approveVendor" || action === "rejectVendor") {
    const approved = action === "approveVendor";
    const batch = db.batch();
    batch.set(
        userRef,
        {
          status: approved ? "active" : "rejected",
          isActive: approved,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
    );
    batch.set(
        db.collection("vendors").doc(userId),
        {
          isApproved: approved,
          approvalStatus: approved ? "approved" : "rejected",
          [approved ? "approvedAt" : "rejectedAt"]:
            FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
    );
    await batch.commit();
    return {success: true};
  }

  await userRef.set(
      {
        status: disabled ? "suspended" : "active",
        isActive: !disabled,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
  );
  return {success: true};
});
