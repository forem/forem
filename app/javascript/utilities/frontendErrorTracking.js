// Keep this lazy proxy and ignore list in sync with app/assets/javascripts/base.js.erb.
const MAX_LAZY_QUEUE = 20;

export const DEFAULT_FRONTEND_ERROR_IGNORE_PATTERNS = [
  /ResizeObserver/i,
  /MetaMask/i,
  /MtPopUpList/i,
  /ChunkLoadError/i,
];

export function defaultBeforeNotifyFilter(notice) {
  if (!notice) {
    return true;
  }
  const parts = [];
  if (typeof notice.name === 'string' && notice.name) {
    parts.push(notice.name);
  }
  if (typeof notice.message === 'string' && notice.message) {
    parts.push(notice.message);
  }
  if (parts.length === 0) {
    return true;
  }
  const haystack = parts.join(': ');
  return !DEFAULT_FRONTEND_ERROR_IGNORE_PATTERNS.some((pattern) =>
    pattern.test(haystack),
  );
}

/**
 * Creates the lightweight on-demand error-tracking proxy installed on `window.Honeybadger`.
 *
 * Strictly enforces single-provider loading:
 * - When `dsn` is configured (`BETTER_STACK_JS_ERRORS_DSN`), ONLY `betterstack-errors-script`
 *   can load (`honeybadger-script` is never requested).
 * - Otherwise, when `apiKey` is configured (`HONEYBADGER_JS_API_KEY`), ONLY `honeybadger-script`
 *   can load (`betterstack-errors-script` is never requested).
 * - When neither is configured, no `window` listeners are attached and nothing loads.
 *
 * @param {object} [options]
 * @param {Window} [options.win]
 * @param {Document} [options.doc]
 * @returns {object}
 */
export function createLazyErrorTrackingProxy({
  win = typeof window !== 'undefined' ? window : undefined,
  doc = typeof document !== 'undefined' ? document : undefined,
} = {}) {
  const clientConfig = {};
  const beforeNotifyHandlers = [];
  let contextData = {};
  const breadcrumbs = [];
  const queue = [];
  let loadingPromise = null;
  let loadFailed = false;
  let listenersAttached = false;

  function isConfigured() {
    return Boolean(clientConfig.dsn || clientConfig.apiKey);
  }

  function getActiveScriptMetaName() {
    if (clientConfig.dsn) {
      return 'betterstack-errors-script';
    }
    if (clientConfig.apiKey) {
      return 'honeybadger-script';
    }
    return null;
  }

  function getLoadedClient() {
    if (win && win.Honeybadger && !win.Honeybadger.__isLazyProxy) {
      return win.Honeybadger;
    }
    return null;
  }

  function passesBeforeNotify(err) {
    const message =
      typeof err === 'string'
        ? err
        : err && typeof err.message === 'string'
          ? err.message
          : undefined;
    const name =
      err && typeof err === 'object' && typeof err.name === 'string'
        ? err.name
        : undefined;
    const notice = { name, message };
    for (let i = 0; i < beforeNotifyHandlers.length; i += 1) {
      try {
        if (beforeNotifyHandlers[i](notice) === false) {
          return false;
        }
      } catch (_err) {
        // Ignore filter errors
      }
    }
    return true;
  }

  function loadActiveClient() {
    if (!win || !doc) {
      return Promise.resolve(null);
    }
    const loadedClient = getLoadedClient();
    if (loadedClient) {
      return Promise.resolve(loadedClient);
    }
    if (loadFailed) {
      return Promise.resolve(null);
    }
    if (loadingPromise) {
      return loadingPromise;
    }

    const metaName = getActiveScriptMetaName();
    if (!metaName) {
      return Promise.resolve(null);
    }

    const meta = doc.querySelector(`meta[name="${metaName}"]`);
    const scriptSrc = meta && meta.getAttribute('content');
    if (!scriptSrc) {
      return Promise.resolve(null);
    }

    loadingPromise = new Promise((resolve) => {
      const script = doc.createElement('script');
      script.src = scriptSrc;
      script.defer = true;
      script.onload = () => {
        const realClient = getLoadedClient();
        if (realClient) {
          if (typeof realClient.configure === 'function') {
            realClient.configure(clientConfig);
          }
          for (let i = 0; i < beforeNotifyHandlers.length; i += 1) {
            if (typeof realClient.beforeNotify === 'function') {
              realClient.beforeNotify(beforeNotifyHandlers[i]);
            }
          }
          if (
            Object.keys(contextData).length > 0 &&
            typeof realClient.setContext === 'function'
          ) {
            realClient.setContext(contextData);
          }
          while (breadcrumbs.length > 0) {
            const crumbArgs = breadcrumbs.shift();
            if (typeof realClient.addBreadcrumb === 'function') {
              realClient.addBreadcrumb(...crumbArgs);
            }
          }
          while (queue.length > 0) {
            const args = queue.shift();
            if (typeof realClient.notify === 'function') {
              realClient.notify(...args);
            }
          }
          resolve(realClient);
        } else {
          loadFailed = true;
          breadcrumbs.length = 0;
          queue.length = 0;
          resolve(null);
        }
      };
      script.onerror = () => {
        loadFailed = true;
        loadingPromise = null;
        breadcrumbs.length = 0;
        queue.length = 0;
        script.remove();
        resolve(null);
      };
      doc.head.appendChild(script);
    });

    return loadingPromise;
  }

  let lazyProxy;

  function attachWindowListeners() {
    if (!win || listenersAttached || !isConfigured()) {
      return;
    }
    listenersAttached = true;

    win.addEventListener('error', (event) => {
      if (!win.Honeybadger || !win.Honeybadger.__isLazyProxy) {
        return;
      }
      const err = (event && event.error) || (event && event.message);
      if (err) {
        lazyProxy.notify(err);
      }
    });

    win.addEventListener('unhandledrejection', (event) => {
      if (!win.Honeybadger || !win.Honeybadger.__isLazyProxy) {
        return;
      }
      const reason = event && event.reason;
      if (reason) {
        lazyProxy.notify(reason);
      }
    });
  }

  lazyProxy = {
    __isLazyProxy: true,
    config: clientConfig,

    configure(opts) {
      const realClient = getLoadedClient();
      if (realClient && typeof realClient.configure === 'function') {
        return realClient.configure(opts);
      }
      if (opts && typeof opts === 'object') {
        Object.assign(clientConfig, opts);
        if (isConfigured()) {
          attachWindowListeners();
        }
      }
      return this;
    },

    beforeNotify(handler) {
      const realClient = getLoadedClient();
      if (realClient && typeof realClient.beforeNotify === 'function') {
        return realClient.beforeNotify(handler);
      }
      if (typeof handler === 'function') {
        beforeNotifyHandlers.push(handler);
      }
      return this;
    },

    setContext(ctx) {
      const realClient = getLoadedClient();
      if (realClient && typeof realClient.setContext === 'function') {
        return realClient.setContext(ctx);
      }
      if (ctx && typeof ctx === 'object') {
        Object.assign(contextData, ctx);
      }
      return this;
    },

    context(ctx) {
      return this.setContext(ctx);
    },

    clear() {
      contextData = {};
      breadcrumbs.length = 0;
      const realClient = getLoadedClient();
      if (realClient && typeof realClient.clear === 'function') {
        return realClient.clear();
      }
      return this;
    },

    resetContext(ctx) {
      const realClient = getLoadedClient();
      if (realClient && typeof realClient.resetContext === 'function') {
        return realClient.resetContext(ctx);
      }
      contextData = ctx && typeof ctx === 'object' ? { ...ctx } : {};
      return this;
    },

    addBreadcrumb(message, opts) {
      const realClient = getLoadedClient();
      if (realClient && typeof realClient.addBreadcrumb === 'function') {
        return realClient.addBreadcrumb(message, opts);
      }
      if (isConfigured()) {
        if (breadcrumbs.length >= MAX_LAZY_QUEUE) {
          breadcrumbs.shift();
        }
        breadcrumbs.push([message, opts]);
      }
      return this;
    },

    notify(err, name, extra) {
      if (loadFailed || !isConfigured() || !passesBeforeNotify(err)) {
        return false;
      }
      const realClient = getLoadedClient();
      if (realClient) {
        return realClient.notify(err, name, extra);
      }
      let errKey =
        typeof err === 'string'
          ? err
          : err && `${err.name || ''}:${err.message || ''}`;
      if (errKey === ':') {
        errKey = '';
      }
      const alreadyQueued =
        errKey &&
        queue.some((item) => {
          const queued = item[0];
          const queuedKey =
            typeof queued === 'string'
              ? queued
              : queued && `${queued.name || ''}:${queued.message || ''}`;
          return queuedKey === errKey;
        });
      if (!alreadyQueued && queue.length < MAX_LAZY_QUEUE) {
        queue.push([err, name, extra]);
      }
      loadActiveClient();
      return true;
    },
  };

  return lazyProxy;
}

