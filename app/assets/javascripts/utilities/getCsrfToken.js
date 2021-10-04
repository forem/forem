/* global Honeybadger */

function getCsrfToken() {
  var promise = new Promise(function callback(resolve, reject) {
    var i = 0;
    // eslint-disable-next-line consistent-return
    var waitingOnCSRF = setInterval(function waitOnCSRF() {
      var metaTag = document.querySelector("meta[name='csrf-token']");
      i += 1;

      if (metaTag) {
        clearInterval(waitingOnCSRF);
        var authToken = metaTag.getAttribute('content');
        return resolve(authToken);
      }

      if (i === 1000) {
        clearInterval(waitingOnCSRF);
        Honeybadger.notify(
          i18next.t('csrf.notify', {
            user: JSON.stringify(localStorage.current_user),
          }),
        );
        return reject(new Error(i18next.t('csrf.error')));
      }
    }, 5);
  });
  return promise;
}
