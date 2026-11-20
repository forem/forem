import { createAssetBundleLoader } from './loadAssetBundle';

const SANDBOXED_EMBED_SELECTOR =
  '[data-sandboxed-embed="true"], .js-sandboxed-embed';
const EMBED_EDITOR_SELECTOR = '[data-embed-editor="true"]';

function rootHasMatch(root, selector) {
  if (!root) return false;
  if (typeof root.matches === 'function' && root.matches(selector)) {
    return true;
  }
  return (
    typeof root.querySelector === 'function' &&
    Boolean(root.querySelector(selector))
  );
}

const sandboxLoader = createAssetBundleLoader({
  metaName: 'page-embed-sandbox-script',
  fallbackSrc: '/assets/pageEmbedSandbox.js',
  dataAttribute: 'pageEmbedSandboxLoaded',
  getReadyValue: () =>
    typeof window.__foremInitSandboxedEmbeds === 'function' &&
    typeof window.__foremInitEmbedEditors === 'function'
      ? window.__foremInitSandboxedEmbeds
      : null,
  errorMessage: 'pageEmbedSandbox loaded without registering initializer',
});

export function initializePageEmbedSandboxLoader(root = document) {
  if (!root || (typeof root.querySelector !== 'function' && typeof root.matches !== 'function')) {
    return;
  }

  const hasEmbed = rootHasMatch(root, SANDBOXED_EMBED_SELECTOR);
  const hasEditor = rootHasMatch(root, EMBED_EDITOR_SELECTOR);
  if (!hasEmbed && !hasEditor) return;

  const embedsReady = typeof window.__foremInitSandboxedEmbeds === 'function';
  const editorsReady = typeof window.__foremInitEmbedEditors === 'function';

  if ((!hasEmbed || embedsReady) && (!hasEditor || editorsReady)) {
    if (hasEmbed) window.__foremInitSandboxedEmbeds(root);
    if (hasEditor) window.__foremInitEmbedEditors(root);
    return;
  }

  sandboxLoader.load().then(
    (initFn) => {
      if (typeof initFn === 'function') {
        initFn(root);
      }
      if (hasEditor && typeof window.__foremInitEmbedEditors === 'function') {
        window.__foremInitEmbedEditors(root);
      }
    },
    () => {
      // Failed loads remove the script element for retry on next navigation
    },
  );
}
