if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/serviceworker.js', { scope: '/' })
    .then(function swStart(registration) {
      // registered!
    }).catch(function (error) {
      console.log('ServiceWorker registration failed: ', error);
    });
}

window.addEventListener('beforeinstallprompt', function (e) {
  // beforeinstallprompt Event fired
  // e.userChoice will return a Promise.
  e.userChoice.then(function (choiceResult) {
    ga('send', 'event', 'PWA-install', choiceResult.outcome);
  });
});
