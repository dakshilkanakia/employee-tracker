importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDI8-PcVqZV26JMp_fqbv2zBGSrd0WRh8Q",
  authDomain: "employee-tracker-ed5a6.firebaseapp.com",
  projectId: "employee-tracker-ed5a6",
  storageBucket: "employee-tracker-ed5a6.firebasestorage.app",
  messagingSenderId: "855996311514",
  appId: "1:855996311514:web:a9d264a2ce64c11997c2e3",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body,
    icon: "/icons/Icon-192.png",
  });
});
