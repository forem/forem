const SHADOW_HOST_SELECTOR = '[data-billboard-shadow-host="true"]';
const SHADOW_SCRIPT_SELECTOR = 'script[data-billboard-script="true"]';
const STATE_KEY = '__foremBillboardShadowState';

function getSharedState() {
  if (!globalThis[STATE_KEY]) {
    globalThis[STATE_KEY] = {
      controllers: new WeakMap(),
      activeHosts: new Set(),
      themeObserver: null,
      beforeUnloadBound: false,
    };
  }
  return globalThis[STATE_KEY];
}

function logBillboardError(billboardId, context, error) {
  const label = billboardId ? `[Billboard ${billboardId}]` : '[Billboard]';
  // eslint-disable-next-line no-console
  console.error(`${label} ${context}:`, error);
}

function isDarkThemeActive() {
  return Boolean(document.body?.classList?.contains('dark-theme'));
}

function syncThemeForHost(host, isDark = isDarkThemeActive()) {
  if (!host) return;
  const theme = isDark ? 'dark' : 'light';
  host.classList.toggle('dark-theme', isDark);
  host.dataset.theme = theme;

  const shadowBody = host.shadowRoot?.querySelector('.billboard-shadow-body');
  if (shadowBody) {
    shadowBody.classList.toggle('dark-theme', isDark);
    shadowBody.dataset.theme = theme;
  }
}

