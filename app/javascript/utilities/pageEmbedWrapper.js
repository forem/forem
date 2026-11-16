import { locale } from './locale';

const SANDBOXED_EMBED_SELECTOR =
  '[data-sandboxed-embed="true"], .js-sandboxed-embed';
const MAX_CONCURRENT_EMBEDS = 8;
const HEARTBEAT_INTERVAL_MS = 2500;
const UNRESPONSIVE_TIMEOUT_MS = 6000;
const AUTO_SUSPEND_TIMEOUT_MS = 15000;
const MIN_EMBED_HEIGHT = 150;
const MAX_EMBED_HEIGHT = 2000;
const AUTO_HEIGHT_SHRINK_TOLERANCE = 48;
const STATE_KEY = '__foremPageEmbedState';
const COORDINATOR_BRIDGE_KEY = '__foremPageEmbedCoordinatorBridge';

function getState() {
  if (!globalThis[STATE_KEY]) {
    globalThis[STATE_KEY] = {
      controllers: new Map(),
      intersectionObserver: null,
      themeObserver: null,
      heartbeatTimer: null,
      globalListenersBound: false,
      instantClickCleanupBound: false,
      pageShowBound: false,
      currentFullscreenEmbed: null,
      exitFullscreenCallback: null,
    };
  }
  return globalThis[STATE_KEY];
}

function getCoordinatorBridge() {
  if (!globalThis[COORDINATOR_BRIDGE_KEY]) {
    globalThis[COORDINATOR_BRIDGE_KEY] = {
      exitFullscreenCallback: null,
      currentFullscreenEmbed: null,
      notifyFullscreenChange: null,
    };
  }
  return globalThis[COORDINATOR_BRIDGE_KEY];
}

const state = getState();
const controllers = state.controllers;

function tEmbed(key, fallback) {
  const translated = locale(`core.embed_sandbox.${key}`);
  return translated.startsWith('[missing ') ? fallback : translated;
}

function getCurrentFullscreenEmbed() {
  const bridge = getCoordinatorBridge();
  return bridge.currentFullscreenEmbed ?? state.currentFullscreenEmbed;
}

function getExitFullscreenCallback() {
  const bridge = getCoordinatorBridge();
  return bridge.exitFullscreenCallback || state.exitFullscreenCallback;
}

function nowMs() {
  if (
    typeof globalThis.performance !== 'undefined' &&
    typeof globalThis.performance.now === 'function'
  ) {
    return globalThis.performance.now();
  }
  return Date.now();
}

function readHostTheme() {
  const isDark = document.body?.classList?.contains('dark-theme') || false;
  const theme = isDark ? 'dark' : 'light';
  const tokens = {
    '--forem-theme': theme,
    '--forem-bg': isDark ? '#090909' : '#ffffff',
    '--forem-fg': isDark ? '#f5f5f5' : '#171717',
    '--forem-card-bg': isDark ? '#171717' : '#ffffff',
    '--forem-border': isDark ? 'rgba(255, 255, 255, 0.15)' : 'rgba(23, 23, 23, 0.1)',
    '--forem-accent': '#3b49df',
  };

  if (typeof globalThis.getComputedStyle === 'function' && document.body) {
    try {
      const style = globalThis.getComputedStyle(document.body);
      const mapVars = {
        '--body-bg': '--forem-bg',
        '--body-color': '--forem-fg',
        '--card-bg': '--forem-card-bg',
        '--card-border': '--forem-border',
        '--accent-brand': '--forem-accent',
      };
      Object.keys(mapVars).forEach((srcVar) => {
        const val = style.getPropertyValue(srcVar)?.trim();
        if (val && /^[#a-zA-Z0-9(),.%\s_-]{1,80}$/.test(val)) {
          tokens[mapVars[srcVar]] = val;
        }
      });
    } catch (_err) {
      // Ignore computed style issues in JSDOM or detached documents
    }
  }

  return { theme, tokens };
}

function computeIsActive(controller) {
  if (!controller || controller.suspended || controller.pausedByUser) {
    return false;
  }
  if (document.hidden) {
    return false;
  }
  const fullscreenEmbed = getCurrentFullscreenEmbed();
  if (fullscreenEmbed && fullscreenEmbed !== controller.embedEl) {
    return false;
  }
  return controller.inViewport;
}

function postStateToController(controller) {
  if (!controller?.port) return;
  const { theme, tokens } = readHostTheme();
  const active = computeIsActive(controller);
  const fullscreen = getCurrentFullscreenEmbed() === controller.embedEl;
  controller.lastSentActive = active;

  try {
    controller.port.postMessage({
      type: 'state',
      active,
      fullscreen,
      muted: controller.pausedByUser,
      autoHeight: controller.autoHeight,
      theme,
      tokens,
    });
  } catch (_err) {
    // Ignore closed port
  }
}

function broadcastThemeAndState() {
  controllers.forEach((controller) => {
    postStateToController(controller);
  });
}

function closeControllerPort(controller) {
  if (!controller.port) return;
  try {
    controller.port.onmessage = null;
    controller.port.close?.();
  } catch (_err) {
    // Ignore
  }
  controller.port = null;
  controller.connected = false;
}

function clearOverlay(controller) {
  if (controller.overlayEl) {
    controller.overlayEl.remove();
    controller.overlayEl = null;
  }
  controller.embedEl.classList.remove('is-unresponsive', 'is-suspended');
}

function renderOverlay(controller, { message, tone = 'neutral', actions = [] }) {
  if (controller.overlayEl) {
    controller.overlayEl.remove();
    controller.overlayEl = null;
  }
  const container = controller.viewport;
  if (!container) return;

  const overlay = document.createElement('div');
  overlay.className = `ltag__page-overlay ltag__page-overlay--${tone}`;
  overlay.setAttribute('role', 'status');

  const text = document.createElement('p');
  text.className = 'ltag__page-overlay-message';
  text.textContent = message;
  overlay.appendChild(text);

  if (actions.length > 0) {
    const btnGroup = document.createElement('div');
    btnGroup.className = 'ltag__page-overlay-actions';
    actions.forEach(({ label, variant = 'secondary', onClick }) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = `crayons-btn crayons-btn--${variant} crayons-btn--s`;
      btn.textContent = label;
      btn.addEventListener('click', onClick);
      btnGroup.appendChild(btn);
    });
    overlay.appendChild(btnGroup);
  }

  container.appendChild(overlay);
  controller.overlayEl = overlay;
}

