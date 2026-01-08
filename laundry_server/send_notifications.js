const admin = require("firebase-admin");

// Option 1 : fichier JSON local
const serviceAccount = require("./laundry-53ef0-firebase-adminsdk-fbsvc-823a165ccc.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Test simple
db.collection("test").get()
  .then(snapshot => {
    console.log("Connexion OK ✅");
    snapshot.forEach(doc => console.log(doc.id, doc.data()));
  })
  .catch(err => console.error("Erreur Firestore:", err));
