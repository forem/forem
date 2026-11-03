import { loadCommentTextAreaBundle } from '@utilities/commentTextAreaLoader';

const SCRIPT_PATH = '/assets/CommentTextArea/CommentTextArea-abc123.js';

function addScriptMeta() {
  const meta = document.createElement('meta');
  meta.name = 'comment-textarea-script';
  meta.content = SCRIPT_PATH;
  document.head.appendChild(meta);
}

function loadedScripts() {
  return document.head.querySelectorAll(`script[src="${SCRIPT_PATH}"]`);
}

describe('loadCommentTextAreaBundle', () => {
  beforeEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    window.Forem = {};
  });

  it('resolves immediately when window.Forem.CommentTextArea is already defined', async () => {
    const mockComponent = () => null;
    window.Forem.CommentTextArea = mockComponent;

    const result = await loadCommentTextAreaBundle();

    expect(result).toEqual({ CommentTextArea: mockComponent });
    expect(loadedScripts()).toHaveLength(0);
  });

  it('appends a deferred script tag and resolves when loaded', async () => {
    addScriptMeta();
    const mockComponent = () => null;

    const promise = loadCommentTextAreaBundle();
    const scripts = loadedScripts();

    expect(scripts).toHaveLength(1);
    expect(scripts[0].defer).toBe(true);

    window.Forem.CommentTextArea = mockComponent;
    scripts[0].onload();

    await expect(promise).resolves.toEqual({ CommentTextArea: mockComponent });
  });

  it('does not append duplicate script tags when already loading', async () => {
    addScriptMeta();
    const mockComponent = () => null;

    const firstPromise = loadCommentTextAreaBundle();
    const secondPromise = loadCommentTextAreaBundle();
    const scripts = loadedScripts();

    expect(scripts).toHaveLength(1);

    window.Forem.CommentTextArea = mockComponent;
    scripts[0].onload();
    scripts[0].dispatchEvent(new Event('load'));

    await expect(Promise.all([firstPromise, secondPromise])).resolves.toEqual([
      { CommentTextArea: mockComponent },
      { CommentTextArea: mockComponent },
    ]);
  });

  it('rejects when the script meta tag is missing', async () => {
    await expect(loadCommentTextAreaBundle()).rejects.toThrow(
      'Missing comment-textarea-script meta tag',
    );
  });
});