function suspendController(controller, reasonText, buttonLabel) {
  controller.suspended = true;
  controller.unresponsive = false;
  controller.pendingPingSince = null;
  closeControllerPort(controller);

  if (controller.iframe) {
    controller.expectingReload = true;
    if (controller.isSrcdocPreview || controller.iframe.hasAttribute('srcdoc')) {
      controller.iframe.removeAttribute('srcdoc');
    }
    controller.iframe.setAttribute('src', 'about:blank');
  }

  controller.embedEl.classList.add('is-suspended');
  renderOverlay(controller, {
    message: reasonText,
    tone: 'warning',
    actions: [
      {
        label: buttonLabel,
        variant: 'primary',
        onClick: () => reloadSandboxedEmbed(controller.embedEl),
      },
    ],
  });
}

export function reloadSandboxedEmbed(embedEl) {
  const controller = controllers.get(embedEl);
  if (!controller || !controller.iframe) return;

  clearOverlay(controller);
  closeControllerPort(controller);
  controller.suspended = false;
  controller.pausedByUser = false;
  controller.unresponsive = false;
  controller.hasLoadedOnce = false;
  controller.expectingReload = true;
  controller.pendingPingSince = null;
  controller.lastPongAt = nowMs();

  if (typeof controller.onReloadRequested === 'function') {
    controller.onReloadRequested(controller.iframe);
    return;
  }

  const targetSrc =
    controller.iframe.dataset.deferredSrc || controller.originalSrc;
  if (targetSrc && targetSrc !== 'about:blank') {
    delete controller.iframe.dataset.deferredSrc;
    if (
      state.intersectionObserver &&
      typeof state.intersectionObserver.observe === 'function'
    ) {
      state.intersectionObserver.observe(controller.embedEl);
    }
    controller.iframe.setAttribute('src', targetSrc);
  }
}

function deferControllerLoad(controller) {
  if (!controller.iframe) return;
  const src = controller.iframe.getAttribute('src');
  if (src && src !== 'about:blank') {
    controller.iframe.dataset.deferredSrc = src;
    controller.iframe.removeAttribute('src');
  }
  controller.suspended = true;
  controller.embedEl.classList.add('is-suspended');
  renderOverlay(controller, {
    message: tEmbed(
      'deferred_message',
      'Interactive widget deferred to keep page performance smooth.',
    ),
    tone: 'neutral',
    actions: [
      {
        label: tEmbed('load_widget', 'Load widget'),
        variant: 'secondary',
        onClick: () => reloadSandboxedEmbed(controller.embedEl),
      },
    ],
  });
}

