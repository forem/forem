import {
  addBreadcrumb as addSdkBreadcrumb,
  getIsolationScope,
  setCurrentClient,
} from '@sentry/browser';
import { createBetterstackErrorsClient } from '../betterstackErrorsAdapter';
import { defaultBeforeNotifyFilter } from '../frontendErrorTracking';

const TEST_DSN =
  'https://testtoken@s2773094.eu-central-1a.betterstackdata.com/2775219';

function extractEventsFromEnvelopes(envelopes) {
  const events = [];
  for (const envelope of envelopes) {
    const items = envelope[1] || [];
    for (const [itemHeader, itemPayload] of items) {
      if (itemHeader && itemHeader.type === 'event') {
        events.push(itemPayload);
      }
    }
  }
  return events;
}

function extractEnvelopeItemTypes(envelopes) {
  const types = [];
  for (const envelope of envelopes) {
    const items = envelope[1] || [];
    for (const [itemHeader] of items) {
      if (itemHeader && itemHeader.type) {
        types.push(itemHeader.type);
      }
    }
  }
  return types;
}

describe('betterstackErrorsAdapter', () => {
  let envelopes;
  let sendMock;
  let client;

  beforeEach(() => {
    envelopes = [];
    sendMock = jest.fn((envelope) => {
      envelopes.push(envelope);
      return Promise.resolve({ statusCode: 200 });
    });

    document.body.removeAttribute('data-user-status');
    localStorage.removeItem('current_user');

    client = createBetterstackErrorsClient({
      bindGlobal: false,
      enableGlobalHandlers: false,
      transport: () => ({
        send: sendMock,
        flush: () => Promise.resolve(true),
      }),
    });
  });

  afterEach(() => {
    client.clear();
  });

  it('returns false and sends nothing when no DSN is configured', () => {
    expect(client.notify(new Error('Unconfigured error'))).toBe(false);
    expect(sendMock).not.toHaveBeenCalled();
  });

  it('sends Error instances as exception events with environment and release', async () => {
    client.configure({
      dsn: TEST_DSN,
      environment: 'production',
      revision: 'commit-abc123',
    });

    expect(client.notify(new TypeError('Widget failed to mount'))).toBe(true);
    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].environment).toBe('production');
    expect(events[0].release).toBe('commit-abc123');
    expect(events[0].exception.values[0].type).toBe('TypeError');
    expect(events[0].exception.values[0].value).toBe('Widget failed to mount');
  });

  it('sends string notices as message events with extra detail and fingerprint support', async () => {
    client.configure({
      dsn: TEST_DSN,
      environment: 'production',
    });

    client.notify('Unable to flag user', '42', {
      fingerprint: ['flag-user-error'],
      context: { action: 'flag' },
    });
    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].message).toBe('Unable to flag user');
    expect(events[0].exception.values[0].type).toBeUndefined();
    expect(events[0].extra).toEqual(expect.objectContaining({ detail: '42' }));
    expect(events[0].fingerprint).toEqual(['flag-user-error']);
    expect(events[0].contexts.notify_context).toEqual({ action: 'flag' });
  });

  it('respects beforeNotify filters including default browser noise patterns', async () => {
    client.configure({ dsn: TEST_DSN, environment: 'production' });
    client.beforeNotify(defaultBeforeNotifyFilter);

    client.notify(
      new Error('ResizeObserver loop completed with undelivered notifications'),
    );
    client.notify(new Error('ChunkLoadError: Loading chunk 4 failed'));
    client.notify(new Error('MetaMask: RPC Error'));
    client.notify(new Error('Actionable application failure'));

    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].exception.values[0].value).toBe(
      'Actionable application failure',
    );
  });

  it('safely serializes circular PointerEvent.nativeEvent breadcrumbs and circular context', async () => {
    client.configure({ dsn: TEST_DSN, environment: 'production' });

    const clickEvent = new MouseEvent('click', { bubbles: true });
    clickEvent.nativeEvent = clickEvent;

    client.addBreadcrumb('button.crayons-btn', {
      category: 'ui.click',
      metadata: {
        selector: 'button.crayons-btn',
        event: clickEvent,
      },
    });

    const circularContext = { area: 'feed' };
    circularContext.self = circularContext;
    client.setContext(circularContext);

    client.notify(new Error('Error after circular click'));
    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].contexts.forem).toEqual({
      area: 'feed',
      self: '[Circular]',
    });
    const clickCrumb = events[0].breadcrumbs.find(
      (crumb) => crumb.category === 'ui.click',
    );
    expect(clickCrumb.data.event).toEqual({
      type: 'click',
      isTrusted: false,
    });
  });

  it('deduplicates bursts of identical errors while allowing distinct errors through', async () => {
    client.configure({ dsn: TEST_DSN, environment: 'production' });

    for (let i = 0; i < 6; i += 1) {
      client.notify(new SyntaxError('Repeated failure'));
    }
    client.notify(new RangeError('Distinct failure'));

    await client.getSentryClient().flush(100);

    // First 3 identical + 1 distinct = 4 events; remaining 3 duplicates suppressed
    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(4);
  });

  it('enforces maxErrors per page session', async () => {
    client.configure({
      dsn: TEST_DSN,
      environment: 'production',
      maxErrors: 2,
    });

    client.notify(new Error('Error one'));
    client.notify(new Error('Error two'));
    client.notify(new Error('Error three'));

    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(2);
  });

  it('backs off sending envelopes after receiving HTTP 429 Too Many Requests without consuming maxErrors', async () => {
    const nowSpy = jest.spyOn(Date, 'now');
    let currentTime = 1_700_000_000_000;
    nowSpy.mockImplementation(() => currentTime);

    try {
      sendMock.mockImplementationOnce((envelope) => {
        envelopes.push(envelope);
        return Promise.resolve({ statusCode: 429 });
      });

      client.configure({
        dsn: TEST_DSN,
        environment: 'production',
        maxErrors: 2,
      });

      client.notify(new Error('Triggers 429'));
      await client.getSentryClient().flush(100);
      expect(sendMock).toHaveBeenCalledTimes(1);

      // Errors suppressed during the 60s backoff must not exhaust maxErrors
      for (let i = 0; i < 5; i += 1) {
        client.notify(new Error(`Suppressed during backoff ${i}`));
      }
      await client.getSentryClient().flush(100);
      expect(sendMock).toHaveBeenCalledTimes(1);

      // Once backoff expires, subsequent errors can still be reported
      currentTime += 60_001;
      client.notify(new Error('Sent after backoff window'));
      await client.getSentryClient().flush(100);
      expect(sendMock).toHaveBeenCalledTimes(2);
    } finally {
      nowSpy.mockRestore();
    }
  });

  it('disables client_report envelopes when events are dropped in beforeSend', async () => {
    client.configure({
      dsn: TEST_DSN,
      environment: 'production',
      maxErrors: 1,
    });
    client.beforeNotify(defaultBeforeNotifyFilter);

    client.notify(new Error('ResizeObserver loop limit exceeded'));
    client.notify(new Error('First actionable failure'));
    client.notify(new Error('Dropped by maxErrors'));

    Object.defineProperty(document, 'visibilityState', {
      configurable: true,
      value: 'hidden',
    });
    document.dispatchEvent(new Event('visibilitychange'));
    await client.getSentryClient().flush(100);

    const itemTypes = extractEnvelopeItemTypes(envelopes);
    expect(itemTypes).toEqual(['event']);
    expect(itemTypes).not.toContain('client_report');
  });

  it('clears both manual and SDK isolation-scope automatic breadcrumbs on clear()', async () => {
    const globalClient = createBetterstackErrorsClient({
      bindGlobal: true,
      enableGlobalHandlers: false,
      transport: () => ({
        send: sendMock,
        flush: () => Promise.resolve(true),
      }),
    });

    try {
      globalClient.configure({ dsn: TEST_DSN, environment: 'production' });
      globalClient.addBreadcrumb('manual breadcrumb');
      addSdkBreadcrumb({
        category: 'navigation',
        message: 'automatic breadcrumb',
      });

      globalClient.clear();

      globalClient.notify(new Error('After clear'));
      await globalClient.getSentryClient().flush(100);

      const events = extractEventsFromEnvelopes(envelopes);
      expect(events).toHaveLength(1);
      expect(events[0].breadcrumbs).toBeUndefined();
    } finally {
      globalClient.clear();
      getIsolationScope().clearBreadcrumbs();
      setCurrentClient(undefined);
    }
  });

  it('attaches only signed-in user ID and scrubs sensitive headers/cookies/contexts/URLs/PII', async () => {
    document.body.dataset.userStatus = 'logged-in';
    localStorage.setItem(
      'current_user',
      JSON.stringify({
        id: 777,
        username: 'ben',
        email: 'secret@example.com',
      }),
    );

    client.configure({ dsn: TEST_DSN, environment: 'production' });
    client.setContext({
      user_id: 777,
      email: 'context@example.com',
      token: 'context-secret-token',
      apiKey: 'context-api-key',
      section: 'dashboard',
    });
    client.addBreadcrumb('GET /api/users', {
      category: 'fetch',
      metadata: {
        url: 'https://dev.to/api/users?confirmation_token=secret-tok',
        token: 'crumb-secret',
        method: 'GET',
      },
    });
    client.getScope().addEventProcessor((event) => {
      event.request = {
        url: 'https://dev.to/users/password/edit?reset_password_token=secret123',
        query_string: 'reset_password_token=secret123',
        cookies: { remember_user_token: 'secret-cookie' },
        data: { password: 'secret' },
        headers: {
          Authorization: 'Bearer secret',
          Cookie: 'remember_user_token=secret',
          'X-CSRF-Token': 'csrf-secret',
          'X-API-Key': 'api-key-secret',
          'X-Auth-Token': 'auth-token-secret',
          'X-Forwarded-For': '203.0.113.5',
          Referer:
            'https://dev.to/users/confirmation?confirmation_token=ref123',
          Accept: 'application/json',
        },
      };
      event.user = {
        id: '777',
        ip_address: '203.0.113.5',
        email: 'secret@example.com',
        username: 'ben',
      };
      return event;
    });

    client.notify(new Error('Authenticated dashboard error'), {
      params: { password: 'secret-password', reset_password_token: 'rp-tok' },
      extraToken: 'secret-extra-token',
      safeFlag: 'enabled',
    });
    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].sdk.settings.infer_ip).toBe('never');
    expect(events[0].user).toEqual({ id: '777' });
    expect(events[0].request.url).toBe('https://dev.to/users/password/edit');
    expect(events[0].request.query_string).toBeUndefined();
    expect(events[0].request.cookies).toBeUndefined();
    expect(events[0].request.data).toBeUndefined();
    expect(events[0].request.headers).toEqual({
      Referer: 'https://dev.to/users/confirmation',
      Accept: 'application/json',
    });
    expect(events[0].contexts.forem).toEqual({
      user_id: 777,
      email: '[Filtered]',
      token: '[Filtered]',
      apiKey: '[Filtered]',
      section: 'dashboard',
    });
    expect(events[0].contexts.notify_params).toEqual({
      password: '[Filtered]',
      reset_password_token: '[Filtered]',
    });
    expect(events[0].extra).toEqual({
      extraToken: '[Filtered]',
      safeFlag: 'enabled',
    });
    const fetchCrumb = events[0].breadcrumbs.find(
      (crumb) => crumb.category === 'fetch',
    );
    expect(fetchCrumb.data).toEqual({
      url: 'https://dev.to/api/users',
      token: '[Filtered]',
      method: 'GET',
    });
  });

  it('formats Response-like objects meaningfully and ignores invalid DSNs safely', async () => {
    const consoleErrorSpy = jest
      .spyOn(console, 'error')
      .mockImplementation(() => {});
    try {
      client.configure({ dsn: 'not-a-valid-dsn', environment: 'production' });
      expect(client.notify(new Error('Invalid DSN error'))).toBe(false);
    } finally {
      consoleErrorSpy.mockRestore();
    }

    client.configure({ dsn: TEST_DSN, environment: 'production' });
    const responseLike = {
      ok: false,
      status: 422,
      statusText: 'Unprocessable Entity',
      url: 'https://dev.to/onboarding?token=secret',
    };
    expect(client.notify(responseLike)).toBe(true);
    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].message).toBe('HTTP 422 Unprocessable Entity');
    expect(events[0].extra.response_url).toBe('https://dev.to/onboarding');
  });
});
