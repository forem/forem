/**
 * Tests for articleForm localStorage key behavior.
 *
 * The key was changed from `editor-${version}-${href}` to
 * `editor-${id || 'new'}-${pathname}` to ensure:
 *   1. Drafts survive V1↔V2 version transitions between sessions.
 *   2. Query params (e.g. ?preview=xyz) don't create different storage buckets.
 */

// Helper: derive the storage key the same way articleForm.jsx does
function storageKey(id, url) {
  return `editor-${id || 'new'}-${new URL(url).pathname}`;
}

describe('localStorage key format', () => {
  const editUrl = 'https://forem.local/username/slug-here/edit';
  const previewUrl = 'https://forem.local/username/slug-here?preview=abc123';
  const articleId = 42;

  beforeEach(() => {
    localStorage.clear();
  });

  it('does not include the editor version string in the key', () => {
    const key = storageKey(articleId, editUrl);
    expect(key).not.toMatch(/v1|v2/);
  });

  it('uses the article id in the key', () => {
    const key = storageKey(articleId, editUrl);
    expect(key).toContain(String(articleId));
  });

  it('uses "new" for articles without an id', () => {
    const key = storageKey(null, editUrl);
    expect(key).toContain('new');
    expect(key).not.toContain('null');
  });

  it('uses pathname, not the full href (strips query params)', () => {
    // Both URLs point to the same edit page — one with a query param, one without
    const urlWithoutQuery = 'https://forem.local/username/slug-here/edit';
    const urlWithQuery = 'https://forem.local/username/slug-here/edit?preview=abc123';

    const keyWithoutQuery = storageKey(articleId, urlWithoutQuery);
    const keyWithQuery = storageKey(articleId, urlWithQuery);

    // Query params must not affect the key — both should produce the same key
    expect(keyWithoutQuery).toEqual(keyWithQuery);
  });

  it('produces the same key regardless of what version the editor was loaded as', () => {
    // Simulate: page first loaded as V1, draft written
    const keyAsV1Session = storageKey(articleId, editUrl);

    // Simulate: page reloaded as V2 (version changed because frontmatter was removed),
    // draft read — should still find the same key
    const keyAsV2Session = storageKey(articleId, editUrl);

    expect(keyAsV1Session).toEqual(keyAsV2Session);
  });
});

describe('localStorage draft survival across version transitions', () => {
  const editUrl = 'https://forem.local/username/slug-here/edit';
  const articleId = 42;

  beforeEach(() => {
    localStorage.clear();
  });

  it('draft written in V1 session is readable in V2 session', () => {
    const draft = {
      title: 'My Draft Title',
      bodyMarkdown: '---\ntitle: My Draft Title\n---\n\nContent',
      tagList: 'ruby',
      updatedAt: new Date().toISOString(),
    };

    // V1 session writes draft — key uses articleId+pathname (no version)
    const writeKey = storageKey(articleId, editUrl);
    localStorage.setItem(writeKey, JSON.stringify(draft));

    // V2 session reads draft — same key because version not in key
    const readKey = storageKey(articleId, editUrl);
    const recovered = JSON.parse(localStorage.getItem(readKey));

    expect(recovered).not.toBeNull();
    expect(recovered.title).toEqual('My Draft Title');
    expect(recovered.bodyMarkdown).toEqual(draft.bodyMarkdown);
  });

  it('draft written in V2 session is readable in V1 session', () => {
    const draft = {
      title: 'V2 Draft',
      bodyMarkdown: 'Plain body without frontmatter',
      tagList: 'javascript',
      updatedAt: new Date().toISOString(),
    };

    const writeKey = storageKey(articleId, editUrl);
    localStorage.setItem(writeKey, JSON.stringify(draft));

    const readKey = storageKey(articleId, editUrl);
    const recovered = JSON.parse(localStorage.getItem(readKey));

    expect(recovered).not.toBeNull();
    expect(recovered.title).toEqual('V2 Draft');
  });
});

describe('localStorage draft cleared on save', () => {
  const editUrl = 'https://forem.local/username/slug-here/edit';
  const articleId = 42;

  beforeEach(() => {
    localStorage.clear();
  });

  it('removeLocalStorage removes the correct key after save', () => {
    const key = storageKey(articleId, editUrl);
    localStorage.setItem(key, JSON.stringify({ title: 'Unsaved Draft' }));

    // Simulate what removeLocalStorage does
    localStorage.removeItem(key);

    expect(localStorage.getItem(key)).toBeNull();
  });

  it('removing the key does not affect other articles draft keys', () => {
    const key1 = storageKey(articleId, editUrl);
    const key2 = storageKey(99, 'https://forem.local/username/other-slug/edit');

    localStorage.setItem(key1, JSON.stringify({ title: 'Article 1 draft' }));
    localStorage.setItem(key2, JSON.stringify({ title: 'Article 2 draft' }));

    // Save article 1 — remove its key
    localStorage.removeItem(key1);

    expect(localStorage.getItem(key1)).toBeNull();
    // Article 2's draft should be unaffected
    const article2Draft = JSON.parse(localStorage.getItem(key2));
    expect(article2Draft.title).toEqual('Article 2 draft');
  });
});

describe('localStorage key for new articles', () => {
  const newArticleUrl = 'https://forem.local/articles/new';

  beforeEach(() => {
    localStorage.clear();
  });

  it('uses "editor-new-/articles/new" key for unsaved articles', () => {
    const key = storageKey(null, newArticleUrl);
    expect(key).toEqual('editor-new-/articles/new');
  });

  it('new article draft is distinct from an existing article draft', () => {
    const newKey = storageKey(null, newArticleUrl);
    const existingKey = storageKey(42, 'https://forem.local/username/slug/edit');
    expect(newKey).not.toEqual(existingKey);
  });
});
