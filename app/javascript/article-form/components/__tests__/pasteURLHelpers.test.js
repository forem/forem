import { handleURLPasted } from '../pasteURLHelpers';

describe('pasteURLHelpers', () => {
  let textAreaRef;
  let handler;

  beforeEach(() => {
    jest.useFakeTimers();

    // Clean up any existing popovers
    const existing = document.getElementById('embed-url-popover');
    if (existing) existing.remove();

    textAreaRef = {
      current: {
        value: 'Some existing text\n',
        selectionStart: 19,
        selectionEnd: 19,
        offsetLeft: 0,
        scrollTop: 0,
        scrollLeft: 0,
        tagName: 'TEXTAREA',
        dispatchEvent: jest.fn(),
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
        getBoundingClientRect: () => ({
          top: 100,
          left: 50,
          right: 500,
          bottom: 400,
          width: 450,
          height: 300,
        }),
      },
    };

    handler = handleURLPasted(textAreaRef);
  });

  afterEach(() => {
    jest.useRealTimers();
    const existing = document.getElementById('embed-url-popover');
    if (existing) existing.remove();
  });

  function createPasteEvent(text, includeFiles = false) {
    const types = includeFiles ? ['Files', 'text/plain'] : ['text/plain'];
    return {
      clipboardData: {
        types,
        getData: () => text,
      },
    };
  }

  it('shows inline popover when a URL is pasted', () => {
    handler(createPasteEvent('https://youtube.com/watch?v=abc'));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).not.toBeNull();
    expect(popover.textContent).toContain('Embed this link?');
    expect(popover.textContent).toContain('Embed');
    expect(popover.textContent).toContain('Dismiss');
  });

  it('does not show popover for non-URL text', () => {
    handler(createPasteEvent('just some regular text'));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).toBeNull();
  });

  it('does not show popover for file pastes', () => {
    handler(createPasteEvent('https://example.com', true));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).toBeNull();
  });

  it('does not show popover when clipboardData is missing', () => {
    handler({});
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).toBeNull();
  });

  it('replaces URL with embed tag when Embed button is clicked', () => {
    const url = 'https://my-app.lovable.app';
    textAreaRef.current.value = `Some existing text\n${url}`;
    textAreaRef.current.selectionStart = 19;

    handler(createPasteEvent(url));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).not.toBeNull();
    const embedBtn = popover.querySelector(
      '.crayons-btn:not(.crayons-btn--ghost)',
    );
    embedBtn.click();

    expect(textAreaRef.current.value).toBe(
      `Some existing text\n{% embed ${url} %}`,
    );
    expect(textAreaRef.current.dispatchEvent).toHaveBeenCalledWith(
      expect.any(Event),
    );
  });

  it('removes popover when Dismiss button is clicked', () => {
    handler(createPasteEvent('https://example.com'));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).not.toBeNull();
    const dismissBtn = popover.querySelector('.crayons-btn--ghost');
    dismissBtn.click();

    expect(document.getElementById('embed-url-popover')).toBeNull();
  });

  it('does not show popover when URL is pasted mid-paragraph', () => {
    // Cursor is in the middle of existing text on the same line
    textAreaRef.current.value = 'Check out this link: ';
    textAreaRef.current.selectionStart = 21; // after "Check out this link: "

    handler(createPasteEvent('https://example.com'));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).toBeNull();
  });

  it('shows popover when URL is pasted on an empty first line', () => {
    textAreaRef.current.value = '';
    textAreaRef.current.selectionStart = 0;

    handler(createPasteEvent('https://example.com'));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).not.toBeNull();
  });

  it('does not show popover when URL is pasted inside an existing liquid tag', () => {
    const url = 'https://my-app.lovable.app';
    // Simulate pasting a URL to replace one already inside {% embed ... %}
    textAreaRef.current.value = `{% embed ${url} %}`;
    textAreaRef.current.selectionStart = 9; // right after "{% embed "

    handler(createPasteEvent(url));
    jest.advanceTimersByTime(10);

    const popover = document.getElementById('embed-url-popover');
    expect(popover).toBeNull();
  });

  it('uses fallback replacement when URL position has shifted', () => {
    const url = 'https://my-app.lovable.app';
    textAreaRef.current.selectionStart = 19;
    handler(createPasteEvent(url));
    jest.advanceTimersByTime(10);

    // Simulate the user having typed more text before clicking Embed
    textAreaRef.current.value = `Some existing text\nExtra text ${url}`;

    const popover = document.getElementById('embed-url-popover');
    expect(popover).not.toBeNull();
    const embedBtn = popover.querySelector(
      '.crayons-btn:not(.crayons-btn--ghost)',
    );
    embedBtn.click();

    expect(textAreaRef.current.value).toBe(
      `Some existing text\nExtra text {% embed ${url} %}`,
    );
  });
});
