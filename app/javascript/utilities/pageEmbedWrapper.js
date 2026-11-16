const SANDBOXED_EMBED_SELECTOR =
  '[data-sandboxed-embed="true"], .js-sandboxed-embed';
const MAX_CONCURRENT_EMBEDS = 8;
const HEARTBEAT_INTERVAL_MS = 2500;
const UNRESPONSIVE_TIMEOUT_MS = 6000;
const AUTO_SUSPEND_TIMEOUT_MS = 15000;
const MIN_EMBED_HEIGHT = 150;
const MAX_EMBED_HEIGHT = 2000;

const controllers = new Map();
let intersectionObserver = null;
let themeObserver = null;
let heartbeatTimer = null;
let globalListenersBound = false;
let instantClickCleanupBound = false;
let currentFullscreenEmbed = null;
let exitFullscreenCallback = null;

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
  if (currentFullscreenEmbed && currentFullscreenEmbed !== controller.embedEl) {
    return false;
  }
  return controller.inViewport;
}

function postStateToController(controller) {
  if (!controller?.port) return;
  const { theme, tokens } = readHostTheme();
  const active = computeIsActive(controller);
  const fullscreen = currentFullscreenEmbed === controller.embedEl;
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
      intersectionObserver &&
      typeof intersectionObserver.observe === 'function'
    ) {
      intersectionObserver.observe(controller.embedEl);
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
    message: 'Interactive widget deferred to keep page performance smooth.',
    tone: 'neutral',
    actions: [
      {
        label: 'Load widget',
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
    if (
      currentFullscreenEmbed === controller.embedEl &&
      typeof exitFullscreenCallback === 'function'
    ) {
      exitFullscreenCallback({ restoreScroll: true, restoreFocus: true });
    }
  } else if (data.type === 'guard') {
    controller.guardCount += 1;
    if (
      data.reason === 'dom-limit' ||
      data.reason === 'error-loop' ||
      data.reason === 'heavy-frame'
    ) {
      renderOverlay(controller, {
        message: 'Widget was throttled by performance protection.',
        tone: 'warning',
        actions: [
          {
            label: 'Reload widget',
            variant: 'secondary',
            onClick: () => reloadSandboxedEmbed(controller.embedEl),
          },
          {
            label: 'Dismiss',
            variant: 'ghost',
            onClick: () => clearOverlay(controller),
          },
        ],
      });
    }
  }
}

function applyAutoHeight(controller, rawHeight) {
  if (!controller.iframe || currentFullscreenEmbed === controller.embedEl) {
    return;
  }
  const clamped = Math.max(
    MIN_EMBED_HEIGHT,
    Math.min(MAX_EMBED_HEIGHT, Math.round(rawHeight)),
  );
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
        'This widget stopped responding and was paused to keep your browser smooth.',
        'Reload widget',
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
        message: 'This widget is taking too long to respond.',
        tone: 'warning',
        actions: [
          {
            label: 'Pause',
            variant: 'secondary',
            onClick: () =>
              suspendController(
                controller,
                'Widget paused.',
                'Resume widget',
              ),
          },
          {
            label: 'Reload',
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
  if (!globalListenersBound) {
    globalListenersBound = true;
    globalThis.addEventListener('message', onGlobalMessage);
    globalThis.addEventListener('beforeunload', destroyAllPageEmbedWrappers);
    document.addEventListener('visibilitychange', broadcastThemeAndState);
    document.addEventListener('click', onGlobalActionClick);
  }

  if (!heartbeatTimer) {
    heartbeatTimer = globalThis.setInterval(
      runHeartbeatTick,
      HEARTBEAT_INTERVAL_MS,
    );
  }

  if (!intersectionObserver && typeof globalThis.IntersectionObserver === 'function') {
    intersectionObserver = new globalThis.IntersectionObserver(
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
    !themeObserver &&
    typeof globalThis.MutationObserver === 'function' &&
    document.body
  ) {
    themeObserver = new globalThis.MutationObserver(() => {
      broadcastThemeAndState();
    });
    themeObserver.observe(document.body, {
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  if (
    !instantClickCleanupBound &&
    typeof globalThis.InstantClick !== 'undefined' &&
    typeof globalThis.InstantClick.on === 'function'
  ) {
    instantClickCleanupBound = true;
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
        'Navigation inside this embedded widget was blocked for your security.',
        'Reload widget',
      );
      return;
    }

    controller.hasLoadedOnce = true;
    controller.expectingReload = false;
    sendDiscoverPing(controller);
  });
}

export function registerFullscreenExitHandler(callback) {
  exitFullscreenCallback = typeof callback === 'function' ? callback : null;
}

export function notifyEmbedFullscreenChange(openEmbedEl) {
  currentFullscreenEmbed = openEmbedEl || null;
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
  if (!root || typeof root.querySelectorAll !== 'function') return [];

  const maxConcurrent =
    typeof options.maxConcurrent === 'number'
      ? options.maxConcurrent
      : MAX_CONCURRENT_EMBEDS;

  const embedEls = Array.from(root.querySelectorAll(SANDBOXED_EMBED_SELECTOR));
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
      if (intersectionObserver && typeof intersectionObserver.observe === 'function') {
        intersectionObserver.observe(embedEl);
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
  currentFullscreenEmbed = null;

  if (intersectionObserver) {
    if (typeof intersectionObserver.disconnect === 'function') {
      intersectionObserver.disconnect();
    }
    intersectionObserver = null;
  }

  if (themeObserver) {
    if (typeof themeObserver.disconnect === 'function') {
      themeObserver.disconnect();
    }
    themeObserver = null;
  }

  if (heartbeatTimer) {
    globalThis.clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }

  if (globalListenersBound) {
    globalListenersBound = false;
    globalThis.removeEventListener('message', onGlobalMessage);
    globalThis.removeEventListener('beforeunload', destroyAllPageEmbedWrappers);
    document.removeEventListener('visibilitychange', broadcastThemeAndState);
    document.removeEventListener('click', onGlobalActionClick);
  }
}

export function getSandboxedEmbedState(embedEl) {
  return controllers.get(embedEl) || null;
}
