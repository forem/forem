let pendingCommentBundlePromise = null;

/**
 * Ensures the `CommentTextArea` pack is loaded and returns its mounting helpers.
 * On pages with comment forms, `CommentTextArea/CommentTextArea.js` is included
 * via `<script defer>` so `window.Forem.renderCommentTextArea` is already available
 * synchronously. If not yet present, falls back to loading the script from the
 * `<meta name="comment-textarea-script">` asset path.
 *
 * @returns {Promise<{ CommentTextArea: Function, renderCommentTextArea: Function }>}
 */
export function loadCommentTextAreaBundle() {
  if (
    typeof window !== 'undefined' &&
    window.Forem?.renderCommentTextArea
  ) {
    return Promise.resolve({
      CommentTextArea: window.Forem.CommentTextArea,
      renderCommentTextArea: window.Forem.renderCommentTextArea,
    });
  }

  if (pendingCommentBundlePromise) {
    return pendingCommentBundlePromise;
  }

  const metaTag = document.querySelector(
    'meta[name="comment-textarea-script"]',
  );
  const scriptSrc =
    metaTag?.content || '/assets/CommentTextArea/CommentTextArea.js';

  pendingCommentBundlePromise = new Promise((resolve, reject) => {
    const existingScript = document.querySelector(
      `script[src="${scriptSrc}"], script[data-comment-textarea-bundle="true"]`,
    );
    const script = existingScript || document.createElement('script');

    const cleanupFailure = (err) => {
      pendingCommentBundlePromise = null;
      if (!existingScript) {
        script.remove();
      }
      reject(err);
    };

    script.addEventListener(
      'load',
      () => {
        if (window.Forem?.renderCommentTextArea) {
          resolve({
            CommentTextArea: window.Forem.CommentTextArea,
            renderCommentTextArea: window.Forem.renderCommentTextArea,
          });
        } else {
          cleanupFailure(
            new Error(
              'CommentTextArea bundle loaded without registering renderCommentTextArea',
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
      script.dataset.commentTextareaBundle = 'true';
      document.head.appendChild(script);
    }
  });

  return pendingCommentBundlePromise;
}

export function resetCommentTextAreaLoaderForTests() {
  pendingCommentBundlePromise = null;
}
