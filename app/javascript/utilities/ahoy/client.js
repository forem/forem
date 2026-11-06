/**
 * Shared wrapper around the global `window.ahoy` instance initialized in `base.js`.
 *
 * Importing `ahoy.js` directly in individual esbuild packs bundles a duplicate ~6.4 KB
 * copy of `ahoy` per pack AND overwrites `window.ahoy.track` with a new closure whose
 * internal config defaults back to `{ cookies: true, trackVisits: true }` (clobbering
 * the `{ cookies: false, trackVisits: false }` configuration applied in `base.js`).
 *
 * Delegating dynamically at call time avoids both duplicate bundle weight and config resets.
 */
export const ahoy = {
  track(name, properties) {
    return window.ahoy?.track?.(name, properties);
  },
  configure(options) {
    return window.ahoy?.configure?.(options);
  },
};

export default ahoy;
