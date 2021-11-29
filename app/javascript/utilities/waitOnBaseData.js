/**
 * A util function to wrap any code that needs to wait until the page has
 * initialized correctly before executing. This is generally the case for
 * packs/components that require `/app/assets/initializers` to execute first,
 * this way you're ensured that global functions/namespaces will be available
 * (i.e. the Runtime class).
 *
 * @returns {Promise} A chainable promise that will fulfill when the page has
 * loaded correctly and all initializers have run.
 */
export function waitOnBaseData() {
  return new Promise((resolve) => {
    const waitingForDataLoad = setInterval(() => {
      if (document.body.getAttribute('data-loaded') === 'true') {
        clearInterval(waitingForDataLoad);
        resolve();
      }
    }, 100);
  });
}
