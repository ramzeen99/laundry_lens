const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.applicationDefault()
});
const db = admin.firestore();

const totalMinutes = 40;

exports.app = async (req, res) => {
  const machines = await db.collection("machines").get();
  const batch = db.batch();

  machines.forEach(doc => {
    const data = doc.data();
    if (data.statut === "occupe") {
      const elapsed = Math.floor((Date.now() - data.tempsRestant) / 60000);
      const remaining = totalMinutes - elapsed;
      batch.update(doc.ref, { tempsRestant: remaining > 0 ? remaining : 0 });
    }
  });

  await batch.commit();
  res.send("Timer updated");
};
