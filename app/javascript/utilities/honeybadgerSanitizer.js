const RATE_LIMIT_WINDOW_MS = 60_000;
const MAX_IDENTICAL_NOTICES_PER_WINDOW = 3;
const RATE_LIMIT_BACKOFF_MS = 60_000;

function isDomEvent(value) {
  if (!value || typeof value !== 'object') {
    return false;
  }
  if (typeof Event !== 'undefined' && value instanceof Event) {
    return true;
  }
  return Boolean(
    typeof value.type === 'string' &&
    ('nativeEvent' in value ||
      ('target' in value && 'currentTarget' in value && 'isTrusted' in value)),
  );
}

function isDomNodeOrWindow(value) {
  if (!value || typeof value !== 'object') {
    return false;
  }
  if (typeof Window !== 'undefined' && value instanceof Window) {
    return true;
  }
  if (typeof Node !== 'undefined' && value instanceof Node) {
    return true;
  }
  return (
    typeof value.nodeType === 'number' && typeof value.nodeName === 'string'
  );
}

function summarizeDomValue(value) {
  if (isDomEvent(value)) {
    return {
      type: String(value.type),
      isTrusted: Boolean(value.isTrusted),
    };
  }
  if (typeof Window !== 'undefined' && value instanceof Window) {
    return '[Window]';
  }
  const tag = value.nodeName ? String(value.nodeName).toLowerCase() : 'node';
  const idSuffix = value.id ? `#${value.id}` : '';
  return `[DOMNode ${tag}${idSuffix}]`;
}

/**
 * Clones arbitrary JSON-like data while safely handling circular references
 * (such as `PointerEvent.nativeEvent` added by `preact/compat`), DOM nodes,
 * functions, Symbols, and BigInts so `GlobalStore.getContents` never throws.
 *
 * @param {any} input
 * @returns {any}
 */
export function safeJsonClone(input) {
  if (input === undefined || input === null || typeof input !== 'object') {
    return input;
  }

  try {
    return JSON.parse(JSON.stringify(input));
  } catch (_err) {
    const ancestors = [];
    const serialized = JSON.stringify(input, function replacer(_key, val) {
      if (typeof val === 'bigint') {
        return val.toString();
      }
      if (typeof val === 'function' || typeof val === 'symbol') {
        return undefined;
      }
      if (!val || typeof val !== 'object') {
        return val;
      }
      if (isDomEvent(val) || isDomNodeOrWindow(val)) {
        return summarizeDomValue(val);
      }

      while (ancestors.length > 0 && ancestors[ancestors.length - 1] !== this) {
        ancestors.pop();
      }
      if (ancestors.includes(val)) {
        return '[Circular]';
      }
      ancestors.push(val);
      return val;
    });

    return serialized === undefined ? undefined : JSON.parse(serialized);
  }
}

export function sanitizeBreadcrumbMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object') {
    return metadata;
  }

  const sanitized = Array.isArray(metadata) ? [...metadata] : { ...metadata };
  for (const key of Object.keys(sanitized)) {
    const value = sanitized[key];
    if (isDomEvent(value) || isDomNodeOrWindow(value)) {
      sanitized[key] = summarizeDomValue(value);
    }
  }
  return sanitized;
}

function patchStoreInstance(store) {
  if (!store || store.__foremSafeClonePatched) {
    return;
  }
  store.__foremSafeClonePatched = true;

  store.getContents = function patchedGetContents(key) {
    const value = key ? this.contents[key] : this.contents;
    return safeJsonClone(value);
  };
}

/**
 * Hardens `@honeybadger-io/js` against:
 * 1. Circular `PointerEvent.nativeEvent` references mutated onto DOM events by `preact/compat`
 *    after Honeybadger's `ui.click` breadcrumb captures `metadata.event`.
 * 2. Circular objects in `context` or `breadcrumbs` serialized by `GlobalStore.getContents`.
 * 3. Identical error floods and HTTP 429 (`Too Many Requests`) retry storms.
 *
 * @param {object} client Honeybadger browser client instance.
 * @returns {object} Patched client.
 */
export function patchHoneybadgerClient(client) {
  if (!client || client.__foremPatched) {
    return client;
  }
  client.__foremPatched = true;

  patchStoreInstance(client.__store);

  if (typeof client.__initStore === 'function') {
    const originalInitStore = client.__initStore.bind(client);
    client.__initStore = function patchedInitStore(...args) {
      const result = originalInitStore(...args);
      patchStoreInstance(this.__store);
      return result;
    };
  }

  if (typeof client.addBreadcrumb === 'function') {
    const originalAddBreadcrumb = client.addBreadcrumb.bind(client);
    client.addBreadcrumb = function patchedAddBreadcrumb(message, opts) {
      if (opts && typeof opts === 'object' && opts.metadata) {
        return originalAddBreadcrumb(message, {
          ...opts,
          metadata: sanitizeBreadcrumbMetadata(opts.metadata),
        });
      }
      return originalAddBreadcrumb(message, opts);
    };
  }

  if (typeof client.beforeNotify === 'function') {
    const seenNotices = new Map();
    const dedupeHandler = (notice) => {
      if (!notice) {
        return true;
      }
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
    };

    client.beforeNotify(dedupeHandler);
  }

  if (client.__transport && typeof client.__transport.send === 'function') {
    const originalSend = client.__transport.send.bind(client.__transport);
    let rateLimitedUntil = 0;

    client.__transport.send = function patchedSend(options, payload) {
      if (Date.now() < rateLimitedUntil) {
        return Promise.resolve({
          statusCode: 201,
          body: '{"id":"rate-limited-skip"}',
        });
      }
      return originalSend(options, payload).then((res) => {
        if (res && res.statusCode === 429) {
          rateLimitedUntil = Date.now() + RATE_LIMIT_BACKOFF_MS;
        }
        return res;
      });
    };
  }

  if (typeof client.factory === 'function') {
    const originalFactory = client.factory.bind(client);
    client.factory = function patchedFactory(...args) {
      return patchHoneybadgerClient(originalFactory(...args));
    };
  }

  return client;
}
