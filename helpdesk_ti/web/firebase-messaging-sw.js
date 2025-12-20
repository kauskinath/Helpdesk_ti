// Firebase Cloud Messaging Service Worker for Web
// Este arquivo é necessário para receber notificações push na web

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Inicializa o Firebase app no Service Worker
// Credenciais do Firebase
firebase.initializeApp({
  apiKey: "AIzaSyDOrQNQMpiZP6BMkasENIamDZTeNJjYQYA",
  authDomain: "helpdesk-ti-4bbf2.firebaseapp.com",
  projectId: "helpdesk-ti-4bbf2",
  storageBucket: "helpdesk-ti-4bbf2.firebasestorage.app",
  messagingSenderId: "473860451308",
  appId: "1:473860451308:web:189a4ad051ce93f6446ec9"
});

const messaging = firebase.messaging();

// Handler para mensagens em background
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'HelpDesk TI';
  const notificationOptions = {
    body: payload.notification?.body || 'Nova notificação',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.chamadoId || 'default',
    data: payload.data,
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: 'Abrir'
      },
      {
        action: 'close',
        title: 'Fechar'
      }
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handler para clique na notificação
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click:', event);
  
  event.notification.close();

  if (event.action === 'close') {
    return;
  }

  // Abre a aplicação ou foca na janela existente
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Se já tem uma janela aberta, foca nela
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Se não tem janela aberta, abre uma nova
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

// Handler para instalação do service worker
self.addEventListener('install', (event) => {
  console.log('[firebase-messaging-sw.js] Service Worker installed');
  self.skipWaiting();
});

// Handler para ativação do service worker
self.addEventListener('activate', (event) => {
  console.log('[firebase-messaging-sw.js] Service Worker activated');
  event.waitUntil(clients.claim());
});
