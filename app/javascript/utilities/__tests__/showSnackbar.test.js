import { showSnackbar, addSnackbarItem } from '../showSnackbar';

describe('showSnackbar', () => {
  let originalConsoleError;

  beforeEach(() => {
    originalConsoleError = console.error;
    console.error = jest.fn();
    delete window.top.addSnackbarItem;
  });

  afterEach(() => {
    console.error = originalConsoleError;
    delete window.top.addSnackbarItem;
    jest.restoreAllMocks();
  });

  test('calls top.addSnackbarItem when available', () => {
    const mockAddSnackbar = jest.fn();
    window.top.addSnackbarItem = mockAddSnackbar;

    showSnackbar('Test message');

    expect(mockAddSnackbar).toHaveBeenCalledWith({
      message: 'Test message',
      addCloseButton: true,
    });
  });

  test('passes custom addCloseButton option to top.addSnackbarItem', () => {
    const mockAddSnackbar = jest.fn();
    window.top.addSnackbarItem = mockAddSnackbar;

    showSnackbar('Test message', { addCloseButton: false });

    expect(mockAddSnackbar).toHaveBeenCalledWith({
      message: 'Test message',
      addCloseButton: false,
    });
  });

  test('handles SecurityError when accessing top and falls back to event dispatching', () => {
    Object.defineProperty(window, 'top', {
      get() {
        throw new Error('SecurityError: Blocked cross-origin frame');
      },
      configurable: true,
    });

    const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

    showSnackbar('Fallback message');

    expect(dispatchEventSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'snackbar:add',
        detail: {
          message: 'Fallback message',
          addCloseButton: true,
        },
      }),
    );

    // Restore top
    Object.defineProperty(window, 'top', {
      value: window,
      writable: true,
      configurable: true,
    });
  });

  test('dispatches custom event with addCloseButton detail when top.addSnackbarItem is unavailable', () => {
    const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

    showSnackbar('Event message', { addCloseButton: false });

    expect(dispatchEventSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'snackbar:add',
        detail: {
          message: 'Event message',
          addCloseButton: false,
        },
      }),
    );
  });

  test('formats Object and Error messages as strings', () => {
    const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

    const err = new Error('Something went wrong');
    showSnackbar(err);

    expect(dispatchEventSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'snackbar:add',
        detail: {
          message: 'Something went wrong',
          addCloseButton: true,
        },
      }),
    );
  });

  test('addSnackbarItem compatibility wrapper delegates to showSnackbar', () => {
    const mockAddSnackbar = jest.fn();
    window.top.addSnackbarItem = mockAddSnackbar;

    addSnackbarItem({ message: 'Legacy message', addCloseButton: true });

    expect(mockAddSnackbar).toHaveBeenCalledWith({
      message: 'Legacy message',
      addCloseButton: true,
    });
  });
});
