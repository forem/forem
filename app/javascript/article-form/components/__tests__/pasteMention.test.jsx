import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { screen, createEvent } from '@testing-library/dom';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { userEvent } from '@testing-library/user-event';
import { Form } from '../Form';

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
jest.mock('../helpers/paste', () => {
    const actual = jest.requireActual('../helpers/paste');
    return {
        ...actual,
        handleURLPasted: jest.fn(),
    };
});
import { handleURLPasted } from '../helpers/paste';

describe('<Form /> – paste behavior (regression tests)', () => {
    const baseProps = {
        titleDefaultValue: 'Test Title v2',
        titleOnChange: null,
        tagsDefaultValue: 'javascript, career',
        tagsOnInput: null,
        bodyDefaultValue: '',
        bodyOnChange: null,
        bodyHasFocus: false,
        version: 'v2', // v2 editor surface; paste behavior is shared
        mainImage:
            'https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png',
        onMainImageUrlChange: null,
        errors: null,
        switchHelpContext: null,
    };

    beforeEach(() => {
        jest.resetAllMocks();
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

    const renderForm = (override = {}) => render(<Form {...baseProps} {...override} />);

    it('URL text paste still triggers handleURLPasted', async () => {
        renderForm();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        await userEvent.paste(textArea, 'https://example.com/some-page?ref=utm');

        await waitFor(() => {
            expect(handleURLPasted).toHaveBeenCalledTimes(1);
        });

        // Assert argument wiring (event + textarea target)
        const [evtArg, targetArg] = handleURLPasted.mock.calls[0];
        expect(targetArg).toBe(textArea);
        expect(evtArg).toBeInstanceOf(Event);
    });

    it('Non-URL text paste neutralizes mention triggers (no mention UI, no mention fetch)', async () => {
        renderForm();

        const textArea = screen.getByRole('textbox', { name: /post content/i });

        // Paste content with '@' that would normally trigger mention suggestions
        await userEvent.paste(textArea, 'Hey @john — welcome!');

        // 1) The text shows up in the editor
        expect(textArea).toHaveValue('Hey @john — welcome!');

        // 2) No URL handler for non-URL text
        expect(handleURLPasted).not.toHaveBeenCalled();

        // 3) No mention suggestion UI becomes visible (adjust roles if your UI differs)
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
        expect(screen.queryByRole('combobox', { hidden: true })).not.toBeInTheDocument();

        // 4) No network calls to mention endpoints
        const mentionsRequests = fetch.mock.calls.filter(([url]) =>
            /mentions|user_suggest|\/users\/suggest/i.test(String(url)),
        );
        expect(mentionsRequests.length).toBe(0);
    });

    it('Image/file paste is unaffected (no URL handler; paste not blocked)', async () => {
        renderForm();

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
        expect(handleURLPasted).not.toHaveBeenCalled();

        // 2) New neutralization logic should not block file pastes
        // If your image paste flow intentionally prevents default, flip this expectation.
        expect(preventDefaultSpy).not.toHaveBeenCalled();

        // 3) No mention UI either
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
    });
});