function sendDiscoverPing(controller) {
  if (!controller?.iframe?.contentWindow) return;
  try {
    controller.iframe.contentWindow.postMessage(
      { __foremEmbedHost: 'discover' },
      '*',
    );
  } catch (_err) {
    // Ignore cross-origin/detached errors
  }
}

function handlePortMessage(controller, event) {
  const data = event?.data;
  if (!data || typeof data !== 'object') return;

  if (data.type === 'pong') {
    controller.lastPongAt = nowMs();
    controller.pendingPingSince = null;
    if (controller.unresponsive) {
      controller.unresponsive = false;
      clearOverlay(controller);
    }
  } else if (data.type === 'ready' || data.type === 'load') {
    controller.connected = true;
    controller.lastPongAt = nowMs();
    controller.pendingPingSince = null;
    if (controller.autoHeight && typeof data.height === 'number') {
      applyAutoHeight(controller, data.height);
    }
  } else if (data.type === 'resize') {
    if (controller.autoHeight && typeof data.height === 'number') {
      applyAutoHeight(controller, data.height);
    }
  } else if (data.type === 'exit-fullscreen') {
    const exitCb = getExitFullscreenCallback();
    if (
      getCurrentFullscreenEmbed() === controller.embedEl &&
      typeof exitCb === 'function'
    ) {
      exitCb({ restoreScroll: true, restoreFocus: true });
    }
  } else if (data.type === 'guard') {
    controller.guardCount += 1;
    if (
      data.reason === 'dom-limit' ||
      data.reason === 'error-loop' ||
      data.reason === 'heavy-frame'
    ) {
      renderOverlay(controller, {
        message: tEmbed(
          'throttled_message',
          'Widget was throttled by performance protection.',
        ),
        tone: 'warning',
        actions: [
          {
            label: tEmbed('reload_widget', 'Reload widget'),
            variant: 'secondary',
            onClick: () => reloadSandboxedEmbed(controller.embedEl),
          },
          {
            label: tEmbed('dismiss', 'Dismiss'),
            variant: 'ghost',
            onClick: () => clearOverlay(controller),
          },
        ],
      });
    }
  }
}

function applyAutoHeight(controller, rawHeight) {
  if (
    !controller.iframe ||
    getCurrentFullscreenEmbed() === controller.embedEl
  ) {
    return;
  }
  const clamped = Math.max(
    MIN_EMBED_HEIGHT,
    Math.min(MAX_EMBED_HEIGHT, Math.round(rawHeight)),
  );
  const currentHeight = parseInt(
    controller.iframe.style.height || controller.iframe.getAttribute('height'),
    10,
  );
  if (
    Number.isFinite(currentHeight) &&
    clamped <= currentHeight &&
    currentHeight - clamped <= AUTO_HEIGHT_SHRINK_TOLERANCE
  ) {
    return;
  }
  controller.iframe.style.height = `${clamped}px`;
  controller.iframe.setAttribute('height', `${clamped}px`);
}

function attachPort(controller, port) {
  closeControllerPort(controller);
  controller.port = port;
  controller.connected = true;
  controller.lastPongAt = nowMs();
  controller.pendingPingSince = null;
  port.onmessage = (evt) => handlePortMessage(controller, evt);
  if (typeof port.start === 'function') {
    port.start();
  }
  postStateToController(controller);
}

function onGlobalMessage(event) {
  const data = event?.data;
  if (!data || typeof data !== 'object' || data.__foremEmbed !== 'boot') {
    return;
  }
  const port = event.ports?.[0];
  if (!port) return;

  for (const controller of controllers.values()) {
    if (controller.iframe?.contentWindow === event.source) {
      attachPort(controller, port);
      return;
    }
  }
}

function runHeartbeatTick() {
  const now = nowMs();
  controllers.forEach((controller) => {
    if (!controller.connected || !controller.port) return;
    if (!computeIsActive(controller)) {
      controller.pendingPingSince = null;
      return;
    }

    if (
      controller.pendingPingSince !== null &&
      now - controller.pendingPingSince >= AUTO_SUSPEND_TIMEOUT_MS
    ) {
      suspendController(
        controller,
        tEmbed(
          'stopped_responding',
          'This widget stopped responding and was paused to keep your browser smooth.',
        ),
        tEmbed('reload_widget', 'Reload widget'),
      );
      return;
    }

    if (
      controller.pendingPingSince !== null &&
      now - controller.pendingPingSince >= UNRESPONSIVE_TIMEOUT_MS &&
      !controller.unresponsive
    ) {
      controller.unresponsive = true;
      controller.embedEl.classList.add('is-unresponsive');
      renderOverlay(controller, {
        message: tEmbed(
          'slow_responding',
          'This widget is taking too long to respond.',
        ),
        tone: 'warning',
        actions: [
          {
            label: tEmbed('pause', 'Pause'),
            variant: 'secondary',
            onClick: () =>
              suspendController(
                controller,
                tEmbed('paused', 'Widget paused.'),
                tEmbed('resume_widget', 'Resume widget'),
              ),
          },
          {
            label: tEmbed('reload', 'Reload'),
            variant: 'primary',
            onClick: () => reloadSandboxedEmbed(controller.embedEl),
          },
        ],
      });
    }

    controller.seq += 1;
    if (controller.pendingPingSince === null) {
      controller.pendingPingSince = now;
    }
    try {
      controller.port.postMessage({ type: 'ping', seq: controller.seq });
    } catch (_err) {
      // Ignore closed port
    }
  });
}

