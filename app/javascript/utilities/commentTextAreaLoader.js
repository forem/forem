const SCRIPT_META_SELECTOR = 'meta[name="comment-textarea-script"]';

export function loadCommentTextAreaBundle() {
  if (window.Forem?.CommentTextArea) {
    return Promise.resolve({ CommentTextArea: window.Forem.CommentTextArea });
  }

  const scriptPath = document
    .querySelector(SCRIPT_META_SELECTOR)
    ?.getAttribute('content');

  if (!scriptPath) {
    return Promise.reject(
      new Error('Missing comment-textarea-script meta tag'),
    );
  }

  return new Promise((resolve, reject) => {
    const existingScript = document.querySelector(
      `script[src="${scriptPath}"]`,
    );
    if (existingScript) {
      existingScript.addEventListener('load', () =>
        resolve({ CommentTextArea: window.Forem.CommentTextArea }),
      );
      existingScript.addEventListener('error', reject);
      return;
    }

    const script = document.createElement('script');
    script.src = scriptPath;
    script.defer = true;
    script.onload = () =>
      resolve({ CommentTextArea: window.Forem.CommentTextArea });
    script.onerror = reject;
    document.head.appendChild(script);
  });
}
