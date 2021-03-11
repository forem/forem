'use strict';

if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .register('/serviceworker.js', { scope: '/' })
    .then(function swStart(registration) {
      // registered!
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.log('ServiceWorker registration failed: ', error);
    });
}

window.addEventListener('beforeinstallprompt', (e) => {
  // beforeinstallprompt Event fired
  // e.userChoice will return a Promise.
  e.userChoice.then((choiceResult) => {
    ga('send', 'event', 'PWA-install', choiceResult.outcome);
  });
});
