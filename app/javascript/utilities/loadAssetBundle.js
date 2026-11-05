/**
 * Creates a reusable, InstantClick-safe lazy loader for a `<meta>`-referenced asset bundle.
 *
 * - Short-circuits immediately if `getReadyValue()` returns a non-null/undefined value.
 * - Deduplicates concurrent in-flight callers via a shared promise.
 * - Reuses an in-flight `<script>` element if already present in the DOM.
 * - Always removes failed `<script>` elements (including pre-existing eager `<script>` tags)
 *   and resets the cached promise so subsequent InstantClick navigations or interactions retry cleanly.
 *
 * @param {Object} options
 * @param {string} options.metaName Name attribute of the `<meta>` tag holding the fingerprinted script path.
 * @param {string} options.fallbackSrc Fallback script path when the `<meta>` tag is absent.
 * @param {string} options.dataAttribute Dataset key (`data-*` in camelCase) applied to dynamically injected `<script>` tags.
 * @param {Function} options.getReadyValue Returns the loaded global value when ready, or `null`/`undefined` when not yet loaded.
 * @param {string} options.errorMessage Error message used if the script loads without registering its expected global.
 * @returns {{ load: () => Promise<any>, reset: () => void }}
 */
export function createAssetBundleLoader({
  metaName,
  fallbackSrc,
  dataAttribute,
  getReadyValue,
  errorMessage,
}) {
  let pendingPromise = null;

  const kebabDataAttr = dataAttribute
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .toLowerCase();

  function load() {
    if (typeof window !== 'undefined') {
      const readyValue = getReadyValue();
      if (readyValue !== null && readyValue !== undefined) {
        return Promise.resolve(readyValue);
      }
    }

    if (pendingPromise) {
      return pendingPromise;
    }

    const metaTag = document.querySelector(`meta[name="${metaName}"]`);
    const scriptSrc = metaTag?.getAttribute('content') || fallbackSrc;

    pendingPromise = new Promise((resolve, reject) => {
      const existingScript = document.querySelector(
        `script[src="${scriptSrc}"], script[data-${kebabDataAttr}="true"]`,
      );
      const script = existingScript || document.createElement('script');

      const cleanupFailure = (err) => {
        pendingPromise = null;
        script.remove();
        reject(err);
      };

      script.addEventListener(
        'load',
        () => {
          const readyValue = getReadyValue();
          if (readyValue !== null && readyValue !== undefined) {
            resolve(readyValue);
          } else {
            cleanupFailure(new Error(errorMessage));
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
        script.dataset[dataAttribute] = 'true';
        document.head.appendChild(script);
      }
    });

    return pendingPromise;
  }

  function reset() {
    pendingPromise = null;
  }

  return { load, reset };
}
