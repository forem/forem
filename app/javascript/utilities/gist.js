let postscribeImport;

async function getPostScribe() {
  if (postscribeImport) {
    // Grab the cached import so we're not always fetching it from the network.
    return postscribeImport;
  }

  const { default: postscribe } = await import('postscribe');
  postscribeImport = postscribe;

  return postscribeImport;
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
    postscribe(gistTag, gistTag.firstElementChild.outerHTML, {
      beforeWrite(text) {
        return gistTag.childElementCount > 3 ? '' : text;
      },
    });
  }
}

function watchForGistTagInsertion(targetNode, postscribe) {
  const config = { attributes: false, childList: true, subtree: true };

  const callback = function (mutationsList) {
    for (const { type, addedNodes } of mutationsList) {
      if (type === 'childList' && addedNodes.length > 0) {
        loadEmbeddedGists(postscribe, getGistTags(addedNodes));
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
  const postscribe = await getPostScribe();

  // Load gist tags that were rendered server-side
  loadEmbeddedGists(
    postscribe,
    document.querySelectorAll('.ltag_gist-liquid-tag'),
  );

  watchForGistTagInsertion(targetNode, postscribe);
}
