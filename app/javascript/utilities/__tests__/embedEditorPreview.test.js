import { initializeEmbedEditorPreviews } from '@utilities/embedEditorPreview';
import {
  destroyAllPageEmbedWrappers,
  getSandboxedEmbedState,
} from '@utilities/pageEmbedWrapper';

function flushMicrotasks() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('embedEditorPreview', () => {
  let originalFetch;

  beforeEach(() => {
    destroyAllPageEmbedWrappers();
    originalFetch = global.fetch;
    global.getCsrfToken = jest.fn(() => Promise.resolve('csrf-secret-token'));
    document.head.innerHTML = '';
    document.body.innerHTML = `
      <div id="user-embed-html-editor" data-embed-editor="true" data-preview-url="/dashboard/embed_pages/preview">
        <button type="button" data-embed-tab="edit" aria-selected="true">Edit</button>
        <button type="button" data-embed-tab="preview" aria-selected="false">Preview</button>
        <div data-embed-pane="edit">
          <textarea data-embed-input="body_html"></textarea>
        </div>
        <div data-embed-pane="preview" data-sandboxed-embed="true" data-embed-preview="true" class="hidden">
          <div data-embed-preview-error="true" data-default-error="Preview failed" class="hidden"></div>
          <div class="ltag__page-viewport">
            <iframe data-embed-preview-frame="true"></iframe>
          </div>
        </div>
      </div>
    `;
  });

  afterEach(() => {
    destroyAllPageEmbedWrappers();
    global.fetch = originalFetch;
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete global.getCsrfToken;
  });

  it('awaits async getCsrfToken and fetches server-wrapped HTML instead of writing raw untrusted HTML into srcdoc', async () => {
    const textarea = document.querySelector('[data-embed-input="body_html"]');
    const previewBtn = document.querySelector('[data-embed-tab="preview"]');
    const previewPane = document.querySelector('[data-embed-pane="preview"]');
    const frame = document.querySelector('[data-embed-preview-frame="true"]');

    textarea.value = '<meta http-equiv="refresh" content="0;url=https://evil.com"><p>Widget</p>';

    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ wrapped_html: '<!DOCTYPE html><html data-forem-embed="1"><body><p>Widget</p></body></html>' }),
      }),
    );

    initializeEmbedEditorPreviews(document);
    previewBtn.click();
    await flushMicrotasks();

    expect(global.getCsrfToken).toHaveBeenCalledTimes(1);
    expect(global.fetch).toHaveBeenCalledWith(
      '/dashboard/embed_pages/preview',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ 'X-CSRF-Token': 'csrf-secret-token' }),
      }),
    );
    expect(frame.srcdoc).toContain('data-forem-embed="1"');
    expect(frame.srcdoc).not.toContain('http-equiv="refresh"');
    expect(getSandboxedEmbedState(previewPane)?.isSrcdocPreview).toBe(true);
  });

  it('prefers synchronous meta[name="csrf-token"] without calling async getCsrfToken', async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="meta-csrf-token">';
    const previewBtn = document.querySelector('[data-embed-tab="preview"]');
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ wrapped_html: '<!DOCTYPE html><html></html>' }),
      }),
    );

    initializeEmbedEditorPreviews(document);
    previewBtn.click();
    await flushMicrotasks();

    expect(global.getCsrfToken).not.toHaveBeenCalled();
    expect(global.fetch).toHaveBeenCalledWith(
      '/dashboard/embed_pages/preview',
      expect.objectContaining({
        headers: expect.objectContaining({ 'X-CSRF-Token': 'meta-csrf-token' }),
      }),
    );
  });

  it('surfaces localized server JSON errors on 422 responses and falls back on network failure', async () => {
    const previewBtn = document.querySelector('[data-embed-tab="preview"]');
    const frame = document.querySelector('[data-embed-preview-frame="true"]');
    const errorNotice = document.querySelector('[data-embed-preview-error="true"]');

    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: false,
        status: 422,
        json: () => Promise.resolve({ error: 'Body HTML is too large (maximum 100 KB)' }),
      }),
    );

    initializeEmbedEditorPreviews(document);
    previewBtn.click();
    await flushMicrotasks();

    expect(frame.srcdoc).toBe('');
    expect(errorNotice.classList.contains('hidden')).toBe(false);
    expect(errorNotice.textContent).toBe('Body HTML is too large (maximum 100 KB)');

    global.fetch = jest.fn(() => Promise.reject(new Error('network down')));
    previewBtn.click();
    await flushMicrotasks();

    expect(frame.srcdoc).toBe('');
    expect(errorNotice.textContent).toBe('Preview failed');
  });
});
