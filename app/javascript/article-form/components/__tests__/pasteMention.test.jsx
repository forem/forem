import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { screen, createEvent } from '@testing-library/dom';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { userEvent } from '@testing-library/user-event';
import { EditorBody } from '../EditorBody';

// Keep original scrollTo so we can restore it after the suite
const originalScrollTo = window.scrollTo;

fetch.enableMocks();

// Mock Algolia (same pattern as other tests in the suite)
jest.mock('algoliasearch/lite', () => {
    const searchClient = {
        initIndex: jest.fn(() => ({
            search: jest.fn().mockResolvedValue({ hits: [] }),
        })),
    };
    return jest.fn(() => searchClient);
});

// mock the URL paste helper used by the Form
// Adjust this import path if your Form imports it from a different location.
jest.mock('../pasteURLHelpers', () => {
    const actual = jest.requireActual('../pasteURLHelpers');
    const mockHandler = jest.fn();
    return {
        ...actual,
        handleURLPasted: jest.fn(() => mockHandler),
        _mockHandler: mockHandler,
    };
});
import { handleURLPasted } from '../pasteURLHelpers';
const { _mockHandler: mockURLHandler } = require('../pasteURLHelpers');

describe('<Form /> – paste behavior (regression tests)', () => {
    const baseProps = {
        defaultValue: '',
        onChange: jest.fn(),
        switchHelpContext: null,
        version: 'v2',
    };

    beforeEach(() => {
        jest.clearAllMocks();
        fetch.resetMocks();

        global.Runtime = {
            isNativeIOS: jest.fn(() => false),
            getOSKeyboardModifierKeyString: jest.fn(() => 'cmd'),
        };

        global.window.matchMedia = jest.fn((query) => {
            return {
                matches: false,
                media: query,
                addListener: jest.fn(),
                removeListener: jest.fn(),
            };
        });

        // In jsdom, window.scrollTo is not implemented; mock to avoid throws.
        window.scrollTo = jest.fn();

        window.fetch = fetch;
        window.getCsrfToken = async () => 'this-is-a-csrf-token';

        // Default stub for incidental fetches (e.g., tags suggest)
        fetch.mockResponse((req) =>
            Promise.resolve(
                req.url.includes('/tags/suggest') ? '[]' : JSON.stringify({ result: [] }),
            ),
        );
    });

    afterAll(() => {
        window.scrollTo = originalScrollTo;
    });

    const renderEditor = (override = {}) => render(<EditorBody {...baseProps} {...override} />);

    it('URL text paste still triggers handleURLPasted', async () => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        textArea.focus();
        await userEvent.paste('https://example.com/some-page?ref=utm');

        await waitFor(() => {
            expect(mockURLHandler).toHaveBeenCalled();
        });

        // Assert argument wiring (event)
        const [evtArg] = mockURLHandler.mock.calls[0];
        expect(evtArg).toBeInstanceOf(Event);
    });

    it('Pastes a prose @mention verbatim and does not trigger suggestions', async () => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        // Paste content that ENDS on '@john', so the caret lands immediately
        // after the mention. This is the position where autocomplete would
        // normally fire, which makes it the meaningful regression case.
        textArea.focus();
        await userEvent.paste('Hey @john');

        // 1) The pasted text is saved exactly as authored. We deliberately do
        //    NOT inject a zero-width space: mentions are resolved server-side by
        //    Html::Parser#wrap_mentions_with_links, so body_markdown must stay
        //    byte-for-byte what the author pasted.
        const value = textArea.value;
        expect(value).toBe('Hey @john');
        expect(value).not.toContain('\u200B');

        // 2) No URL handler for non-URL text
        expect(mockURLHandler).not.toHaveBeenCalled();

        // 3) No mention suggestion UI becomes visible on paste
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
        expect(screen.queryByRole('combobox', { hidden: true })).not.toBeInTheDocument();

        // 4) No network calls to the mention suggestion endpoint on paste.
        //    EditorBody fetches suggestions via fetchSearch('usernames', ...)
        //    which requests /search/usernames, so that is the URL to guard.
        const mentionsRequests = fetch.mock.calls.filter(([url]) =>
            /search\/usernames|mentions|user_suggest|\/users\/suggest/i.test(
                String(url),
            ),
        );
        expect(mentionsRequests.length).toBe(0);
    });

    it('Pastes an @handle inside fenced or inline code verbatim', async () => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        // @pkg appears inside both a fenced block and an inline code span.
        const pasted = 'See ```npm i @pkg/core``` and `@pkg` for details';
        textArea.focus();
        await userEvent.paste(pasted);

        // Code (and everything else) must survive verbatim, with no injected
        // zero-width space that would corrupt a copied snippet.
        const value = textArea.value;
        expect(value).not.toContain('\u200B');
        expect(value).toBe(pasted);

        expect(mockURLHandler).not.toHaveBeenCalled();
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
    });

    // Regression guard: '@' after '/' (inside URLs, markdown link targets, and
    // liquid tags) must never be altered. A previous approach inserted U+200B
    // after every '@', which broke these by pointing links at the wrong page
    // and stopping MediumTag::REGISTRY_REGEXP from matching.
    it.each([
        ['a URL in prose', 'Read https://medium.com/@author/post today'],
        ['a markdown link target', '[me](https://mastodon.social/@alice)'],
        ['a liquid embed tag', 'before {% embed https://medium.com/@a/b %} after'],
    ])('pastes %s verbatim, leaving @ after / untouched', async (_label, pasted) => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        textArea.focus();
        await userEvent.paste(pasted);

        const value = textArea.value;
        expect(value).toBe(pasted);
        expect(value).not.toContain('\u200B');
    });

    it('Image/file paste is unaffected (no URL handler; paste not blocked)', async () => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        const file = new File(['PNGDATA'], 'pic.png', { type: 'image/png' });

        // Build a synthetic paste event with files in the clipboard
        const pasteEvent = createEvent.paste(textArea, { bubbles: true, cancelable: true });
        const dt = {
            types: ['Files'],
            files: [file],
            items: [
                {
                    kind: 'file',
                    type: 'image/png',
                    getAsFile: () => file,
                },
            ],
            getData: () => '',
        };

        Object.defineProperty(pasteEvent, 'clipboardData', {
            value: dt,
            writable: false,
        });

        const preventDefaultSpy = jest.spyOn(pasteEvent, 'preventDefault');

        textArea.dispatchEvent(pasteEvent);

        // 1) URL-specific handler should not run
        expect(mockURLHandler).not.toHaveBeenCalled();

        // 2) The image paste handler owns file pastes and calls preventDefault
        //    (pasteImageHelpers#handleImagePasted) before processing the image.
        expect(preventDefaultSpy).toHaveBeenCalled();

        // 3) No mention UI either
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
    });
});