function ensureGlobalObservers() {
  const state = getSharedState();

  if (
    !state.themeObserver &&
    typeof MutationObserver === 'function' &&
    document.body
  ) {
    state.themeObserver = new MutationObserver(() => {
      const isDark = isDarkThemeActive();
      state.activeHosts.forEach((host) => {
        if (host.isConnected) {
          syncThemeForHost(host, isDark);
        }
      });
    });
    state.themeObserver.observe(document.body, {
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  if (!state.beforeUnloadBound && typeof window !== 'undefined') {
    state.beforeUnloadBound = true;
    window.addEventListener('beforeunload', cleanupAllBillboardSandboxes);
  }
}

function findDirectShadowTemplate(host) {
  for (let i = 0; i < host.children.length; i += 1) {
    const child = host.children[i];
    if (
      child.tagName === 'TEMPLATE' &&
      child.getAttribute('shadowrootmode') === 'open'
    ) {
      return child;
    }
  }
  return null;
}

function ensureShadowRoot(host) {
  if (host.shadowRoot) {
    return host.shadowRoot;
  }

  const template = findDirectShadowTemplate(host);
  if (!template) {
    return null;
  }

  if (typeof host.attachShadow !== 'function') {
    host.appendChild(template.content);
    template.remove();
    return null;
  }

  const shadowRoot = host.attachShadow({ mode: 'open' });
  shadowRoot.appendChild(template.content);
  template.remove();
  return shadowRoot;
}

function ensureShadowBody(shadowRoot) {
  let shadowBody = shadowRoot.querySelector('.billboard-shadow-body');
  if (!shadowBody) {
    shadowBody = document.createElement('div');
    shadowBody.className = 'billboard-shadow-body';
    const movableNodes = [];
    shadowRoot.childNodes.forEach((node) => {
      if (
        !(
          node.nodeType === Node.ELEMENT_NODE &&
          node.tagName === 'STYLE' &&
          node.hasAttribute('data-billboard-base-styles')
        )
      ) {
        movableNodes.push(node);
      }
    });
    movableNodes.forEach((node) => shadowBody.appendChild(node));
    shadowRoot.appendChild(shadowBody);
  }
  return shadowBody;
}

function attachImageErrorFallbacks(shadowRoot) {
  shadowRoot.querySelectorAll('img').forEach((img) => {
    if (img.__foremBillboardImgFallbackBound) return;
    img.__foremBillboardImgFallbackBound = true;
    img.addEventListener('error', () => {
      img.style.display = 'none';
    });
  });
}

function getListenerCaptureFlag(options) {
  if (typeof options === 'boolean') return options;
  if (options && typeof options === 'object') return Boolean(options.capture);
  return false;
}

function createSandboxController(host, shadowRoot, shadowBody) {
  const realWindow = window;
  const realDocument = document;
  const billboardId = host.dataset.billboardId || null;

  const controller = {
    host,
    shadowRoot,
    shadowBody,
    billboardId,
    destroyed: false,
    localGlobals: Object.create(null),
    docExtras: Object.create(null),
    intervals: new Set(),
    timeouts: new Set(),
    rafs: new Set(),
    listeners: [],
    listenerRegistry: new WeakMap(),
    observers: new Set(),
    cleanupCallbacks: new Set(),
    abortController:
      typeof AbortController === 'function' ? new AbortController() : null,
    currentScript: null,
    windowProxy: null,
    scopedDocument: null,
    billboardApi: null,
  };

  function runSafely(context, fn, thisArg, args) {
    if (controller.destroyed) return undefined;
    try {
      return fn.apply(thisArg, args);
    } catch (error) {
      logBillboardError(billboardId, context, error);
      return undefined;
    }
  }

  function wrapCallback(context, fn) {
    return function wrappedBillboardCallback(...args) {
      return runSafely(context, fn, this, args);
    };
  }

  function scheduleMicrotaskSafely(context, fn, thisArg) {
    const invoke = () => {
      if (controller.destroyed) return;
      runSafely(context, fn, thisArg, []);
    };
    if (typeof queueMicrotask === 'function') {
      queueMicrotask(invoke);
    } else {
      Promise.resolve().then(invoke);
    }
  }

  function trackedSetInterval(callback, delay, ...args) {
    if (controller.destroyed) return 0;
    const wrapped =
      typeof callback === 'function'
        ? () => runSafely('interval error', callback, controller.windowProxy, args)
        : () => {
            if (typeof callback === 'string') {
              executeInlineScriptInSandbox(controller, callback, null);
            }
          };
    const id = realWindow.setInterval(wrapped, delay);
    controller.intervals.add(id);
    return id;
  }

  function trackedClearInterval(id) {
    controller.intervals.delete(id);
    realWindow.clearInterval(id);
  }

  function trackedSetTimeout(callback, delay, ...args) {
    if (controller.destroyed) return 0;
    let id;
    const wrapped = () => {
      controller.timeouts.delete(id);
      if (typeof callback === 'function') {
        runSafely('timeout error', callback, controller.windowProxy, args);
      } else if (typeof callback === 'string') {
        executeInlineScriptInSandbox(controller, callback, null);
      }
    };
    id = realWindow.setTimeout(wrapped, delay);
    controller.timeouts.add(id);
    return id;
  }

  function trackedClearTimeout(id) {
    controller.timeouts.delete(id);
    realWindow.clearTimeout(id);
  }

  function trackedRAF(callback) {
    if (controller.destroyed || typeof realWindow.requestAnimationFrame !== 'function') {
      return 0;
    }
    let id;
    id = realWindow.requestAnimationFrame((ts) => {
      controller.rafs.delete(id);
      if (typeof callback === 'function') {
        runSafely('animation frame error', callback, controller.windowProxy, [ts]);
      }
    });
    controller.rafs.add(id);
    return id;
  }

  function trackedCancelRAF(id) {
    controller.rafs.delete(id);
    if (typeof realWindow.cancelAnimationFrame === 'function') {
      realWindow.cancelAnimationFrame(id);
    }
  }

  function addTrackedListener(target, type, listener, options) {
    if (controller.destroyed || !listener) return;
    if (typeof listener !== 'function' && typeof listener.handleEvent !== 'function') {
      return;
    }

    const capture = getListenerCaptureFlag(options);
    const key = `${type}:${capture}`;
    let targetMap = controller.listenerRegistry.get(listener);
    if (!targetMap) {
      targetMap = new Map();
      controller.listenerRegistry.set(listener, targetMap);
    }

    const existingForTarget = targetMap.get(target) || new Map();
    if (existingForTarget.has(key)) {
      return;
    }

    const wrapped = function wrappedEventListener(event) {
      if (controller.destroyed) return;
      try {
        if (typeof listener === 'function') {
          listener.call(this, event);
        } else {
          listener.handleEvent(event);
        }
      } catch (error) {
        logBillboardError(billboardId, `event listener (${type}) error`, error);
      }
    };

    existingForTarget.set(key, wrapped);
    targetMap.set(target, existingForTarget);
    controller.listeners.push({ target, type, wrapped, options });
    target.addEventListener(type, wrapped, options);
  }

  function removeTrackedListener(target, type, listener, options) {
    if (!listener) return;
    const capture = getListenerCaptureFlag(options);
    const key = `${type}:${capture}`;
    const targetMap = controller.listenerRegistry.get(listener);
    const existingForTarget = targetMap?.get(target);
    const wrapped = existingForTarget?.get(key);
    if (!wrapped) return;

    target.removeEventListener(type, wrapped, options);
    existingForTarget.delete(key);
    controller.listeners = controller.listeners.filter(
      (entry) => !(entry.target === target && entry.type === type && entry.wrapped === wrapped),
    );
  }

  function createTrackedObserver(NativeObserver, label) {
    if (typeof NativeObserver !== 'function') {
      return undefined;
    }

    return class TrackedBillboardObserver extends NativeObserver {
      constructor(callback, ...rest) {
        super(wrapCallback(`${label} error`, callback), ...rest);
        controller.observers.add(this);
      }

      disconnect() {
        controller.observers.delete(this);
        super.disconnect();
      }
    };
  }

  const TrackedResizeObserver = createTrackedObserver(
    realWindow.ResizeObserver,
    'ResizeObserver',
  );
  const TrackedIntersectionObserver = createTrackedObserver(
    realWindow.IntersectionObserver,
    'IntersectionObserver',
  );
  const TrackedMutationObserver = createTrackedObserver(
    realWindow.MutationObserver,
    'MutationObserver',
  );

  // Scoped `document.head` proxy: writes (e.g. dynamically appended <style>)
  // stay inside the billboard's ShadowRoot, while read-only <meta> queries can
  // still inspect page metadata like csrf-token or user-signed-in.
  const scopedHead = {
    appendChild(node) {
      return shadowRoot.appendChild(node);
    },
    insertBefore(node, refNode) {
      return shadowRoot.insertBefore(node, refNode);
    },
    append(...nodes) {
      return shadowRoot.append(...nodes);
    },
    prepend(...nodes) {
      return shadowRoot.prepend(...nodes);
    },
    removeChild(node) {
      return shadowRoot.removeChild(node);
    },
    contains(node) {
      return shadowRoot.contains(node);
    },
    querySelector(selector) {
      const localMatch = shadowRoot.querySelector(selector);
      if (localMatch) return localMatch;
      if (typeof selector === 'string' && /^\s*meta\b/i.test(selector)) {
        return realDocument.head?.querySelector(selector) || null;
      }
      return null;
    },
    querySelectorAll(selector) {
      const localMatches = shadowRoot.querySelectorAll(selector);
      if (localMatches.length > 0) return localMatches;
      if (typeof selector === 'string' && /^\s*meta\b/i.test(selector)) {
        return realDocument.head?.querySelectorAll(selector) || localMatches;
      }
      return localMatches;
    },
  };

  function blockDocumentWrite(methodName) {
    return () => {
      // eslint-disable-next-line no-console
      console.warn(
        `[Billboard ${billboardId || 'raw'}] Blocked document.${methodName}() inside isolated billboard.`,
      );
    };
  }

  const documentMethods = {
    getElementById(id) {
      return shadowRoot.getElementById(id);
    },
    querySelector(selector) {
      const localMatch = shadowRoot.querySelector(selector);
      if (localMatch) return localMatch;
      if (typeof selector === 'string' && /^\s*meta\[/i.test(selector)) {
        return realDocument.querySelector(selector);
      }
      return null;
    },
    querySelectorAll(selector) {
      return shadowRoot.querySelectorAll(selector);
    },
    getElementsByClassName(classNames) {
      return shadowBody.getElementsByClassName(classNames);
    },
    getElementsByTagName(tagName) {
      return shadowBody.getElementsByTagName(tagName);
    },
    getElementsByTagNameNS(ns, tagName) {
      return shadowBody.getElementsByTagNameNS(ns, tagName);
    },
    getElementsByName(name) {
      const escaped =
        typeof CSS !== 'undefined' && typeof CSS.escape === 'function'
          ? CSS.escape(String(name))
          : String(name).replace(/["\\]/g, '\\$&');
      return shadowRoot.querySelectorAll(`[name="${escaped}"]`);
    },
    contains(node) {
      return shadowRoot.contains(node);
    },
    addEventListener(type, listener, options) {
      if (type === 'DOMContentLoaded') {
        if (typeof listener === 'function') {
          scheduleMicrotaskSafely('DOMContentLoaded listener error', listener, scopedDocument);
        }
        return;
      }
      if (type === 'visibilitychange' || type === 'readystatechange') {
        addTrackedListener(realDocument, type, listener, options);
        return;
      }
      addTrackedListener(shadowRoot, type, listener, options);
    },
    removeEventListener(type, listener, options) {
      if (type === 'visibilitychange' || type === 'readystatechange') {
        removeTrackedListener(realDocument, type, listener, options);
        return;
      }
      removeTrackedListener(shadowRoot, type, listener, options);
    },
    write: blockDocumentWrite('write'),
    writeln: blockDocumentWrite('writeln'),
    open: blockDocumentWrite('open'),
    close: blockDocumentWrite('close'),
  };

  const scopedDocument = new Proxy(realDocument, {
    get(target, prop) {
      if (prop === 'body' || prop === 'documentElement' || prop === 'scrollingElement') {
        return shadowBody;
      }
      if (prop === 'head') return scopedHead;
      if (prop === 'currentScript') return controller.currentScript;
      if (prop === 'activeElement') return shadowRoot.activeElement;
      if (prop === 'styleSheets') return shadowRoot.styleSheets;
      if (prop === 'adoptedStyleSheets') return shadowRoot.adoptedStyleSheets;
      if (Object.prototype.hasOwnProperty.call(documentMethods, prop)) {
        return documentMethods[prop];
      }
      if (prop in controller.docExtras) {
        return controller.docExtras[prop];
      }
      const value = Reflect.get(target, prop, target);
      return typeof value === 'function' ? value.bind(target) : value;
    },
    set(_target, prop, value) {
      if (prop === 'title') {
        return true;
      }
      controller.docExtras[prop] = value;
      return true;
    },
    has(target, prop) {
      return prop in controller.docExtras || prop in documentMethods || prop in target;
    },
  });

  const windowOverrides = {
    setInterval: trackedSetInterval,
    clearInterval: trackedClearInterval,
    setTimeout: trackedSetTimeout,
    clearTimeout: trackedClearTimeout,
    requestAnimationFrame: trackedRAF,
    cancelAnimationFrame: trackedCancelRAF,
    ResizeObserver: TrackedResizeObserver,
    IntersectionObserver: TrackedIntersectionObserver,
    MutationObserver: TrackedMutationObserver,
    addEventListener(type, listener, options) {
      if (type === 'load' && realDocument.readyState === 'complete') {
        if (typeof listener === 'function') {
          scheduleMicrotaskSafely('load listener error', listener, windowProxy);
        }
        return;
      }
      addTrackedListener(realWindow, type, listener, options);
    },
    removeEventListener(type, listener, options) {
      removeTrackedListener(realWindow, type, listener, options);
    },
  };

  const windowProxy = new Proxy(realWindow, {
    get(target, prop) {
      if (prop === 'window' || prop === 'self' || prop === 'globalThis') {
        return windowProxy;
      }
      if (prop === 'document') {
        return scopedDocument;
      }
      if (Object.prototype.hasOwnProperty.call(windowOverrides, prop)) {
        return windowOverrides[prop];
      }
      if (prop in controller.localGlobals) {
        return controller.localGlobals[prop];
      }

      const value = Reflect.get(target, prop, target);
      if (
        typeof value === 'function' &&
        !Object.prototype.hasOwnProperty.call(value, 'prototype')
      ) {
        return value.bind(target);
      }
      return value;
    },
    set(target, prop, value) {
      if (prop === 'location') {
        target.location = value;
        return true;
      }
      controller.localGlobals[prop] = value;
      return true;
    },
    has(target, prop) {
      return (
        prop in controller.localGlobals ||
        Object.prototype.hasOwnProperty.call(windowOverrides, prop) ||
        prop in target
      );
    },
    deleteProperty(_target, prop) {
      if (prop in controller.localGlobals) {
        delete controller.localGlobals[prop];
      }
      return true;
    },
  });

  controller.windowProxy = windowProxy;
  controller.scopedDocument = scopedDocument;
  controller.trackedApis = {
    trackedSetInterval,
    trackedClearInterval,
    trackedSetTimeout,
    trackedClearTimeout,
    trackedRAF,
    trackedCancelRAF,
    TrackedResizeObserver,
    TrackedIntersectionObserver,
    TrackedMutationObserver,
  };
  controller.billboardApi = Object.freeze({
    id: billboardId,
    host,
    root: shadowRoot,
    body: shadowBody,
    signal: controller.abortController?.signal || null,
    onCleanup(fn) {
      if (typeof fn === 'function') {
        controller.cleanupCallbacks.add(fn);
      }
    },
  });

  return controller;
}

function executeInlineScriptInSandbox(controller, code, scriptEl) {
  if (controller.destroyed || !code || !code.trim()) return;

  const {
    trackedSetInterval,
    trackedClearInterval,
    trackedSetTimeout,
    trackedClearTimeout,
    trackedRAF,
    trackedCancelRAF,
    TrackedResizeObserver,
    TrackedIntersectionObserver,
    TrackedMutationObserver,
  } = controller.trackedApis;

  const previousScript = controller.currentScript;
  controller.currentScript = scriptEl;

  try {
    // eslint-disable-next-line no-new-func
    const runner = new Function(
      'window',
      'self',
      'globalThis',
      'document',
      'setInterval',
      'clearInterval',
      'setTimeout',
      'clearTimeout',
      'requestAnimationFrame',
      'cancelAnimationFrame',
      'ResizeObserver',
      'IntersectionObserver',
      'MutationObserver',
      'billboard',
      `"use strict";\n${code}`,
    );

    runner.call(
      controller.windowProxy,
      controller.windowProxy,
      controller.windowProxy,
      controller.windowProxy,
      controller.scopedDocument,
      trackedSetInterval,
      trackedClearInterval,
      trackedSetTimeout,
      trackedClearTimeout,
      trackedRAF,
      trackedCancelRAF,
      TrackedResizeObserver,
      TrackedIntersectionObserver,
      TrackedMutationObserver,
      controller.billboardApi,
    );
  } catch (error) {
    logBillboardError(controller.billboardId, 'script execution error', error);
  } finally {
    controller.currentScript = previousScript;
  }
}

function executeExternalOrModuleScript(controller, originalScript) {
  const copy = document.createElement('script');
  for (let i = 0; i < originalScript.attributes.length; i += 1) {
    const { name, value } = originalScript.attributes[i];
    if (
      name === 'type' ||
      name === 'data-billboard-script' ||
      name === 'data-billboard-script-executed' ||
      name === 'data-billboard-script-src' ||
      name === 'data-original-type'
    ) {
      continue;
    }
    copy.setAttribute(name, value);
  }

  const originalType = originalScript.dataset.originalType;
  if (originalType) {
    copy.type = originalType;
  }

  const scriptSrc = originalScript.dataset.billboardScriptSrc;
  if (scriptSrc) {
    copy.src = scriptSrc;
  } else {
    copy.textContent = originalScript.textContent;
  }

  copy.dataset.billboardScriptRuntime = 'true';
  originalScript.parentNode?.insertBefore(copy, originalScript.nextSibling);
}

function executeShadowScripts(controller) {
  const scripts = Array.from(
    controller.shadowRoot.querySelectorAll(SHADOW_SCRIPT_SELECTOR),
  );

  scripts.forEach((script) => {
    if (script.dataset.billboardScriptExecuted === 'true') return;
    script.dataset.billboardScriptExecuted = 'true';

    const originalType = script.dataset.originalType || '';
    const hasExternalSrc = Boolean(script.dataset.billboardScriptSrc);

    if (hasExternalSrc || originalType.toLowerCase() === 'module') {
      executeExternalOrModuleScript(controller, script);
      return;
    }

    executeInlineScriptInSandbox(controller, script.textContent, script);
  });
}

export function cleanupBillboardShadowHost(host) {
  if (!host) return;
  const state = getSharedState();
  const controller = state.controllers.get(host);
  if (!controller || controller.destroyed) return;

  controller.destroyed = true;

  controller.intervals.forEach((id) => window.clearInterval(id));
  controller.intervals.clear();

  controller.timeouts.forEach((id) => window.clearTimeout(id));
  controller.timeouts.clear();

  controller.rafs.forEach((id) => {
    if (typeof window.cancelAnimationFrame === 'function') {
      window.cancelAnimationFrame(id);
    }
  });
  controller.rafs.clear();

  controller.listeners.forEach(({ target, type, wrapped, options }) => {
    try {
      target.removeEventListener(type, wrapped, options);
    } catch (_err) {
      // Ignore already-detached targets
    }
  });
  controller.listeners = [];

  controller.observers.forEach((observer) => {
    try {
      observer.disconnect();
    } catch (_err) {
      // Ignore observer cleanup errors
    }
  });
  controller.observers.clear();

  if (controller.abortController) {
    try {
      controller.abortController.abort();
    } catch (_err) {
      // Ignore abort errors
    }
  }

  controller.cleanupCallbacks.forEach((fn) => {
    try {
      fn();
    } catch (error) {
      logBillboardError(controller.billboardId, 'cleanup callback error', error);
    }
  });
  controller.cleanupCallbacks.clear();

  // Remove any dynamically inserted runtime module/external script copies so
  // InstantClick restore can cleanly re-run them.
  controller.shadowRoot
    ?.querySelectorAll('script[data-billboard-script-runtime="true"]')
    .forEach((el) => el.remove());

  state.activeHosts.delete(host);
}

export function cleanupBillboardShadowHostsIn(root) {
  if (!root || typeof root.querySelectorAll !== 'function') return;
  if (typeof root.matches === 'function' && root.matches(SHADOW_HOST_SELECTOR)) {
    cleanupBillboardShadowHost(root);
  }
  root.querySelectorAll(SHADOW_HOST_SELECTOR).forEach(cleanupBillboardShadowHost);
}

export function cleanupDisconnectedBillboardSandboxes() {
  const state = getSharedState();
  Array.from(state.activeHosts).forEach((host) => {
    if (!host.isConnected) {
      cleanupBillboardShadowHost(host);
    }
  });
}

export function cleanupAllBillboardSandboxes() {
  const state = getSharedState();
  Array.from(state.activeHosts).forEach(cleanupBillboardShadowHost);
}

export function mountBillboardShadowHost(host) {
  if (!host || !host.hasAttribute?.('data-billboard-shadow-host')) {
    return null;
  }

  ensureGlobalObservers();
  const state = getSharedState();
  const existing = state.controllers.get(host);

  if (existing && !existing.destroyed) {
    syncThemeForHost(host);
    return existing;
  }

  const shadowRoot = ensureShadowRoot(host);
  if (!shadowRoot) {
    return null;
  }

  const shadowBody = ensureShadowBody(shadowRoot);
  syncThemeForHost(host);
  attachImageErrorFallbacks(shadowRoot);

  // If this host was previously torn down (e.g. InstantClick history restore),
  // allow its billboard scripts to re-initialize cleanly.
  if (existing && existing.destroyed) {
    shadowRoot.querySelectorAll(SHADOW_SCRIPT_SELECTOR).forEach((script) => {
      delete script.dataset.billboardScriptExecuted;
    });
  }

  const controller = createSandboxController(host, shadowRoot, shadowBody);
  state.controllers.set(host, controller);
  state.activeHosts.add(host);

  executeShadowScripts(controller);
  return controller;
}

export function mountBillboardShadowHosts(root = document) {
  if (!root) return [];

  const hosts = [];
  if (typeof root.matches === 'function' && root.matches(SHADOW_HOST_SELECTOR)) {
    hosts.push(root);
  }
  if (typeof root.querySelectorAll === 'function') {
    root.querySelectorAll(SHADOW_HOST_SELECTOR).forEach((host) => {
      if (!hosts.includes(host)) {
        hosts.push(host);
      }
    });
  }

  return hosts.map(mountBillboardShadowHost).filter(Boolean);
}

/**
 * Finds the nearest ancestor matching `selector` along a DOM event's composed
 * path, so delegated listeners in the light DOM work seamlessly for clicks
 * originating inside an open billboard ShadowRoot.
 *
 * @param {Event} event
 * @param {string} selector
 * @returns {Element|null}
 */
export function findClosestInEventPath(event, selector) {
  if (!event || !selector) return null;

  if (typeof event.composedPath === 'function') {
    const path = event.composedPath();
    for (let i = 0; i < path.length; i += 1) {
      const node = path[i];
      if (
        node &&
        node.nodeType === 1 &&
        typeof node.matches === 'function' &&
        node.matches(selector)
      ) {
        return node;
      }
    }
  }

  const target = event.target;
  if (target && typeof target.closest === 'function') {
    return target.closest(selector);
  }
  return null;
}

/**
 * Queries matching elements in the light DOM and inside all open billboard
 * ShadowRoots under `root`.
 *
 * @param {string} selector
 * @param {ParentNode} root
 * @returns {Element[]}
 */
export function queryAllIncludingBillboardShadows(selector, root = document) {
  if (!root || typeof root.querySelectorAll !== 'function') {
    return [];
  }

  const results = Array.from(root.querySelectorAll(selector));
  root.querySelectorAll(SHADOW_HOST_SELECTOR).forEach((host) => {
    if (!host.shadowRoot) return;
    host.shadowRoot.querySelectorAll(selector).forEach((match) => {
      results.push(match);
    });
  });
  return results;
}

export function registerBillboardShadowGlobal() {
  if (typeof window === 'undefined') return;
  window.Forem = window.Forem || {};
  window.Forem.mountBillboardShadowHost = mountBillboardShadowHost;
  window.Forem.mountBillboardShadowHosts = mountBillboardShadowHosts;
}

registerBillboardShadowGlobal();
