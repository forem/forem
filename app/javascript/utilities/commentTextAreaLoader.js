import { createAssetBundleLoader } from './loadAssetBundle';

const commentTextAreaBundleLoader = createAssetBundleLoader({
  metaName: 'comment-textarea-script',
  fallbackSrc: '/assets/CommentTextArea/CommentTextArea.js',
  dataAttribute: 'commentTextareaBundle',
  getReadyValue: () =>
    window.Forem?.renderCommentTextArea
      ? {
          CommentTextArea: window.Forem.CommentTextArea,
          renderCommentTextArea: window.Forem.renderCommentTextArea,
        }
      : null,
  errorMessage:
    'CommentTextArea bundle loaded without registering renderCommentTextArea',
});

/**
 * Ensures the `CommentTextArea` pack is loaded and returns its mounting helpers.
 * On pages with comment forms for signed-in users, `CommentTextArea/CommentTextArea.js`
 * is included via `<script defer>` so `window.Forem.renderCommentTextArea` is available
 * synchronously. If not yet present, falls back to loading the script from the
 * `<meta name="comment-textarea-script">` asset path.
 *
 * @returns {Promise<{ CommentTextArea: Function, renderCommentTextArea: Function }>}
 */
export function loadCommentTextAreaBundle() {
  return commentTextAreaBundleLoader.load();
}

export function resetCommentTextAreaLoaderForTests() {
  commentTextAreaBundleLoader.reset();
}
