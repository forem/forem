let pendingPostscribePromise = null;

export function loadPostScribe() {
  if (
    typeof window !== 'undefined' &&
    typeof window.Forem?.postscribe === 'function'
  ) {
    return Promise.resolve(window.Forem.postscribe);
  }

  if (pendingPostscribePromise) {
    return pendingPostscribePromise;
  }

  const metaTag = document.querySelector('meta[name="postscribe-script"]');
  const scriptSrc = metaTag?.content || '/assets/postscribeLoader.js';

  pendingPostscribePromise = new Promise((resolve, reject) => {
    const existingScript = document.querySelector(
      `script[src="${scriptSrc}"], script[data-postscribe-bundle="true"]`,
    );
    const script = existingScript || document.createElement('script');

    const cleanupFailure = (err) => {
      pendingPostscribePromise = null;
      if (!existingScript) {
        script.remove();
      }
      reject(err);
    };

    script.addEventListener(
      'load',
      () => {
        if (typeof window.Forem?.postscribe === 'function') {
          resolve(window.Forem.postscribe);
        } else {
          cleanupFailure(
            new Error(
              'postscribeLoader bundle loaded without registering window.Forem.postscribe',
            ),
          );
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
      script.dataset.postscribeBundle = 'true';
      document.head.appendChild(script);
    }
  });

  return pendingPostscribePromise;
}

export function resetPostscribeLoaderForTests() {
  pendingPostscribePromise = null;
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
