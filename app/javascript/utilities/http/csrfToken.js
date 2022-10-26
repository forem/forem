const MAX_RETRIES = 30;
const RETRY_INTERVAL = 250;

export function getCSRFToken() {
  const promise = new Promise((resolve, reject) => {
    // eslint-disable-next-line consistent-return
    let i = 0;
    const waitingOnCSRF = setInterval(() => {
      const metaTag = document.querySelector("meta[name='csrf-token']");
      i += 1;

      if (metaTag) {
        clearInterval(waitingOnCSRF);
        const authToken = metaTag.getAttribute('content');
        return resolve(authToken);
      }

      if (i === MAX_RETRIES) {
        clearInterval(waitingOnCSRF);
        Honeybadger.notify(
          `Could not locate CSRF metatag ${JSON.stringify(
            localStorage.current_user,
          )}`,
        );
        return reject(new Error('Could not locate CSRF meta tag on the page.'));
      }
    }, RETRY_INTERVAL);
  });
  return promise;
}