function ensureGlobalInfrastructure() {
  getCoordinatorBridge().notifyFullscreenChange = notifyEmbedFullscreenChange;

  if (!state.globalListenersBound) {
    state.globalListenersBound = true;
    globalThis.addEventListener('message', onGlobalMessage);
    globalThis.addEventListener('beforeunload', destroyAllPageEmbedWrappers);
    document.addEventListener('visibilitychange', broadcastThemeAndState);
    document.addEventListener('click', onGlobalActionClick);
  }

  if (!state.pageShowBound) {
    state.pageShowBound = true;
    globalThis.addEventListener('pageshow', (event) => {
      if (event.persisted) {
        initializeSandboxedEmbeds(document);
      }
    });
  }

  if (!state.heartbeatTimer) {
    state.heartbeatTimer = globalThis.setInterval(
      runHeartbeatTick,
      HEARTBEAT_INTERVAL_MS,
    );
  }

  if (
    !state.intersectionObserver &&
    typeof globalThis.IntersectionObserver === 'function'
  ) {
    state.intersectionObserver = new globalThis.IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          const controller = controllers.get(entry.target);
          if (!controller) return;
          const nextInViewport = Boolean(entry.isIntersecting);
          if (controller.inViewport !== nextInViewport) {
            controller.inViewport = nextInViewport;
            postStateToController(controller);
          }
        });
      },
      { rootMargin: '150px 0px', threshold: 0.01 },
    );
  }

  if (
    !state.themeObserver &&
    typeof globalThis.MutationObserver === 'function' &&
    document.body
  ) {
    state.themeObserver = new globalThis.MutationObserver(() => {
      broadcastThemeAndState();
    });
    state.themeObserver.observe(document.body, {
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  if (
    !state.instantClickCleanupBound &&
    typeof globalThis.InstantClick !== 'undefined' &&
    typeof globalThis.InstantClick.on === 'function'
  ) {
    state.instantClickCleanupBound = true;
    globalThis.InstantClick.on('change', () => {
      destroyAllPageEmbedWrappers();
      initializeSandboxedEmbeds(document);
    });
  }
}

function onGlobalActionClick(event) {
  const reloadBtn = event.target?.closest?.('.js-reload-page-action');
  if (!reloadBtn) return;

  const embedEl = reloadBtn.closest(SANDBOXED_EMBED_SELECTOR);
  if (!embedEl) return;

  event.preventDefault();
  reloadSandboxedEmbed(embedEl);
}

function bindIframeLoadListener(controller) {
  if (!controller.iframe || controller.loadBound) return;
  controller.loadBound = true;

  controller.iframe.addEventListener('load', () => {
    const currentSrc = controller.iframe.getAttribute('src');
    if (currentSrc === 'about:blank' && controller.suspended) {
      controller.expectingReload = false;
      return;
    }

    if (
      !controller.isSrcdocPreview &&
      controller.hasLoadedOnce &&
      !controller.expectingReload
    ) {
      suspendController(
        controller,
        tEmbed(
          'navigation_blocked',
          'Navigation inside this embedded widget was blocked for your security.',
        ),
        tEmbed('reload_widget', 'Reload widget'),
      );
      return;
    }

    controller.hasLoadedOnce = true;
    controller.expectingReload = false;
    sendDiscoverPing(controller);
  });
}

export function registerFullscreenExitHandler(callback) {
  const fn = typeof callback === 'function' ? callback : null;
  state.exitFullscreenCallback = fn;
  getCoordinatorBridge().exitFullscreenCallback = fn;
}

export function notifyEmbedFullscreenChange(openEmbedEl) {
  const target = openEmbedEl || null;
  state.currentFullscreenEmbed = target;
  getCoordinatorBridge().currentFullscreenEmbed = target;
  broadcastThemeAndState();
}

export function prepareEmbedPreviewReload(embedEl, onReloadRequested) {
  const controller = controllers.get(embedEl);
  if (!controller) return;
  controller.expectingReload = true;
  controller.suspended = false;
  controller.unresponsive = false;
  clearOverlay(controller);
  if (typeof onReloadRequested === 'function') {
    controller.onReloadRequested = onReloadRequested;
  }
}

export function initializeSandboxedEmbeds(root = document, options = {}) {
  if (!globalThis.__foremInitSandboxedEmbeds) {
    globalThis.__foremInitSandboxedEmbeds = initializeSandboxedEmbeds;
  }
  getCoordinatorBridge().notifyFullscreenChange = notifyEmbedFullscreenChange;

  if (
    !root ||
    (typeof root.querySelectorAll !== 'function' &&
      typeof root.matches !== 'function')
  ) {
    return [];
  }

  const maxConcurrent =
    typeof options.maxConcurrent === 'number'
      ? options.maxConcurrent
      : MAX_CONCURRENT_EMBEDS;

  const embedEls =
    typeof root.querySelectorAll === 'function'
      ? Array.from(root.querySelectorAll(SANDBOXED_EMBED_SELECTOR))
      : [];
  if (
    typeof root.matches === 'function' &&
    root.matches(SANDBOXED_EMBED_SELECTOR) &&
    !embedEls.includes(root)
  ) {
    embedEls.unshift(root);
  }
  if (embedEls.length === 0) return [];

  ensureGlobalInfrastructure();

  let activeCount = Array.from(controllers.values()).filter(
    (c) => !c.suspended,
  ).length;

  embedEls.forEach((embedEl) => {
    if (controllers.has(embedEl)) return;
    const iframe = embedEl.querySelector('iframe');
    if (!iframe) return;

    const controller = {
      embedEl,
      iframe,
      viewport: embedEl.querySelector('.ltag__page-viewport') || embedEl,
      originalSrc: iframe.getAttribute('src') || iframe.dataset.embedSrc || '',
      autoHeight:
        iframe.dataset.autoHeight === 'true' ||
        embedEl.dataset.autoHeight === 'true',
      isSrcdocPreview:
        iframe.hasAttribute('srcdoc') ||
        embedEl.dataset.embedPreview === 'true',
      port: null,
      connected: false,
      inViewport: true,
      pausedByUser: false,
      suspended: false,
      unresponsive: false,
      hasLoadedOnce: false,
      expectingReload: false,
      loadBound: false,
      lastPongAt: nowMs(),
      pendingPingSince: null,
      seq: 0,
      guardCount: 0,
      overlayEl: null,
      onReloadRequested: null,
      lastSentActive: true,
    };

    controllers.set(embedEl, controller);
    bindIframeLoadListener(controller);

    if (!controller.isSrcdocPreview && activeCount >= maxConcurrent) {
      deferControllerLoad(controller);
    } else {
      activeCount += 1;
      if (
        state.intersectionObserver &&
        typeof state.intersectionObserver.observe === 'function'
      ) {
        state.intersectionObserver.observe(embedEl);
      }
      sendDiscoverPing(controller);
    }
  });

  return Array.from(controllers.values());
}

export function destroyAllPageEmbedWrappers() {
  controllers.forEach((controller) => {
    closeControllerPort(controller);
    clearOverlay(controller);
  });
  controllers.clear();
  state.currentFullscreenEmbed = null;
  getCoordinatorBridge().currentFullscreenEmbed = null;

  if (state.intersectionObserver) {
    if (typeof state.intersectionObserver.disconnect === 'function') {
      state.intersectionObserver.disconnect();
    }
    state.intersectionObserver = null;
  }

  if (state.themeObserver) {
    if (typeof state.themeObserver.disconnect === 'function') {
      state.themeObserver.disconnect();
    }
    state.themeObserver = null;
  }

  if (state.heartbeatTimer) {
    globalThis.clearInterval(state.heartbeatTimer);
    state.heartbeatTimer = null;
  }

  if (state.globalListenersBound) {
    state.globalListenersBound = false;
    globalThis.removeEventListener('message', onGlobalMessage);
    globalThis.removeEventListener('beforeunload', destroyAllPageEmbedWrappers);
    document.removeEventListener('visibilitychange', broadcastThemeAndState);
    document.removeEventListener('click', onGlobalActionClick);
  }
}

export function getSandboxedEmbedState(embedEl) {
  return controllers.get(embedEl) || null;
}
