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

        await userEvent.paste(textArea, 'https://example.com/some-page?ref=utm');

        await waitFor(() => {
            expect(mockURLHandler).toHaveBeenCalled();
        });

        // Assert argument wiring (event)
        const [evtArg] = mockURLHandler.mock.calls[0];
        expect(evtArg).toBeInstanceOf(Event);
    });

    // The server-side mention matcher (Html::Parser#wrap_mentions_with_links)
    // uses /\B@[a-z0-9_-]+/i. A neutralized token must no longer match it.
    const MENTION_MATCH = /\B@[a-z0-9_-]+/i;

    it('Non-URL text paste ending on an @mention neutralizes the mention and does not trigger suggestions', async () => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        // Paste content that ENDS on '@john', so the caret lands immediately
        // after the mention. This is the position where autocomplete would
        // normally fire, which makes it the meaningful regression case.
        await userEvent.paste(textArea, 'Hey @john');

        // 1) The '@john' in prose is neutralized so it no longer matches the
        //    server-side mention regex, while staying visually identical.
        const value = textArea.value;
        expect(value).toContain('@\u200Bjohn');
        expect(value.replace(/\u200B/g, '')).toBe('Hey @john');
        expect(MENTION_MATCH.test(value)).toBe(false);

        // 2) No URL handler for non-URL text
        expect(mockURLHandler).not.toHaveBeenCalled();

        // 3) No mention suggestion UI becomes visible
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
        expect(screen.queryByRole('combobox', { hidden: true })).not.toBeInTheDocument();

        // 4) No network calls to the mention suggestion endpoint.
        //    EditorBody fetches suggestions via fetchSearch('usernames', ...)
        //    which requests /search/usernames, so that is the URL to guard.
        const mentionsRequests = fetch.mock.calls.filter(([url]) =>
            /search\/usernames|mentions|user_suggest|\/users\/suggest/i.test(
                String(url),
            ),
        );
        expect(mentionsRequests.length).toBe(0);
    });

    it('Does not modify an @handle inside fenced or inline code', async () => {
        renderEditor();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        // @pkg appears inside both a fenced block and an inline code span.
        const pasted = 'See ```npm i @pkg/core``` and `@pkg` for details';
        await userEvent.paste(textArea, pasted);

        // Code-enclosed handles must survive verbatim (no zero-width space).
        const value = textArea.value;
        expect(value).not.toContain('\u200B');
        expect(value).toBe(pasted);

        expect(mockURLHandler).not.toHaveBeenCalled();
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
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