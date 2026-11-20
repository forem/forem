import { createAssetBundleLoader } from './loadAssetBundle';

const postscribeBundleLoader = createAssetBundleLoader({
  metaName: 'postscribe-script',
  fallbackSrc: '/assets/postscribeLoader.js',
  dataAttribute: 'postscribeBundle',
  getReadyValue: () =>
    typeof window.Forem?.postscribe === 'function'
      ? window.Forem.postscribe
      : null,
  errorMessage:
    'postscribeLoader bundle loaded without registering window.Forem.postscribe',
});

export function loadPostScribe() {
  return postscribeBundleLoader.load();
}

export function resetPostscribeLoaderForTests() {
  postscribeBundleLoader.reset();
}

function getGistTags(nodes) {
  const gistNodes = [];

  for (const node of nodes) {
    if (node.nodeType === 1) {
      if (node.classList.contains('ltag_gist-liquid-tag')) {
        gistNodes.push(node);
      }

      gistNodes.push(...node.querySelectorAll('.ltag_gist-liquid-tag'));
    }
  }

  return gistNodes;
}

function loadEmbeddedGists(postscribe, gistTags) {
  for (const gistTag of gistTags) {
    const gistWrapper = gistTag.firstElementChild;
    if (!gistWrapper) {
      continue;
    }
    postscribe(gistTag, gistWrapper.outerHTML, {
      beforeWrite(text) {
        return gistTag.childElementCount > 3 ? '' : text;
      },
    });
    gistWrapper.remove();
  }
}

function watchForGistTagInsertion(targetNode) {
  const config = { attributes: false, childList: true, subtree: true };

  const callback = async function (mutationsList) {
    for (const { type, addedNodes } of mutationsList) {
      if (type === 'childList' && addedNodes.length > 0) {
        const gistTags = getGistTags(addedNodes);
        if (gistTags.length > 0) {
          const postscribe = await loadPostScribe();
          loadEmbeddedGists(postscribe, gistTags);
        }
      }
    }
  };

  const observer = new MutationObserver(callback);
  observer.observe(targetNode, config);

  InstantClick.on('change', () => {
    observer.disconnect();
  });

  window.addEventListener('beforeunload', () => {
    observer.disconnect();
  });
}

export async function embedGists(targetNode) {
  // Only fetch postscribe if gist tags actually exist in the DOM
  const initialGistTags = document.querySelectorAll('.ltag_gist-liquid-tag');
  if (initialGistTags.length > 0) {
    const postscribe = await loadPostScribe();
    loadEmbeddedGists(postscribe, initialGistTags);
  }

  if (targetNode) {
    watchForGistTagInsertion(targetNode);
  }
}
