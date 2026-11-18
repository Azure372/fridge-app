// 蜀ｷ阡ｵ蠎ｫ邂｡逅・Service Worker: 繧ｪ繝輔Λ繧､繝ｳ縺ｧ繧る幕縺代ｋ繧医≧縺ｫ繝輔ぃ繧､繝ｫ繧偵く繝｣繝・す繝･縺吶ｋ
const CACHE = 'fridge-v18';
const FILES = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// 繝阪ャ繝医Ρ繝ｼ繧ｯ蜆ｪ蜈医∝､ｱ謨励＠縺溘ｉ繧ｭ繝｣繝・す繝･・域峩譁ｰ繧貞叙繧翫▽縺､繧ｪ繝輔Λ繧､繝ｳ縺ｧ繧ょ虚縺擾ｼ・self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request).then(res => {
      const copy = res.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy));
      return res;
    }).catch(() => caches.match(e.request).then(r => r || caches.match('./index.html')))
  );
});

// 騾夂衍繧偵ち繝・・縺励◆繧峨い繝励Μ繧帝幕縺・self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
    const c = list.find(w => 'focus' in w);
    return c ? c.focus() : self.clients.openWindow('./index.html');
  }));
});
