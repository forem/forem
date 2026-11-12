import {
  BrowserClient,
  Scope,
  breadcrumbsIntegration,
  browserApiErrorsIntegration,
  defaultStackParser,
  eventFiltersIntegration,
  functionToStringIntegration,
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

const SENSITIVE_HEADER_KEYS = new Set([
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
  'x-csrf-token',
  'api-key',
  'x-algolia-api-key',
  'health-check-token',
]);

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

    if (event.request.headers && typeof event.request.headers === 'object') {
      for (const key of Object.keys(event.request.headers)) {
        if (SENSITIVE_HEADER_KEYS.has(key.toLowerCase())) {
          delete event.request.headers[key];
        }
      }
    }
  }

  if (event.user && typeof event.user === 'object') {
    delete event.user.ip_address;
    delete event.user.email;
    delete event.user.username;
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

function createBackoffTransportFactory(baseTransportFactory) {
  let rateLimitedUntil = 0;

  return function makeBackoffTransport(options) {
    const innerTransport = baseTransportFactory(options);

    return {
      send(envelope) {
        if (Date.now() < rateLimitedUntil) {
          return Promise.resolve({ statusCode: 200 });
        }
        return Promise.resolve(innerTransport.send(envelope)).then((res) => {
          if (res && res.statusCode === 429) {
            rateLimitedUntil = Date.now() + RATE_LIMIT_BACKOFF_MS;
          }
          return res;
        });
      },
      flush(timeout) {
        return innerTransport.flush(timeout);
      },
    };
  };
}

function buildIntegrations({ enableGlobalHandlers }) {
  const integrations = [
    eventFiltersIntegration(),
    functionToStringIntegration(),
    browserApiErrorsIntegration(),
    breadcrumbsIntegration({
      console: true,
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
        data: safeJsonClone(sanitizeBreadcrumbMetadata(breadcrumb.data)),
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
    } else if (event.user && Object.keys(event.user).length === 0) {
      delete event.user;
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
        sentryClient.close(0);
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
      transport: createBackoffTransportFactory(customTransportFactory),
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
          ? safeJsonClone(sanitizeBreadcrumbMetadata(opts.metadata))
          : undefined;
      isolatedScope.addBreadcrumb({
        message: String(message || ''),
        category: (opts && opts.category) || 'custom',
        data: metadata,
      });
      return this;
    },

    notify(err, name, extra) {
      if (!config.dsn || !sentryClient || !isolatedScope || err == null) {
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
