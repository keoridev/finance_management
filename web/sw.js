// ARC Finance - Capybara Service Worker
// Enables notifications directly in Android / Desktop OS notification shade

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Handle clicking on notification in system shade
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

// Listen for messages to post notifications from background & scheduled
self.addEventListener('message', (event) => {
  if (!event.data) return;

  if (event.data.type === 'SHOW_NOTIFICATION') {
    self.registration.showNotification(event.data.title, event.data.options);
  } else if (event.data.type === 'SCHEDULE_NOTIFICATION') {
    const delay = (event.data.seconds || 5) * 1000;
    setTimeout(() => {
      self.registration.showNotification(event.data.title, event.data.options);
    }, delay);
  }
});
