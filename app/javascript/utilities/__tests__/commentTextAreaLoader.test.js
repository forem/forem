import {
  loadCommentTextAreaBundle,
  resetCommentTextAreaLoaderForTests,
} from '@utilities/commentTextAreaLoader';

describe('loadCommentTextAreaBundle', () => {
  beforeEach(() => {
    resetCommentTextAreaLoaderForTests();
    document.head.innerHTML =
      '<meta name="comment-textarea-script" content="/assets/CommentTextArea/CommentTextArea-test.js">';
    document.body.innerHTML = '';
    window.Forem = {};
  });

  it('resolves immediately when window.Forem.renderCommentTextArea is already registered', async () => {
    const fakeRender = jest.fn();
    const fakeComponent = () => null;
    window.Forem.CommentTextArea = fakeComponent;
    window.Forem.renderCommentTextArea = fakeRender;

    const result = await loadCommentTextAreaBundle();
    expect(result).toEqual({
      CommentTextArea: fakeComponent,
      renderCommentTextArea: fakeRender,
    });
    expect(
      document.querySelector('script[data-comment-textarea-bundle="true"]'),
    ).toBeNull();
  });

  it('injects the script tag once for concurrent callers and resolves when loaded', async () => {
    const promise1 = loadCommentTextAreaBundle();
    const promise2 = loadCommentTextAreaBundle();

    const scripts = document.querySelectorAll(
      'script[data-comment-textarea-bundle="true"]',
    );
    expect(scripts).toHaveLength(1);
    expect(scripts[0].getAttribute('src')).toEqual(
      '/assets/CommentTextArea/CommentTextArea-test.js',
    );

    const fakeRender = jest.fn();
    const fakeComponent = () => null;
    window.Forem.CommentTextArea = fakeComponent;
    window.Forem.renderCommentTextArea = fakeRender;
    scripts[0].dispatchEvent(new Event('load'));

    const [res1, res2] = await Promise.all([promise1, promise2]);
    expect(res1.renderCommentTextArea).toBe(fakeRender);
    expect(res2.renderCommentTextArea).toBe(fakeRender);
  });

  it('cleans up failed script and allows a subsequent call to retry', async () => {
    const firstAttempt = loadCommentTextAreaBundle();
    const firstScript = document.querySelector(
      'script[data-comment-textarea-bundle="true"]',
    );
    firstScript.dispatchEvent(new Event('error'));

    await expect(firstAttempt).rejects.toThrow(
      'Failed to load /assets/CommentTextArea/CommentTextArea-test.js',
    );
    expect(
      document.querySelector('script[data-comment-textarea-bundle="true"]'),
    ).toBeNull();

    const secondAttempt = loadCommentTextAreaBundle();
    const secondScript = document.querySelector(
      'script[data-comment-textarea-bundle="true"]',
    );
    expect(secondScript).not.toBeNull();

    const fakeRender = jest.fn();
    window.Forem.renderCommentTextArea = fakeRender;
    secondScript.dispatchEvent(new Event('load'));

    const result = await secondAttempt;
    expect(result.renderCommentTextArea).toBe(fakeRender);
  });
});
