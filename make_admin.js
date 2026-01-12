// 1️⃣ Importer Firebase Admin
const admin = require("firebase-admin");

// 2️⃣ Charger le fichier JSON de ton service account
const serviceAccount = require("C:\\Users\\THUNDERROBOT\\Downloads\\laundry-53ef0-firebase-adminsdk-fbsvc-31be87c48a.json");

// 3️⃣ Initialiser l'app Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 4️⃣ UID de l'utilisateur que tu veux rendre super admin
const uid = "lqHuVdSIE8eCfrMVFS56akQsDnw2";

// 5️⃣ Définir le custom claim
admin.auth().setCustomUserClaims(uid, { role: "super_admin" })
  .then(() => {
    console.log("✅ Super admin configuré pour l'UID:", uid);
    process.exit(0); // Terminer le script correctement
  })
  .catch((error) => {
    console.error("❌ Erreur:", error);
    process.exit(1);
  });
