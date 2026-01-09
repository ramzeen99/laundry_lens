const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onMachineStart = functions.firestore
  .document("machines/{machineId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Détecter si la machine vient d'être lancée
    if (!before.startTime && after.startTime && after.statut === "occupe") {
      const machineId = context.params.machineId;
      const duration = after.duration; // en minutes
      const startTime = after.startTime.toDate();

      const endTime = new Date(startTime.getTime() + duration * 60000);

      console.log(`⏳ Timer programmé pour ${machineId}, fin prévue à ${endTime}`);

      // Programmer notification via FCM
      const payload = {
        notification: {
          title: "🎉 Machine terminée !",
          body: `${after.nom} (${after.emplacement}) a terminé son cycle`,
        },
        topic: `machine_${machineId}`, // envoi ciblé
      };

      const delay = endTime.getTime() - Date.now();

      setTimeout(() => {
        admin.messaging().send(payload);
        console.log(`🔔 Notification envoyée pour ${machineId}`);
      }, delay);
    }

    return null;
  });
