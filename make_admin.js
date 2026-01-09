// 1️⃣ Importer Firebase Admin
const admin = require("firebase-admin");

// 2️⃣ Charger le fichier JSON de ton service account
const serviceAccount = require("C:\\Users\\THUNDERROBOT\\Downloads\\laundry-53ef0-firebase-adminsdk-fbsvc-31be87c48a.json");

// 3️⃣ Initialiser l'app Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 4️⃣ UID de l'utilisateur que tu veux rendre admin
const uid = "lqHuVdSIE8eCfrMVFS56akQsDnw2";

// 5️⃣ Définir le custom claim
admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log("✅ Admin configuré pour l'UID:", uid);
  })
  .catch((error) => {
    console.error("❌ Erreur:", error);
  });