export function waitForDataLoaded() {
  return new Promise((resolve) => {
    const waitingForDataLoad = setInterval(() => {
      if (document.body.getAttribute('data-loaded') === 'true') {
        clearInterval(waitingForDataLoad);
        resolve();
      }
    }, 100);
  });
}
