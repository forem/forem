import '@testing-library/jest-dom';
import {
  shouldLoadEventSignupButtons,
  loadEventSignupButtonsBundle,
  maybeLoadEventSignupButtons,
  resetEventSignupButtonsLoaderForTests,
} from '../eventSignupButtonsLoader';

describe('eventSignupButtonsLoader', () => {
  beforeEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.eventSignupCleanup;
    resetEventSignupButtonsLoaderForTests();
  });

  describe('shouldLoadEventSignupButtons', () => {
    it('returns false when no event signup buttons exist in the DOM', () => {
      expect(shouldLoadEventSignupButtons()).toBe(false);
    });

    it('returns true when an element with data-event-signup-button="true" exists', () => {
      document.body.innerHTML =
        '<button data-event-signup-button="true">Join</button>';
      expect(shouldLoadEventSignupButtons()).toBe(true);
    });
  });

  describe('loadEventSignupButtonsBundle', () => {
    it('resolves immediately if window.eventSignupCleanup is already defined', async () => {
      window.eventSignupCleanup = jest.fn();
      document.head.innerHTML =
        '<meta name="event-signup-buttons-script" content="/assets/eventSignupButtons-123.js">';

      await loadEventSignupButtonsBundle();

      expect(
        document.querySelector(
          'script[src="/assets/eventSignupButtons-123.js"]',
        ),
      ).not.toBeInTheDocument();
    });

    it('injects the script tag from meta[name="event-signup-buttons-script"] and resolves on load', async () => {
      document.head.innerHTML =
        '<meta name="event-signup-buttons-script" content="/assets/eventSignupButtons-123.js">';

      const promise = loadEventSignupButtonsBundle();
      const script = document.querySelector(
        'script[src="/assets/eventSignupButtons-123.js"]',
      );

      expect(script).toBeInTheDocument();
      script.onload();

      await expect(promise).resolves.toBeUndefined();
    });

    it('removes the failed script element on error so a subsequent attempt can retry', async () => {
      document.head.innerHTML =
        '<meta name="event-signup-buttons-script" content="/assets/eventSignupButtons-123.js">';

      const firstPromise = loadEventSignupButtonsBundle();
      const firstScript = document.querySelector(
        'script[src="/assets/eventSignupButtons-123.js"]',
      );

      expect(firstScript).toBeInTheDocument();
      firstScript.onerror();
      await firstPromise;

      expect(
        document.querySelector(
          'script[src="/assets/eventSignupButtons-123.js"]',
        ),
      ).not.toBeInTheDocument();

      const retryPromise = loadEventSignupButtonsBundle();
      const retryScript = document.querySelector(
        'script[src="/assets/eventSignupButtons-123.js"]',
      );

      expect(retryScript).toBeInTheDocument();
      retryScript.onload();
      await expect(retryPromise).resolves.toBeUndefined();
    });
  });

  describe('maybeLoadEventSignupButtons', () => {
    it('does not inject the script when no event signup button is present', async () => {
      document.head.innerHTML =
        '<meta name="event-signup-buttons-script" content="/assets/eventSignupButtons-123.js">';

      await maybeLoadEventSignupButtons();

      expect(
        document.querySelector(
          'script[src="/assets/eventSignupButtons-123.js"]',
        ),
      ).not.toBeInTheDocument();
    });

    it('injects the script when an event signup button is present', () => {
      document.head.innerHTML =
        '<meta name="event-signup-buttons-script" content="/assets/eventSignupButtons-123.js">';
      document.body.innerHTML =
        '<button data-event-signup-button="true">Join</button>';

      maybeLoadEventSignupButtons();

      expect(
        document.querySelector(
          'script[src="/assets/eventSignupButtons-123.js"]',
        ),
      ).toBeInTheDocument();
    });
  });
});
