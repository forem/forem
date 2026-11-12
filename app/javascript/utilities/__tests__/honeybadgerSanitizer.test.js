import Honeybadger from '@honeybadger-io/js/dist/browser/honeybadger.js';
import {
  patchHoneybadgerClient,
  safeJsonClone,
  sanitizeBreadcrumbMetadata,
} from '../honeybadgerSanitizer';

describe('honeybadgerSanitizer', () => {
  describe('safeJsonClone', () => {
    it('clones plain objects identically to JSON.parse(JSON.stringify(...))', () => {
      const payload = { a: 1, nested: { b: 'two', list: [true, null] } };
      expect(safeJsonClone(payload)).toEqual(payload);
      expect(safeJsonClone(payload)).not.toBe(payload);
    });

    it('safely serializes circular PointerEvent.nativeEvent structures created by preact/compat', () => {
      const clickEvent = new MouseEvent('click', { bubbles: true });
      clickEvent.nativeEvent = clickEvent;

      expect(() => JSON.stringify({ event: clickEvent })).toThrow(TypeError);

      const cloned = safeJsonClone([
        {
          category: 'ui.click',
          message: 'button.crayons-btn',
          metadata: {
            selector: 'body > button',
            text: 'Save',
            event: clickEvent,
          },
        },
      ]);

      expect(cloned).toEqual([
        {
          category: 'ui.click',
          message: 'button.crayons-btn',
          metadata: {
            selector: 'body > button',
            text: 'Save',
            event: {
              type: 'click',
              isTrusted: false,
            },
          },
        },
      ]);
    });

    it('replaces arbitrary object cycles with [Circular] while preserving shared non-circular siblings', () => {
      const shared = { tag: 'javascript' };
      const root = { first: shared, second: shared };
      root.self = root;

      const cloned = safeJsonClone(root);
      expect(cloned).toEqual({
        first: { tag: 'javascript' },
        second: { tag: 'javascript' },
        self: '[Circular]',
      });
    });
  });

  describe('sanitizeBreadcrumbMetadata', () => {
    it('replaces DOM Event and Node values with compact plain summaries', () => {
      const button = document.createElement('button');
      button.id = 'save-btn';
      const event = new MouseEvent('click');
      event.nativeEvent = event;

      const sanitized = sanitizeBreadcrumbMetadata({
        selector: 'button#save-btn',
        event,
        node: button,
      });

      expect(sanitized).toEqual({
        selector: 'button#save-btn',
        event: { type: 'click', isTrusted: false },
        node: '[DOMNode button#save-btn]',
      });
      expect(() => JSON.stringify(sanitized)).not.toThrow();
    });
  });

  describe('patchHoneybadgerClient', () => {
    let client;
    let transportSendSpy;

    beforeEach(() => {
      client = Honeybadger.factory({
        apiKey: 'hb-test-key',
        environment: 'production',
        reportData: true,
        maxErrors: 20,
        enableUncaught: false,
        enableUnhandledRejection: false,
        breadcrumbsEnabled: {
          console: false,
          dom: false,
          fetch: false,
          history: false,
          network: false,
        },
        logger: {
          debug: jest.fn(),
          info: jest.fn(),
          warn: jest.fn(),
          error: jest.fn(),
          log: jest.fn(),
        },
      });
      transportSendSpy = jest
        .spyOn(client.__transport, 'send')
        .mockResolvedValue({ statusCode: 201, body: '{"id":"notice-1"}' });
      patchHoneybadgerClient(client);
    });

    afterEach(() => {
      client.clear();
    });

    it('prevents PointerEvent.nativeEvent circular JSON TypeError when reporting after a UI click breadcrumb', async () => {
      const pointerEvent = new MouseEvent('click', { bubbles: true });
      client.addBreadcrumb('button.like', {
        category: 'ui.click',
        metadata: {
          selector: 'body > button.like',
          text: 'Like',
          event: pointerEvent,
        },
      });
      // Simulate preact/compat mutating the live event after capture-phase listener ran
      pointerEvent.nativeEvent = pointerEvent;

      expect(() => client.__store.getContents('breadcrumbs')).not.toThrow();

      client.notify(new Error('Navigation error'));

      await new Promise((resolve) => {
        setTimeout(resolve, 20);
      });

      expect(transportSendSpy).toHaveBeenCalledTimes(1);
      const sentPayload = transportSendSpy.mock.calls[0][1];
      const clickCrumb = sentPayload.breadcrumbs.trail.find(
        (crumb) => crumb.category === 'ui.click',
      );
      expect(clickCrumb.metadata.event).toEqual({
        type: 'click',
        isTrusted: false,
      });
    });

    it('never throws when circular objects are stored directly in Honeybadger context', () => {
      const circularContext = { page: 'feed' };
      circularContext.self = circularContext;
      client.setContext(circularContext);

      expect(() => client.__store.getContents('context')).not.toThrow();
      expect(client.__store.getContents('context')).toEqual({
        page: 'feed',
        self: {
          page: 'feed',
          self: '[Circular]',
        },
      });
    });

    it('deduplicates bursts of identical error notices while allowing distinct errors through', async () => {
      for (let i = 0; i < 6; i += 1) {
        client.notify(
          new SyntaxError("Identifier 'x' has already been declared"),
        );
      }
      client.notify(new TypeError('Distinct failure'));

      await new Promise((resolve) => {
        setTimeout(resolve, 20);
      });

      // First 3 identical notices + 1 distinct notice are sent; remaining 3 duplicates are suppressed
      expect(transportSendSpy).toHaveBeenCalledTimes(4);
    });

    it('backs off sending additional requests after receiving HTTP 429 Too Many Requests', async () => {
      transportSendSpy.mockResolvedValueOnce({ statusCode: 429, body: '' });

      client.notify(new Error('First error triggers 429'));
      await new Promise((resolve) => {
        setTimeout(resolve, 20);
      });
      expect(transportSendSpy).toHaveBeenCalledTimes(1);

      client.notify(new Error('Second error during backoff'));
      await new Promise((resolve) => {
        setTimeout(resolve, 20);
      });
      // Transport is short-circuited during backoff window
      expect(transportSendSpy).toHaveBeenCalledTimes(1);
    });
  });
});
