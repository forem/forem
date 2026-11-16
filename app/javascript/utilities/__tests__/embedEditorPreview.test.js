import { initializeEmbedEditorPreviews } from '@utilities/embedEditorPreview';
import { destroyAllPageEmbedWrappers } from '@utilities/pageEmbedWrapper';

function flushMicrotasks() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('embedEditorPreview', () => {
  let originalFetch;

  beforeEach(() => {
    destroyAllPageEmbedWrappers();
    originalFetch = global.fetch;
    global.getCsrfToken = () => 'csrf-secret-token';
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
    delete global.getCsrfToken;
  });

  it('fetches server-wrapped HTML instead of writing raw untrusted HTML into srcdoc', async () => {
    const textarea = document.querySelector('[data-embed-input="body_html"]');
    const previewBtn = document.querySelector('[data-embed-tab="preview"]');
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

    expect(global.fetch).toHaveBeenCalledWith(
      '/dashboard/embed_pages/preview',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ 'X-CSRF-Token': 'csrf-secret-token' }),
      }),
    );
    expect(frame.srcdoc).toContain('data-forem-embed="1"');
    expect(frame.srcdoc).not.toContain('http-equiv="refresh"');
  });

  it('shows a safe error notice and clears srcdoc if preview request fails', async () => {
    const previewBtn = document.querySelector('[data-embed-tab="preview"]');
    const frame = document.querySelector('[data-embed-preview-frame="true"]');
    const errorNotice = document.querySelector('[data-embed-preview-error="true"]');

    global.fetch = jest.fn(() => Promise.reject(new Error('network down')));

    initializeEmbedEditorPreviews(document);
    previewBtn.click();
    await flushMicrotasks();

    expect(frame.srcdoc).toBe('');
    expect(errorNotice.classList.contains('hidden')).toBe(false);
    expect(errorNotice.textContent).toBe('Preview failed');
  });
});
