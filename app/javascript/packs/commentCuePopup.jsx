import { h, render } from 'preact';
import { CommentCuePopup } from '../commentCue/CommentCuePopup';

const FLAG_NAME = 'comment_cue_popup';
const STORAGE_PREFIX = 'commentCueDismissed:';

export function init() {
  const flags = document.body.dataset.globalFeatureFlagsEnabled || '';
  if (!flags.split(' ').includes(FLAG_NAME)) return;

  const articleBody = document.querySelector('#article-body');
  if (!articleBody) return;

  const storageKey = `${STORAGE_PREFIX}${articleBody.dataset.articleId}`;
  if (window.sessionStorage.getItem(storageKey)) return;

  const message = articleBody.dataset.cueMessage;
  const closeLabel = articleBody.dataset.cueCloseLabel || 'Dismiss';
  if (!message) return;

  // Position a sentinel at the bottom of the article section to serve as both
  // the IntersectionObserver target and the popup's positioned ancestor
  const sentinel = document.createElement('div');
  sentinel.className = 'comment-cue-sentinel';
  sentinel.setAttribute('aria-hidden', 'true');
  // Append to the parent, so the popup is rendered below any billboards
  articleBody.parentElement.appendChild(sentinel);

  const dismiss = () => {
    window.sessionStorage.setItem(storageKey, '1');
    render(null, sentinel);
    sentinel.remove();
  };

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;

        observer.disconnect();
        render(
          <CommentCuePopup
            message={message}
            closeLabel={closeLabel}
            onDismiss={dismiss}
          />,
          sentinel,
        );
        return;
      }
    },
    { rootMargin: '0px 0px -100px 0px' },
  );
  observer.observe(sentinel);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
