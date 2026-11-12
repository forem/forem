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

  it('backs off sending envelopes after receiving HTTP 429 Too Many Requests', async () => {
    sendMock.mockImplementationOnce((envelope) => {
      envelopes.push(envelope);
      return Promise.resolve({ statusCode: 429 });
    });

    client.configure({ dsn: TEST_DSN, environment: 'production' });

    client.notify(new Error('Triggers 429'));
    await client.getSentryClient().flush(100);
    expect(sendMock).toHaveBeenCalledTimes(1);

    client.notify(new Error('Dropped during backoff'));
    await client.getSentryClient().flush(100);
    expect(sendMock).toHaveBeenCalledTimes(1);
  });

  it('attaches only signed-in user ID and scrubs sensitive headers/cookies/PII', async () => {
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
    client.getScope().addEventProcessor((event) => {
      event.request = {
        url: 'https://dev.to/dashboard',
        cookies: { remember_user_token: 'secret-cookie' },
        data: { password: 'secret' },
        headers: {
          Authorization: 'Bearer secret',
          Cookie: 'remember_user_token=secret',
          'X-CSRF-Token': 'csrf-secret',
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

    client.notify(new Error('Authenticated dashboard error'));
    await client.getSentryClient().flush(100);

    const events = extractEventsFromEnvelopes(envelopes);
    expect(events).toHaveLength(1);
    expect(events[0].user).toEqual({ id: '777' });
    expect(events[0].request.cookies).toBeUndefined();
    expect(events[0].request.data).toBeUndefined();
    expect(events[0].request.headers).toEqual({ Accept: 'application/json' });
  });
});
