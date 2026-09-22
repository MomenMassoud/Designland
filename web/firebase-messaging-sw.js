importScripts(
  "https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js"
);

// تهيئة الفايربيز مع مطابقة الـ Auth Domain التابع لـ designland-market
firebase.initializeApp({
  apiKey: "AIzaSyD727CeckI2brOtT5ycefqAZTkOrhyiwvg",
  authDomain: "designland-market.firebaseapp.com",
  projectId: "desginland-5ca7a",
  storageBucket: "desginland-5ca7a.firebasestorage.app",
  messagingSenderId: "848711152963",
  appId: "1:848711152963:web:4b4c831a8d7853c2a26bf6",
  measurementId: "G-FYDNF4NC6X"
});

const messaging = firebase.messaging();

// استقبال الإشعارات في الخلفية
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const notification = payload.notification || {};
  const data = payload.data || {};

  const title = notification.title || data.title || 'DesignLand - إشعار جديد 🔔';
  const body = notification.body || data.body || '';

  const notificationOptions = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: data,
    tag: data.orderId || data.type || 'designland-notification',
    renotify: true
  };

  self.registration.showNotification(title, notificationOptions);
});

// التفاعل عند الضغط على الإشعار
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});