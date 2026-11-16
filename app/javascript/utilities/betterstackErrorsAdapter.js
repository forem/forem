import {
  BrowserClient,
  Scope,
  breadcrumbsIntegration,
  browserApiErrorsIntegration,
  defaultStackParser,
  eventFiltersIntegration,
  functionToStringIntegration,
  getClient,
  getIsolationScope,
  globalHandlersIntegration,
  httpContextIntegration,
  linkedErrorsIntegration,
  makeFetchTransport,
  setCurrentClient,
} from '@sentry/browser';
import {
  safeJsonClone,
  sanitizeBreadcrumbMetadata,
} from './honeybadgerSanitizer';

const RATE_LIMIT_WINDOW_MS = 60_000;
const MAX_IDENTICAL_NOTICES_PER_WINDOW = 3;
const RATE_LIMIT_BACKOFF_MS = 60_000;
const DEFAULT_MAX_ERRORS = 20;
const REDACTED_VALUE = '[Filtered]';
const MAX_SCRUB_DEPTH = 8;

const SENSITIVE_HEADER_KEYS = new Set([
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
  'x-csrf-token',
  'x-xsrf-token',
  'api-key',
  'x-api-key',
  'x-algolia-api-key',
  'x-auth-token',
  'health-check-token',
  'x-forwarded-for',
  'x-real-ip',
  'forwarded',
  'cf-connecting-ip',
  'true-client-ip',
]);

const SENSITIVE_FIELD_TOKENS = new Set([
  'authorization',
  'auth',
  'password',
  'passwd',
  'pwd',
  'secret',
  'token',
  'cookie',
  'cookies',
  'csrf',
  'xsrf',
  'credential',
  'credentials',
  'jwt',
  'bearer',
  'apikey',
  'email',
  'username',
  'phone',
  'mobile',
  'ssn',
  'cvv',
  'signature',
  'session',
  'forwarded',
  'ip',
]);

const SENSITIVE_TOKEN_PAIRS = [
  ['api', 'key'],
  ['access', 'key'],
  ['private', 'key'],
  ['signing', 'key'],
  ['encryption', 'key'],
  ['e', 'mail'],
  ['user', 'name'],
  ['credit', 'card'],
  ['card', 'number'],
];

const URL_FIELD_KEYS = new Set([
  'url',
  'href',
  'referer',
  'referrer',
  'from',
  'to',
  'request_url',
]);

function tokenizeFieldKey(key) {
  return String(key)
    .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
    .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean);
}

function isSensitiveFieldKey(key) {
  const tokens = tokenizeFieldKey(key);
  if (tokens.some((token) => SENSITIVE_FIELD_TOKENS.has(token))) {
    return true;
  }
  for (let i = 0; i < tokens.length - 1; i += 1) {
    const first = tokens[i];
    const second = tokens[i + 1];
    if (
      SENSITIVE_TOKEN_PAIRS.some(
        ([pairFirst, pairSecond]) =>
          first === pairFirst && second === pairSecond,
      )
    ) {
      return true;
    }
  }
  return false;
}

function isSensitiveHeaderKey(key) {
  const lower = String(key).toLowerCase();
  return SENSITIVE_HEADER_KEYS.has(lower) || isSensitiveFieldKey(lower);
}

