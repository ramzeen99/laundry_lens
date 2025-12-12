import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// 🚀 Initialiser Firebase Admin
admin.initializeApp();

// 🎯 FUNCTION 1: Notification quand une machine devient TERMINÉE
export const sendMachineFinishedNotification = functions.firestore
  .document("machines/{machineId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    console.log("🔍 Vérification changement machine:", after.nom);

    // 🎯 SCÉNARIO: Machine qui passe à TERMINÉE
    if (before.statut !== "termine" && after.statut === "termine") {
      console.log("🎉 Machine terminée détectée:", after.nom);

      // 📝 Préparer le message de notification
      const message = {
        notification: {
          title: "🎉 Machine prête !",
          body: `Votre ${after.nom} (${after.emplacement}) est terminée`,
        },
        data: {
          type: "machine_finished",
          machineId: context.params.machineId,
          machineName: after.nom,
          location: after.emplacement,
          click_action: "FLUTTER_NOTIFICATION_CLICK", // 👈 Important pour Flutter
        },
        topic: "machines", // 👈 Envoyer à tous abonnés
      };

      try {
        // 📤 Envoyer la notification
        const response = await admin.messaging().send(message);
        console.log("✅ Notification envoyée avec succès:", response);
        return null;
      } catch (error) {
        console.error("❌ Erreur envoi notification:", error);
        return null;
      }
    }

    // 🎯 SCÉNARIO: Machine qui passe à LIBRE
    if (before.statut !== "libre" && after.statut === "libre") {
      console.log("✅ Machine libre détectée:", after.nom);

      const message = {
        notification: {
          title: "✅ Machine disponible",
          body: `${after.nom} (${after.emplacement}) est maintenant libre`,
        },
        data: {
          type: "machine_available",
          machineId: context.params.machineId,
          machineName: after.nom,
          location: after.emplacement,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        topic: "machines",
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("✅ Notification disponibilité envoyée:", response);
        return null;
      } catch (error) {
        console.error("❌ Erreur envoi notification:", error);
        return null;
      }
    }

    console.log("ℹ️  Aucune notification nécessaire");
    return null;
  });

// 🎯 FUNCTION 2: Notification de rappel automatique
export const sendReminderNotification = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    console.log("⏰ Vérification des rappels...");

    try {
      // 🔍 Récupérer les machines occupées avec peu de temps restant
      const machinesSnapshot = await admin.firestore()
        .collection("machines")
        .where("statut", "==", "occupe")
        .get();

      let remindersSent = 0;

      for (const doc of machinesSnapshot.docs) {
        const machine = doc.data();

        // 🎯 Machine bientôt terminée (moins de 10 minutes)
        if (machine.tempsRestant && machine.tempsRestant <= 10) {
          console.log(`⏰ Rappel pour ${machine.nom}: ${machine.tempsRestant}min`);

          const message = {
            notification: {
              title: "⏰ Rappel",
              body: `${machine.nom} sera terminée dans ${machine.tempsRestant} minutes`,
            },
            data: {
              type: "reminder",
              machineId: doc.id,
              machineName: machine.nom,
              timeRemaining: machine.tempsRestant.toString(),
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            topic: "machines",
          };

          await admin.messaging().send(message);
          remindersSent++;
        }
      }

      console.log(`✅ ${remindersSent} rappels envoyés`);
      return null;
    } catch (error) {
      console.error("❌ Erreur rappels:", error);
      return null;
    }
  });

// 🎯 FUNCTION 3: Notification test (pour déboguer)
export const sendTestNotification = functions.https.onCall(async (data, context) => {
  console.log("🧪 Notification test demandée");

  const message = {
    notification: {
      title: "🧪 Test Notification",
      body: "Ceci est une notification de test depuis Firebase!",
    },
    data: {
      type: "test",
      message: "Hello from Firebase!",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    topic: "machines",
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("✅ Notification test envoyée:", response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("❌ Erreur notification test:", error);
    return {success: false, error: error};
  }
});