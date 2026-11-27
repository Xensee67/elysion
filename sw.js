const CACHE_NAME = 'elysion-v12';
const APP_SHELL = ['./', './index.html', './manifest.webmanifest', './icon-512.png', './icon-1024.png'];

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
  if (url.hostname.includes('supabase.co') || url.hostname.includes('workers.dev') || url.hostname.includes('apple.com') || url.hostname.includes('lrclib.net')) return;
  e.respondWith(caches.match(e.request).then(cached => cached || fetch(e.request)));
});