function stripUrlQuery(url) {
  if (typeof url !== 'string' || !url) {
    return url;
  }
  const hashIndex = url.indexOf('#');
  const hash = hashIndex === -1 ? '' : url.slice(hashIndex);
  const withoutHash = hashIndex === -1 ? url : url.slice(0, hashIndex);
  const queryIndex = withoutHash.indexOf('?');
  let base = queryIndex === -1 ? withoutHash : withoutHash.slice(0, queryIndex);
  base = base.replace(/^([a-z][a-z0-9+.-]*:\/\/)([^/@?#]+)@/i, '$1');
  const safeHash =
    hash &&
    /(?:access_token|id_token|refresh_token|token|code|secret)=/i.test(hash)
      ? ''
      : hash;
  return `${base}${safeHash}`;
}

function scrubSensitiveFields(value, depth = 0) {
  if (
    value === null ||
    value === undefined ||
    typeof value !== 'object' ||
    depth >= MAX_SCRUB_DEPTH
  ) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => scrubSensitiveFields(item, depth + 1));
  }

  const scrubbed = {};
  for (const key of Object.keys(value)) {
    const entryValue = value[key];
    if (isSensitiveFieldKey(key)) {
      scrubbed[key] = REDACTED_VALUE;
    } else if (
      URL_FIELD_KEYS.has(key.toLowerCase()) &&
      typeof entryValue === 'string'
    ) {
      scrubbed[key] = stripUrlQuery(entryValue);
    } else {
      scrubbed[key] = scrubSensitiveFields(entryValue, depth + 1);
    }
  }
  return scrubbed;
}

function getSignedInUserId() {
  if (typeof document === 'undefined' || typeof localStorage === 'undefined') {
    return null;
  }
  if (document.body?.dataset?.userStatus !== 'logged-in') {
    return null;
  }
  try {
    const rawUser = localStorage.getItem('current_user');
    if (!rawUser) {
      return null;
    }
    const parsed = JSON.parse(rawUser);
    if (
      parsed &&
      (typeof parsed.id === 'number' || typeof parsed.id === 'string')
    ) {
      return String(parsed.id);
    }
  } catch (_err) {
    // Ignore malformed localStorage or SecurityError in restricted iframes
  }
  return null;
}

function scrubEventPii(event) {
  if (!event || typeof event !== 'object') {
    return event;
  }

  if (event.request && typeof event.request === 'object') {
    delete event.request.cookies;
    delete event.request.data;
    delete event.request.query_string;

    if (typeof event.request.url === 'string') {
      event.request.url = stripUrlQuery(event.request.url);
    }

    if (event.request.headers && typeof event.request.headers === 'object') {
      for (const key of Object.keys(event.request.headers)) {
        if (isSensitiveHeaderKey(key)) {
          delete event.request.headers[key];
        } else if (
          (key.toLowerCase() === 'referer' ||
            key.toLowerCase() === 'referrer') &&
          typeof event.request.headers[key] === 'string'
        ) {
          event.request.headers[key] = stripUrlQuery(
            event.request.headers[key],
          );
        }
      }
    }
  }

  if (event.contexts && typeof event.contexts === 'object') {
    event.contexts = scrubSensitiveFields(event.contexts);
  }

  if (event.extra && typeof event.extra === 'object') {
    event.extra = scrubSensitiveFields(event.extra);
  }

  if (event.tags && typeof event.tags === 'object') {
    event.tags = scrubSensitiveFields(event.tags);
  }

  if (Array.isArray(event.breadcrumbs)) {
    event.breadcrumbs = event.breadcrumbs.map((crumb) => {
      if (!crumb || typeof crumb !== 'object') {
        return crumb;
      }
      if (crumb.data && typeof crumb.data === 'object') {
        return {
          ...crumb,
          data: scrubSensitiveFields(crumb.data),
        };
      }
      return crumb;
    });
  }

  if (event.user && typeof event.user === 'object') {
    if (event.user.id !== undefined && event.user.id !== null) {
      event.user = { id: String(event.user.id) };
    } else {
      delete event.user;
    }
  }

  return event;
}

function extractNoticeDetails(event, hint) {
  const original = hint && hint.originalException;
  const firstException =
    event &&
    event.exception &&
    Array.isArray(event.exception.values) &&
    event.exception.values[0];

  if (typeof original === 'string') {
    return { name: '', message: original };
  }

  if (original && typeof original === 'object') {
    const origName = typeof original.name === 'string' ? original.name : '';
    const origMessage =
      typeof original.message === 'string' ? original.message : '';
    if (origName || origMessage) {
      return { name: origName, message: origMessage };
    }
  }

  if (firstException) {
    return {
      name: typeof firstException.type === 'string' ? firstException.type : '',
      message:
        typeof firstException.value === 'string' ? firstException.value : '',
    };
  }

  return {
    name: '',
    message: event && typeof event.message === 'string' ? event.message : '',
  };
}

function parseRetryAfterMs(headers) {
  if (!headers || typeof headers !== 'object') {
    return RATE_LIMIT_BACKOFF_MS;
  }
  const retryAfter = headers['retry-after'];
  if (retryAfter) {
    const seconds = Number(retryAfter);
    if (!Number.isNaN(seconds) && seconds > 0) {
      return Math.max(RATE_LIMIT_BACKOFF_MS, seconds * 1000);
    }
    const parsedDate = Date.parse(String(retryAfter));
    if (!Number.isNaN(parsedDate)) {
      return Math.max(RATE_LIMIT_BACKOFF_MS, parsedDate - Date.now());
    }
  }
  return RATE_LIMIT_BACKOFF_MS;
}

function envelopeContainsEventItem(envelope) {
  return (
    Array.isArray(envelope) &&
    Array.isArray(envelope[1]) &&
    envelope[1].some(
      (item) => Array.isArray(item) && item[0] && item[0].type === 'event',
    )
  );
}

function createBackoffTransport(baseTransportFactory, { onBackoffDrop } = {}) {
  let rateLimitedUntil = 0;

  return {
    isRateLimited() {
      return Date.now() < rateLimitedUntil;
    },
    transportFactory(options) {
      const innerTransport = baseTransportFactory(options);

      return {
        send(envelope) {
          if (Date.now() < rateLimitedUntil) {
            if (onBackoffDrop && envelopeContainsEventItem(envelope)) {
              onBackoffDrop();
            }
            return Promise.resolve({ statusCode: 200 });
          }
          return Promise.resolve()
            .then(() => innerTransport.send(envelope))
            .then((res) => {
              if (res && res.statusCode === 429) {
                const backoffMs = parseRetryAfterMs(res.headers);
                rateLimitedUntil = Math.max(
                  rateLimitedUntil,
                  Date.now() + backoffMs,
                );
              }
              return res;
            });
        },
        flush(timeout) {
          return innerTransport.flush(timeout);
        },
      };
    },
  };
}

function buildIntegrations({ enableGlobalHandlers }) {
  const integrations = [
    eventFiltersIntegration(),
    functionToStringIntegration(),
    browserApiErrorsIntegration(),
    breadcrumbsIntegration({
      dom: true,
      fetch: true,
      history: true,
      sentry: false,
      xhr: true,
    }),
    linkedErrorsIntegration(),
    httpContextIntegration(),
  ];

  if (enableGlobalHandlers) {
    integrations.push(
      globalHandlersIntegration({
        onerror: true,
        onunhandledrejection: true,
      }),
    );
  }

  return integrations;
}

/**
 * Creates a Better Stack frontend error tracking client backed by `@sentry/browser`
 * using Better Stack's Sentry-compatible DSN ingest.
 *
 * Exposes a `Honeybadger`-compatible interface (`configure`, `beforeNotify`,
 * `setContext`, `context`, `resetContext`, `clear`, `addBreadcrumb`, `notify`)
 * so existing Forem frontend error call sites route cleanly to Better Stack
 * when `BETTER_STACK_JS_ERRORS_DSN` is configured.
 *
 * @param {object} [initialOptions]
 * @returns {object}
 */
export function createBetterstackErrorsClient(initialOptions = {}) {
  const config = {
    maxErrors: DEFAULT_MAX_ERRORS,
  };
  const beforeNotifyHandlers = [];
  const seenNotices = new Map();
  let contextData = {};
  let sentCount = 0;
  let sentryClient = null;
  let isolatedScope = null;

  const bindGlobal = initialOptions.bindGlobal !== false;
  const customTransportFactory = initialOptions.transport || makeFetchTransport;
  const backoffTransport = createBackoffTransport(customTransportFactory, {
    onBackoffDrop() {
      sentCount = Math.max(0, sentCount - 1);
    },
  });

  function runsBeforeNotify(notice) {
    for (let i = 0; i < beforeNotifyHandlers.length; i += 1) {
      try {
        if (beforeNotifyHandlers[i](notice) === false) {
          return false;
        }
      } catch (_err) {
        // Ignore faulty filter callbacks
      }
    }
    return true;
  }

  function passesRateLimitDedupe(notice) {
    const signature = `${notice.name || ''}:${notice.message || ''}`;
    if (signature === ':') {
      return true;
    }

    const now = Date.now();
    if (seenNotices.size > 100) {
      for (const [key, entry] of seenNotices.entries()) {
        if (now - entry.windowStart > RATE_LIMIT_WINDOW_MS) {
          seenNotices.delete(key);
        }
      }
    }

    const existing = seenNotices.get(signature);
    if (!existing || now - existing.windowStart > RATE_LIMIT_WINDOW_MS) {
      seenNotices.set(signature, { count: 1, windowStart: now });
      return true;
    }

    existing.count += 1;
    return existing.count <= MAX_IDENTICAL_NOTICES_PER_WINDOW;
  }

  function beforeBreadcrumb(breadcrumb) {
    if (!breadcrumb || typeof breadcrumb !== 'object') {
      return breadcrumb;
    }
    if (breadcrumb.data && typeof breadcrumb.data === 'object') {
      return {
        ...breadcrumb,
        data: scrubSensitiveFields(
          safeJsonClone(sanitizeBreadcrumbMetadata(breadcrumb.data)),
        ),
      };
    }
    return breadcrumb;
  }

  function beforeSend(event, hint) {
    const maxErrors =
      typeof config.maxErrors === 'number' && config.maxErrors > 0
        ? config.maxErrors
        : DEFAULT_MAX_ERRORS;
    if (sentCount >= maxErrors) {
      return null;
    }
    if (backoffTransport.isRateLimited()) {
      return null;
    }

    const notice = extractNoticeDetails(event, hint);
    if (!runsBeforeNotify(notice)) {
      return null;
    }
    if (!passesRateLimitDedupe(notice)) {
      return null;
    }

    const clonedContext = safeJsonClone(contextData);
    if (clonedContext && Object.keys(clonedContext).length > 0) {
      event.contexts = {
        ...(event.contexts || {}),
        forem: clonedContext,
      };
    }

    const contextUserId =
      clonedContext && (clonedContext.user_id || clonedContext.userId);
    const resolvedUserId =
      contextUserId !== undefined && contextUserId !== null
        ? String(contextUserId)
        : getSignedInUserId();

    scrubEventPii(event);

    if (resolvedUserId) {
      event.user = { id: resolvedUserId };
    }

    sentCount += 1;
    return event;
  }

  function initSentryClient() {
    if (!config.dsn) {
      return null;
    }

    if (sentryClient) {
      try {
        Promise.resolve(sentryClient.close(1)).catch(() => {});
      } catch (_err) {
        // Ignore close errors when reconfiguring
      }
    }

    const enableGlobalHandlers =
      initialOptions.enableGlobalHandlers !== undefined
        ? Boolean(initialOptions.enableGlobalHandlers)
        : bindGlobal;

    sentryClient = new BrowserClient({
      dsn: config.dsn,
      environment: config.environment || undefined,
      release: config.release || config.revision || undefined,
      sendClientReports: false,
      dataCollection: {
        userInfo: false,
        cookies: false,
        httpBodies: false,
        urlQueryParams: false,
      },
      transport: backoffTransport.transportFactory,
      stackParser: defaultStackParser,
      integrations: buildIntegrations({ enableGlobalHandlers }),
      beforeBreadcrumb,
      beforeSend,
    });

    isolatedScope = new Scope();
    isolatedScope.setClient(sentryClient);

    if (bindGlobal) {
      setCurrentClient(sentryClient);
    }

    sentryClient.init();
    return sentryClient;
  }

  const adapter = {
    __provider: 'betterstack',
    config,

    configure(opts = {}) {
      if (opts && typeof opts === 'object') {
        const previousDsn = config.dsn;
        const previousEnv = config.environment;
        const previousRelease = config.release || config.revision;

        Object.assign(config, opts);

        const nextRelease = config.release || config.revision;
        if (
          config.dsn &&
          (!sentryClient ||
            config.dsn !== previousDsn ||
            config.environment !== previousEnv ||
            nextRelease !== previousRelease)
        ) {
          initSentryClient();
        }
      }
      return this;
    },

    beforeNotify(handler) {
      if (typeof handler === 'function') {
        beforeNotifyHandlers.push(handler);
      }
      return this;
    },

    setContext(ctx) {
      if (ctx && typeof ctx === 'object') {
        const sanitized = safeJsonClone(ctx);
        if (sanitized && typeof sanitized === 'object') {
          Object.assign(contextData, sanitized);
        }
      }
      return this;
    },

    context(ctx) {
      return this.setContext(ctx);
    },

    clear() {
      contextData = {};
      if (isolatedScope) {
        isolatedScope.clearBreadcrumbs();
      }
      if (bindGlobal || (sentryClient && getClient() === sentryClient)) {
        const sdkIsolationScope = getIsolationScope();
        if (sdkIsolationScope) {
          sdkIsolationScope.clearBreadcrumbs();
        }
      }
      return this;
    },

    resetContext(ctx) {
      contextData = {};
      if (ctx && typeof ctx === 'object') {
        this.setContext(ctx);
      }
      return this;
    },

    addBreadcrumb(message, opts = {}) {
      if (!isolatedScope) {
        return this;
      }
      const metadata =
        opts && typeof opts === 'object' && opts.metadata
          ? scrubSensitiveFields(
              safeJsonClone(sanitizeBreadcrumbMetadata(opts.metadata)),
            )
          : undefined;
      isolatedScope.addBreadcrumb({
        message: String(message || ''),
        category: (opts && opts.category) || 'custom',
        data: metadata,
      });
      return this;
    },

    notify(err, name, extra) {
      if (
        !config.dsn ||
        !sentryClient ||
        !isolatedScope ||
        !sentryClient.getDsn() ||
        !sentryClient.getTransport() ||
        err == null
      ) {
        return false;
      }

      const captureScope = isolatedScope.clone();
      let resolvedExtra =
        extra && typeof extra === 'object' ? safeJsonClone(extra) : null;

      if (name && typeof name === 'object') {
        resolvedExtra = {
          ...safeJsonClone(name),
          ...(resolvedExtra || {}),
        };
      } else if (name !== undefined && name !== null && name !== '') {
        captureScope.setExtra('detail', String(name));
      }

      if (resolvedExtra) {
        if (resolvedExtra.fingerprint) {
          const fp = Array.isArray(resolvedExtra.fingerprint)
            ? resolvedExtra.fingerprint.map(String)
            : [String(resolvedExtra.fingerprint)];
          captureScope.setFingerprint(fp);
        }
        if (
          resolvedExtra.context &&
          typeof resolvedExtra.context === 'object'
        ) {
          captureScope.setContext('notify_context', resolvedExtra.context);
        }
        if (resolvedExtra.params && typeof resolvedExtra.params === 'object') {
          captureScope.setContext('notify_params', resolvedExtra.params);
        }
        const remainingExtras = {};
        for (const key of Object.keys(resolvedExtra)) {
          if (key !== 'fingerprint' && key !== 'context' && key !== 'params') {
            remainingExtras[key] = resolvedExtra[key];
          }
        }
        if (Object.keys(remainingExtras).length > 0) {
          captureScope.setExtras(remainingExtras);
        }
      }

      if (err instanceof Error) {
        captureScope.captureException(err);
        return true;
      }

      if (typeof err === 'string') {
        captureScope.captureMessage(err, 'error');
        return true;
      }

      if (typeof err === 'object') {
        if (err.context && typeof err.context === 'object') {
          captureScope.setContext('notify_context', safeJsonClone(err.context));
        }
        if (err.params && typeof err.params === 'object') {
          captureScope.setContext('notify_params', safeJsonClone(err.params));
        }
        if (err.fingerprint) {
          const fp = Array.isArray(err.fingerprint)
            ? err.fingerprint.map(String)
            : [String(err.fingerprint)];
          captureScope.setFingerprint(fp);
        }
        if (err.error instanceof Error) {
          captureScope.captureException(err.error);
          return true;
        }
        if (typeof err.message === 'string') {
          if (typeof err.name === 'string' && err.name) {
            const synthetic = new Error(err.message);
            synthetic.name = err.name;
            if (typeof err.stack === 'string') {
              synthetic.stack = err.stack;
            }
            captureScope.captureException(synthetic);
          } else {
            captureScope.captureMessage(err.message, 'error');
          }
          return true;
        }
        if (typeof err.status === 'number' && 'ok' in err) {
          const statusLabel = err.statusText ? ` ${err.statusText}` : '';
          if (typeof err.url === 'string' && err.url) {
            captureScope.setExtra('response_url', stripUrlQuery(err.url));
          }
          captureScope.captureMessage(
            `HTTP ${err.status}${statusLabel}`,
            'error',
          );
          return true;
        }
        captureScope.captureException(err);
        return true;
      }

      captureScope.captureMessage(String(err), 'error');
      return true;
    },

    getSentryClient() {
      return sentryClient;
    },

    getScope() {
      return isolatedScope;
    },
  };

  if (initialOptions.dsn) {
    adapter.configure(initialOptions);
  }

  return adapter;
}