/**
 * Installs and configures frontend error tracking on `win.Honeybadger` based on
 * `document.body.dataset`. Better Stack (`data-betterstack-errors-dsn`) strictly
 * takes precedence over Honeybadger (`data-honeybadger-key`). When neither is
 * present, error tracking remains completely inactive and loads no scripts.
 *
 * @param {object} [options]
 * @param {Window} [options.win]
 * @param {Document} [options.doc]
 * @param {string} [options.environment]
 * @returns {object|null}
 */
export function initializeFrontendErrorTracking({
  win = typeof window !== 'undefined' ? window : undefined,
  doc = typeof document !== 'undefined' ? document : undefined,
  environment,
} = {}) {
  if (!win || !doc) {
    return null;
  }

  if (!win.Honeybadger) {
    win.Honeybadger = createLazyErrorTrackingProxy({ win, doc });
  }

  const dataset = doc.body && doc.body.dataset;
  if (!dataset) {
    return win.Honeybadger;
  }

  const envMeta = doc.querySelector('meta[name="environment"]');
  const resolvedEnv =
    environment ||
    dataset.betterstackErrorsEnvironment ||
    dataset.environment ||
    (envMeta && envMeta.getAttribute('content')) ||
    'production';

  if (dataset.betterstackErrorsDsn) {
    if (!win.Honeybadger.config || !win.Honeybadger.config.dsn) {
      win.Honeybadger.configure({
        dsn: dataset.betterstackErrorsDsn,
        environment: resolvedEnv,
        revision:
          dataset.latestCommitId ||
          dataset.releaseFootprint ||
          dataset.deployedAt,
        maxErrors: MAX_LAZY_QUEUE,
      });
      win.Honeybadger.beforeNotify(defaultBeforeNotifyFilter);
    }
  } else if (dataset.honeybadgerKey) {
    if (!win.Honeybadger.config || !win.Honeybadger.config.apiKey) {
      win.Honeybadger.configure({
        apiKey: dataset.honeybadgerKey,
        environment:
          environment ||
          dataset.environment ||
          (envMeta && envMeta.getAttribute('content')) ||
          'production',
        revision: dataset.releaseFootprint || dataset.latestCommitId,
        maxErrors: MAX_LAZY_QUEUE,
      });
      win.Honeybadger.beforeNotify(defaultBeforeNotifyFilter);
    }
  }

  return win.Honeybadger;
}
