const CACHE_NAME = 'elysion-v11';
const APP_SHELL = ['./', './index.html', './manifest.webmanifest', './splash-16a.jpg', './icon-512.png', './icon-1024.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE_NAME).then(c => c.addAll(APP_SHELL)));
  self.skipWaiting();
});
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (url.hostname.includes('supabase.co') || url.hostname.includes('workers.dev') || url.hostname.includes('apple.com')) return;
  e.respondWith(caches.match(e.request).then(cached => cached || fetch(e.request)));
});
