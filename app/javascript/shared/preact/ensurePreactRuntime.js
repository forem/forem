/**
 * Executes a Preact-dependent pack function immediately and synchronously when
 * `window.__foremPreact` is already initialized (100% of steady-state page loads).
 *
 * If a user with a stale pre-deploy `<head>` navigates via InstantClick (`?i=i`)
 * to a newly deployed `#page-content` before `window.__foremPreact` exists in `<head>`,
 * dynamically loads the fingerprinted `preactRuntime.js` bundle once (using
 * `#page-content[data-preact-runtime-src]` or `meta[name="preact-runtime-script"]`)
 * and then executes queued packs in order.
 *
 * @param {Function} runPack Callback containing the pack's compiled module body.
 * @returns {any}
 */
export function ensurePreactRuntime(runPack) {
  if (window.__foremPreact) {
    return runPack();
  }

  if (!window.__foremPreactLoadingPromise) {
    window.__foremPreactLoadingPromise = new Promise((resolve, reject) => {
      const pageContent = document.getElementById('page-content');
      const metaTag = document.querySelector(
        'meta[name="preact-runtime-script"]',
      );
      const scriptSrc =
        pageContent?.dataset?.preactRuntimeSrc ||
        metaTag?.getAttribute('content') ||
        '/assets/preactRuntime.js';

      const existingScript = document.querySelector(
        `script[src="${scriptSrc}"], script[data-preact-runtime-script="true"]`,
      );
      const script = existingScript || document.createElement('script');

      const cleanupFailure = (err) => {
        window.__foremPreactLoadingPromise = null;
        script.remove();
        reject(err);
      };

      script.addEventListener(
        'load',
        () => {
          if (window.__foremPreact) {
            resolve(window.__foremPreact);
          } else {
            cleanupFailure(new Error('Failed to initialize Preact runtime'));
          }
        },
        { once: true },
      );

      script.addEventListener(
        'error',
        () => {
          cleanupFailure(new Error(`Failed to load ${scriptSrc}`));
        },
        { once: true },
      );

      if (!existingScript) {
        script.src = scriptSrc;
        script.defer = true;
        script.dataset.preactRuntimeScript = 'true';
        document.head.appendChild(script);
      }
    });
  }

  return window.__foremPreactLoadingPromise.then(() => runPack());
}
