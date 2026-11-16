const guardedWindows = new WeakSet();

export function initEmbedInnerGuard(config = {}, win = globalThis, doc = document) {
  if (!win || !doc || guardedWindows.has(win)) {
    return null;
  }
  guardedWindows.add(win);

  const defaults = {
    maxActiveTimers: 128,
    maxPendingRaf: 64,
    minIntervalMs: 16,
    minTimeoutMs: 4,
    maxConcurrentFetches: 12,
    maxFetchesPerWindow: 60,
    fetchWindowMs: 10000,
    maxPopupsPerGesture: 1,
    popupCooldownMs: 1000,
    maxConsolePerSec: 40,
    maxLongTaskMs: 250,
    maxConsecutiveHeavyFrames: 5,
    maxConsecutiveErrors: 25,
    maxDomNodes: 25000,
    userActivationWindowMs: 5000,
  };

  const limits = Object.assign({}, defaults, config.limits || {});
  const allowLocalHttp = Boolean(config.allowLocalHttp);
  const blockedHosts = new Set(
    Array.isArray(config.blockedHosts)
      ? config.blockedHosts
          .map((h) => String(h || '').trim().toLowerCase().replace(/:\d+$/, ''))
          .filter(Boolean)
      : [],
  );

  // Capture native primitives before any author code runs.
  const ObjectDefineProperty = Object.defineProperty;
  const ObjectGetOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const ReflectApply = Reflect.apply;
  const URLCtor = win.URL || globalThis.URL;
  const RequestCtor = win.Request || globalThis.Request || null;
  const requestUrlGetter = RequestCtor
    ? ObjectGetOwnPropertyDescriptor(RequestCtor.prototype, 'url')?.get || null
    : null;
  const MessageChannelCtor =
    win.MessageChannel || globalThis.MessageChannel || null;
  const CustomEventCtor = win.CustomEvent || globalThis.CustomEvent || null;
  const DOMExceptionCtor = win.DOMException || globalThis.DOMException || Error;
  const MapCtor = Map;
  const SetCtor = Set;
  const WeakSetCtor = WeakSet;

  const eventPreventDefault = Event.prototype.preventDefault;
  const eventStopImmediatePropagation = Event.prototype.stopImmediatePropagation;
  const messageDataGetter = win.MessageEvent
    ? ObjectGetOwnPropertyDescriptor(win.MessageEvent.prototype, 'data')?.get
    : null;
  const messageSourceGetter = win.MessageEvent
    ? ObjectGetOwnPropertyDescriptor(win.MessageEvent.prototype, 'source')?.get
    : null;

  const parentWin = win.parent && win.parent !== win ? win.parent : null;
  const nativeParentPostMessage =
    parentWin && typeof parentWin.postMessage === 'function'
      ? parentWin.postMessage.bind(parentWin)
      : null;

  const nativeWinAddEventListener = win.addEventListener.bind(win);
  const nativeWinRemoveEventListener = win.removeEventListener.bind(win);
  const nativeDocAddEventListener = doc.addEventListener.bind(doc);
  const nativeDocRemoveEventListener = doc.removeEventListener.bind(doc);
  const registeredListeners = [];

  function trackWinListener(type, fn, opts) {
    nativeWinAddEventListener(type, fn, opts);
    registeredListeners.push({ remove: () => nativeWinRemoveEventListener(type, fn, opts) });
  }

  function trackDocListener(type, fn, opts) {
    nativeDocAddEventListener(type, fn, opts);
    registeredListeners.push({ remove: () => nativeDocRemoveEventListener(type, fn, opts) });
  }
  const nativePerfNow =
    win.performance && typeof win.performance.now === 'function'
      ? win.performance.now.bind(win.performance)
      : () => Date.now();

  const nativeSetTimeout = win.setTimeout.bind(win);
  const nativeClearTimeout = win.clearTimeout.bind(win);
  const nativeSetInterval = win.setInterval.bind(win);
  const nativeClearInterval = win.clearInterval.bind(win);
  const nativeRAF =
    typeof win.requestAnimationFrame === 'function'
      ? win.requestAnimationFrame.bind(win)
      : (cb) => nativeSetTimeout(() => cb(nativePerfNow()), 16);
  const nativeCAF =
    typeof win.cancelAnimationFrame === 'function'
      ? win.cancelAnimationFrame.bind(win)
      : nativeClearTimeout;

  const nativeFetch =
    typeof win.fetch === 'function' ? win.fetch.bind(win) : null;
  const nativeXHROpen = win.XMLHttpRequest
    ? win.XMLHttpRequest.prototype.open
    : null;
  const nativeXHRSend = win.XMLHttpRequest
    ? win.XMLHttpRequest.prototype.send
    : null;
  const nativeSendBeacon =
    win.navigator && typeof win.navigator.sendBeacon === 'function'
      ? win.navigator.sendBeacon.bind(win.navigator)
      : null;
  const NativeWebSocket = win.WebSocket || null;
  const NativeEventSource = win.EventSource || null;

  const nativeWindowOpen =
    typeof win.open === 'function' ? win.open.bind(win) : null;
  const nativeDocOpen = doc.open ? doc.open.bind(doc) : null;
  const nativeDocWrite = doc.write ? doc.write.bind(doc) : null;
  const nativeDocWriteln = doc.writeln ? doc.writeln.bind(doc) : null;
  const nativeHtmlFocus = win.HTMLElement
    ? win.HTMLElement.prototype.focus
    : null;
  const nativeSvgFocus = win.SVGElement
    ? win.SVGElement.prototype.focus
    : null;
  const nativeWinFocus =
    typeof win.focus === 'function' ? win.focus.bind(win) : null;
  const nativeReqFullscreen = win.Element
    ? win.Element.prototype.requestFullscreen
    : null;
  const nativeWebkitReqFullscreen = win.Element
    ? win.Element.prototype.webkitRequestFullscreen
    : null;
  const nativeClipboardWrite = win.navigator?.clipboard?.write
    ? win.navigator.clipboard.write.bind(win.navigator.clipboard)
    : null;
  const nativeClipboardWriteText = win.navigator?.clipboard?.writeText
    ? win.navigator.clipboard.writeText.bind(win.navigator.clipboard)
    : null;

  const NativeAudioContext =
    win.AudioContext || win.webkitAudioContext || null;
  const nativeMediaPlay = win.HTMLMediaElement
    ? win.HTMLMediaElement.prototype.play
    : null;
  const nativeMediaPause = win.HTMLMediaElement
    ? win.HTMLMediaElement.prototype.pause
    : null;

  const winProto = win.Window ? win.Window.prototype : null;
  const patchedDescriptors = [];

  function patchMethod(targets, propName, replacement) {
    targets.forEach((target) => {
      if (!target) return;
      const desc = ObjectGetOwnPropertyDescriptor(target, propName);
      if (desc && desc.configurable === false && desc.writable === false) {
        return;
      }
      try {
        patchedDescriptors.push({
          target,
          propName,
          hadOwn: Boolean(desc),
          descriptor: desc,
        });
        ObjectDefineProperty(target, propName, {
          value: replacement,
          configurable: true,
          writable: true,
          enumerable: desc ? desc.enumerable : true,
        });
      } catch (_err) {
        try {
          target[propName] = replacement;
        } catch (_err2) {
          // Ignore non-writable globals in constrained environments
        }
      }
    });
  }

  function patchAccessor(targets, propName, getFn, setFn) {
    targets.forEach((target) => {
      if (!target) return;
      const desc = ObjectGetOwnPropertyDescriptor(target, propName);
      if (desc && desc.configurable === false) {
        return;
      }
      try {
        patchedDescriptors.push({
          target,
          propName,
          hadOwn: Boolean(desc),
          descriptor: desc,
        });
        ObjectDefineProperty(target, propName, {
          get: getFn || desc?.get,
          set: setFn !== undefined ? setFn : desc?.set,
          configurable: true,
          enumerable: desc ? desc.enumerable : true,
        });
      } catch (_err) {
        // Ignore non-configurable host accessors
      }
    });
  }

  function createSecurityError(message) {
    try {
      return new DOMExceptionCtor(message, 'SecurityError');
    } catch (_err) {
      return new Error(message);
    }
  }

  // Runtime state kept strictly inside this closure
  let activePort = null;
  let isActive = true;
  let isFullscreen = false;
  let isMuted = false;
  let autoHeightEnabled = false;
  let currentTheme = 'light';
  let lastReportedHeight = 0;
  let domLimitTriggered = false;
  let totalErrorCount = 0;
  let totalGuardCount = 0;
  let lastUserActivationAt = -Infinity;
  let lastPopupAt = -Infinity;
  let popupsInCurrentGesture = 0;
  let activeFetchCount = 0;
  let fetchTimestamps = [];
  let consoleWindowStart = nativePerfNow();
  let consoleCallsInWindow = 0;
  let resizeObserver = null;
  let domGuardObserver = null;
  let pendingMeasureRaf = false;

  const guardNoticeLastAt = new MapCtor();
  const activeTimeouts = new MapCtor();
  const activeIntervals = new MapCtor();
  const pendingRafs = new MapCtor();
  let pausedRafQueue = [];
  let nextVirtualId = 1;

  const trackedAudioContexts = new SetCtor();
  const suspendedContextsByWrapper = new WeakSetCtor();
  const pausedMediaByWrapper = new WeakSetCtor();
  const xhrMeta = new WeakMap();

  function sendToHost(payload) {
    if (!activePort) return;
    try {
      activePort.postMessage(payload);
    } catch (_err) {
      // Ignore closed/disconnected port errors
    }
  }

  function reportGuard(reason, detail) {
    totalGuardCount += 1;
    const now = nativePerfNow();
    const lastAt = guardNoticeLastAt.get(reason) || -Infinity;
    if (now - lastAt < 1500) return;
    guardNoticeLastAt.set(reason, now);
    sendToHost({
      type: 'guard',
      reason,
      detail: detail || null,
    });
  }

  function hasRecentUserActivation() {
    if (win.navigator?.userActivation?.isActive) {
      return true;
    }
    return nativePerfNow() - lastUserActivationAt <= limits.userActivationWindowMs;
  }

  function markUserActivation() {
    const now = nativePerfNow();
    if (now - lastUserActivationAt > limits.popupCooldownMs) {
      popupsInCurrentGesture = 0;
    }
    lastUserActivationAt = now;
  }

  ['pointerdown', 'mousedown', 'keydown', 'touchstart', 'click'].forEach(
    (evtName) => {
      trackDocListener(evtName, markUserActivation, {
        capture: true,
        passive: true,
      });
    },
  );

  function checkDomNodeLimit() {
    if (domLimitTriggered) return false;
    const count = doc.getElementsByTagName('*').length;
    if (count > limits.maxDomNodes) {
      domLimitTriggered = true;
      reportGuard('dom-limit', { nodes: count });
      return false;
    }
    return true;
  }

  function measureContentHeight() {
    if (!doc.body) return 0;
    const rect = doc.body.getBoundingClientRect();
    const rectHeight = rect ? Math.ceil(rect.height) : 0;
    const scrollHeight = doc.body.scrollHeight || 0;
    let margins = 0;
    try {
      const style = win.getComputedStyle(doc.body);
      margins =
        (parseFloat(style.marginTop) || 0) +
        (parseFloat(style.marginBottom) || 0);
    } catch (_err) {
      margins = 0;
    }
    return Math.max(0, Math.ceil(Math.max(rectHeight, scrollHeight) + margins));
  }

  function sendHeightIfChanged(force = false) {
    const height = measureContentHeight();
    if (!height) return;
    if (!force && Math.abs(height - lastReportedHeight) < 2) return;
    lastReportedHeight = height;
    sendToHost({ type: 'resize', height });
  }

  function scheduleMeasure() {
    if (!autoHeightEnabled || pendingMeasureRaf || !isActive) return;
    pendingMeasureRaf = true;
    nativeRAF(() => {
      pendingMeasureRaf = false;
      sendHeightIfChanged(false);
    });
  }

  function setupResizeObserver() {
    if (resizeObserver || !autoHeightEnabled || !doc.body) return;
    if (typeof win.ResizeObserver !== 'function') return;
    try {
      resizeObserver = new win.ResizeObserver(() => {
        scheduleMeasure();
      });
      resizeObserver.observe(doc.body);
    } catch (_err) {
      resizeObserver = null;
    }
  }

  // Suspend / resume AudioContexts & <audio>/<video>
  function syncMediaAndAudioPlayback() {
    const shouldSilence = !isActive || isMuted;

    trackedAudioContexts.forEach((ctx) => {
      if (!ctx || ctx.state === 'closed') {
        trackedAudioContexts.delete(ctx);
        return;
      }
      if (shouldSilence) {
        if (ctx.state === 'running' && typeof ctx.suspend === 'function') {
          suspendedContextsByWrapper.add(ctx);
          ctx.suspend().catch(() => {});
        }
      } else if (
        suspendedContextsByWrapper.has(ctx) &&
        ctx.state === 'suspended' &&
        typeof ctx.resume === 'function'
      ) {
        suspendedContextsByWrapper.delete(ctx);
        ctx.resume().catch(() => {});
      }
    });

    if (typeof doc.querySelectorAll === 'function') {
      const mediaEls = doc.querySelectorAll('audio, video');
      mediaEls.forEach((el) => {
        if (shouldSilence) {
          if (!el.paused && nativeMediaPause) {
            pausedMediaByWrapper.add(el);
            ReflectApply(nativeMediaPause, el, []);
          }
        } else if (
          pausedMediaByWrapper.has(el) &&
          el.paused &&
          nativeMediaPlay
        ) {
          pausedMediaByWrapper.delete(el);
          const p = ReflectApply(nativeMediaPlay, el, []);
          if (p && typeof p.catch === 'function') {
            p.catch(() => {});
          }
        }
      });
    }
  }

  function flushPausedRafs() {
    if (!isActive || pausedRafQueue.length === 0) return;
    const batch = pausedRafQueue;
    pausedRafQueue = [];
    batch.forEach((entry) => {
      if (!pendingRafs.has(entry.id)) return;
      scheduleNativeRaf(entry);
    });
  }

  function resumePausedTimeouts() {
    if (!isActive) return;
    activeTimeouts.forEach((entry, vid) => {
      if (!entry.paused) return;
      entry.paused = false;
      const delay = Math.max(0, entry.pausedRemaining || 0);
      entry.dueAt = nativePerfNow() + delay;
      entry.nativeId = nativeSetTimeout(() => {
        activeTimeouts.delete(vid);
        executeGuardedTimer(entry.fn, entry.args, null);
      }, delay);
    });
  }

  function resumePausedIntervals() {
    if (!isActive) return;
    activeIntervals.forEach((entry) => {
      if (!entry.paused || entry.suspended) return;
      entry.paused = false;
      entry.nativeId = nativeSetInterval(() => {
        if (!isActive || entry.suspended) return;
        executeGuardedTimer(entry.fn, entry.args, entry);
      }, entry.delay);
    });
  }

  function applyActiveState(nextActive) {
    const normalized = Boolean(nextActive);
    if (normalized === isActive) return;
    isActive = normalized;

    if (doc.documentElement) {
      doc.documentElement.dataset.foremPaused = isActive ? 'false' : 'true';
    }

    if (!isActive) {
      pendingRafs.forEach((entry) => {
        if (entry.nativeId != null) {
          nativeCAF(entry.nativeId);
          entry.nativeId = null;
          pausedRafQueue.push(entry);
        }
      });

      const now = nativePerfNow();
      activeTimeouts.forEach((entry) => {
        if (entry.nativeId != null && !entry.paused) {
          nativeClearTimeout(entry.nativeId);
          entry.nativeId = null;
          entry.paused = true;
          entry.pausedRemaining = Math.max(0, entry.dueAt - now);
        }
      });

      activeIntervals.forEach((entry) => {
        if (entry.nativeId != null && !entry.paused) {
          nativeClearInterval(entry.nativeId);
          entry.nativeId = null;
          entry.paused = true;
        }
      });
    } else {
      flushPausedRafs();
      resumePausedTimeouts();
      resumePausedIntervals();
      scheduleMeasure();
    }

    syncMediaAndAudioPlayback();
  }

  const SAFE_THEME_TOKENS = new SetCtor([
    '--forem-theme',
    '--forem-bg',
    '--forem-fg',
    '--forem-card-bg',
    '--forem-border',
    '--forem-accent',
  ]);
  const SAFE_CSS_VALUE_REGEXP = /^[#a-zA-Z0-9(),.%\s_-]{1,80}$/;

  function applyHostState(state) {
    if (!state || typeof state !== 'object') return;

    if (typeof state.theme === 'string') {
      currentTheme = state.theme === 'dark' ? 'dark' : 'light';
      if (doc.documentElement) {
        doc.documentElement.dataset.foremTheme = currentTheme;
      }
    }

    if (state.tokens && typeof state.tokens === 'object' && doc.documentElement) {
      Object.keys(state.tokens).forEach((key) => {
        if (!SAFE_THEME_TOKENS.has(key)) return;
        const val = String(state.tokens[key] || '').trim();
        if (SAFE_CSS_VALUE_REGEXP.test(val)) {
          doc.documentElement.style.setProperty(key, val);
        }
      });
    }

    if (typeof state.fullscreen === 'boolean') {
      isFullscreen = state.fullscreen;
      if (doc.documentElement) {
        doc.documentElement.dataset.foremFullscreen = isFullscreen
          ? 'true'
          : 'false';
      }
    }

    if (typeof state.muted === 'boolean') {
      isMuted = state.muted;
      syncMediaAndAudioPlayback();
    }

    if (typeof state.autoHeight === 'boolean') {
      autoHeightEnabled = state.autoHeight;
      if (autoHeightEnabled) {
        setupResizeObserver();
        sendHeightIfChanged(true);
      }
    }

    if (typeof state.active === 'boolean') {
      applyActiveState(state.active);
    }

    if (CustomEventCtor) {
      try {
        win.dispatchEvent(
          new CustomEventCtor('forem:state', {
            detail: {
              visible: isActive,
              fullscreen: isFullscreen,
              muted: isMuted,
              theme: currentTheme,
            },
          }),
        );
      } catch (_err) {
        // Ignore event dispatch failure
      }
    }
  }

  function handlePortMessage(event) {
    const msg = event?.data;
    if (!msg || typeof msg !== 'object') return;

    if (msg.type === 'ping') {
      sendToHost({
        type: 'pong',
        seq: msg.seq,
        metrics: {
          timers: activeTimeouts.size + activeIntervals.size,
          rafs: pendingRafs.size,
          fetches: activeFetchCount,
          errors: totalErrorCount,
          guards: totalGuardCount,
          nodes: doc.getElementsByTagName('*').length,
        },
      });
    } else if (msg.type === 'state') {
      applyHostState(msg);
    } else if (msg.type === 'measure') {
      sendHeightIfChanged(true);
    }
  }

  function connectChannel() {
    if (!nativeParentPostMessage || !MessageChannelCtor) return;
    try {
      if (activePort) {
        try {
          activePort.close();
        } catch (_err) {
          // Ignore
        }
      }
      const channel = new MessageChannelCtor();
      activePort = channel.port1;
      activePort.onmessage = handlePortMessage;
      if (typeof activePort.start === 'function') {
        activePort.start();
      }
      nativeParentPostMessage(
        {
          __foremEmbed: 'boot',
          protocol: 1,
          title: doc.title || '',
        },
        '*',
        [channel.port2],
      );
      if (doc.readyState !== 'loading') {
        sendToHost({
          type: 'ready',
          height: measureContentHeight(),
        });
      }
    } catch (_err) {
      // Ignore if parent frame is detached or cross-context restricted
    }
  }

  function onWindowMessage(event) {
    const source = messageSourceGetter
      ? ReflectApply(messageSourceGetter, event, [])
      : event.source;
    const data = messageDataGetter
      ? ReflectApply(messageDataGetter, event, [])
      : event.data;

    if (
      parentWin &&
      source === parentWin &&
      data &&
      typeof data === 'object' &&
      data.__foremEmbedHost === 'discover'
    ) {
      ReflectApply(eventStopImmediatePropagation, event, []);
      connectChannel();
    }
  }

  trackWinListener('message', onWindowMessage, true);

  // Guarded timer & rAF wrappers
  function executeGuardedTimer(fn, args, loopMeta) {
    if (!checkDomNodeLimit()) {
      if (loopMeta && loopMeta.nativeId != null) {
        nativeClearInterval(loopMeta.nativeId);
        loopMeta.nativeId = null;
        loopMeta.suspended = true;
      }
      return;
    }

    const t0 = nativePerfNow();
    try {
      ReflectApply(fn, undefined, args);
      if (loopMeta) {
        loopMeta.errorStreak = 0;
      }
    } catch (err) {
      totalErrorCount += 1;
      if (loopMeta) {
        loopMeta.errorStreak += 1;
        if (loopMeta.errorStreak >= limits.maxConsecutiveErrors) {
          loopMeta.suspended = true;
          if (loopMeta.nativeId != null) {
            nativeClearInterval(loopMeta.nativeId);
            loopMeta.nativeId = null;
          }
          reportGuard('error-loop', { count: loopMeta.errorStreak });
        }
      }
      throw err;
    } finally {
      const dt = nativePerfNow() - t0;
      if (loopMeta && !loopMeta.suspended) {
        if (dt > limits.maxLongTaskMs) {
          loopMeta.heavyStreak += 1;
          if (loopMeta.heavyStreak >= limits.maxConsecutiveHeavyFrames) {
            loopMeta.delay = Math.max(loopMeta.delay || 16, 500);
            loopMeta.heavyStreak = 0;
            if (loopMeta.nativeId != null) {
              nativeClearInterval(loopMeta.nativeId);
              loopMeta.nativeId = nativeSetInterval(() => {
                if (!isActive || loopMeta.suspended) return;
                executeGuardedTimer(loopMeta.fn, loopMeta.args, loopMeta);
              }, loopMeta.delay);
            }
            reportGuard('heavy-frame', { durationMs: Math.round(dt) });
          }
        } else {
          loopMeta.heavyStreak = 0;
        }
      }
    }
  }

  function guardedSetTimeout(fn, delay, ...args) {
    if (typeof fn !== 'function') {
      reportGuard('eval-timer-blocked');
      return 0;
    }
    if (activeTimeouts.size + activeIntervals.size >= limits.maxActiveTimers) {
      reportGuard('timer-limit', { max: limits.maxActiveTimers });
      return 0;
    }

    const safeDelay = Math.max(Number(delay) || 0, limits.minTimeoutMs);
    const vid = nextVirtualId++;
    const entry = {
      fn,
      args,
      delay: safeDelay,
      dueAt: nativePerfNow() + safeDelay,
      paused: !isActive && doc.readyState !== 'loading',
      pausedRemaining: safeDelay,
      nativeId: null,
    };
    activeTimeouts.set(vid, entry);

    if (!entry.paused) {
      entry.nativeId = nativeSetTimeout(() => {
        activeTimeouts.delete(vid);
        executeGuardedTimer(fn, args, null);
      }, safeDelay);
    }

    return vid;
  }

  function guardedClearTimeout(id) {
    const entry = activeTimeouts.get(id);
    if (!entry) return;
    if (entry.nativeId != null) {
      nativeClearTimeout(entry.nativeId);
    }
    activeTimeouts.delete(id);
  }

  function guardedSetInterval(fn, delay, ...args) {
    if (typeof fn !== 'function') {
      reportGuard('eval-timer-blocked');
      return 0;
    }
    if (activeTimeouts.size + activeIntervals.size >= limits.maxActiveTimers) {
      reportGuard('timer-limit', { max: limits.maxActiveTimers });
      return 0;
    }

    const safeDelay = Math.max(Number(delay) || 0, limits.minIntervalMs);
    const vid = nextVirtualId++;
    const entry = {
      fn,
      args,
      delay: safeDelay,
      paused: !isActive,
      suspended: false,
      errorStreak: 0,
      heavyStreak: 0,
      nativeId: null,
    };
    activeIntervals.set(vid, entry);

    if (isActive) {
      entry.nativeId = nativeSetInterval(() => {
        if (!isActive || entry.suspended) return;
        executeGuardedTimer(fn, args, entry);
      }, safeDelay);
    }

    return vid;
  }

  function guardedClearInterval(id) {
    const entry = activeIntervals.get(id);
    if (!entry) return;
    if (entry.nativeId != null) {
      nativeClearInterval(entry.nativeId);
    }
    activeIntervals.delete(id);
  }

  let rafErrorStreak = 0;
  let rafHeavyStreak = 0;

  function scheduleNativeRaf(entry) {
    entry.nativeId = nativeRAF((ts) => {
      entry.nativeId = null;
      if (!pendingRafs.has(entry.id)) return;
      if (!isActive) {
        pausedRafQueue.push(entry);
        return;
      }

      pendingRafs.delete(entry.id);
      if (!checkDomNodeLimit()) return;

      const t0 = nativePerfNow();
      try {
        entry.callback(ts);
        rafErrorStreak = 0;
      } catch (err) {
        totalErrorCount += 1;
        rafErrorStreak += 1;
        if (rafErrorStreak >= limits.maxConsecutiveErrors) {
          pendingRafs.clear();
          pausedRafQueue = [];
          reportGuard('error-loop', { count: rafErrorStreak });
        }
        throw err;
      } finally {
        const dt = nativePerfNow() - t0;
        if (dt > limits.maxLongTaskMs) {
          rafHeavyStreak += 1;
          if (rafHeavyStreak >= limits.maxConsecutiveHeavyFrames) {
            reportGuard('heavy-frame', { durationMs: Math.round(dt) });
          }
        } else {
          rafHeavyStreak = 0;
        }
      }
    });
  }

  function guardedRequestAnimationFrame(callback) {
    if (typeof callback !== 'function') return 0;
    if (domLimitTriggered || rafErrorStreak >= limits.maxConsecutiveErrors) {
      return 0;
    }
    if (pendingRafs.size >= limits.maxPendingRaf) {
      reportGuard('raf-limit', { max: limits.maxPendingRaf });
      return 0;
    }

    const vid = nextVirtualId++;
    const entry = { id: vid, callback, nativeId: null };
    pendingRafs.set(vid, entry);

    if (isActive) {
      scheduleNativeRaf(entry);
    } else {
      pausedRafQueue.push(entry);
    }

    return vid;
  }

  function guardedCancelAnimationFrame(id) {
    const entry = pendingRafs.get(id);
    if (!entry) return;
    if (entry.nativeId != null) {
      nativeCAF(entry.nativeId);
    }
    pendingRafs.delete(id);
  }

  patchMethod([win, winProto], 'setTimeout', guardedSetTimeout);
  patchMethod([win, winProto], 'clearTimeout', guardedClearTimeout);
  patchMethod([win, winProto], 'setInterval', guardedSetInterval);
  patchMethod([win, winProto], 'clearInterval', guardedClearInterval);
  patchMethod([win, winProto], 'requestAnimationFrame', guardedRequestAnimationFrame);
  patchMethod([win, winProto], 'cancelAnimationFrame', guardedCancelAnimationFrame);

  // Network URL validator & rate limiter
  const PRIVATE_IP_PATTERNS = [
    /^127\./,
    /^0\./,
    /^10\./,
    /^169\.254\./,
    /^192\.168\./,
    /^172\.(1[6-9]|2\d|3[01])\./,
    /^100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\./,
    /^::1$/,
    /^::$/,
    /^fe[89ab][0-9a-f]:/,
    /^f[cd][0-9a-f]{2}:/,
  ];

  function decodeMappedIpv4(host) {
    const hexMatch = /^::ffff:([0-9a-f]{1,4}):([0-9a-f]{1,4})$/.exec(host);
    if (hexMatch) {
      const hi = parseInt(hexMatch[1], 16);
      const lo = parseInt(hexMatch[2], 16);
      return `${(hi >> 8) & 255}.${hi & 255}.${(lo >> 8) & 255}.${lo & 255}`;
    }
    const dottedMatch = /^::ffff:(\d{1,3}(?:\.\d{1,3}){3})$/.exec(host);
    return dottedMatch ? dottedMatch[1] : null;
  }

  function isPrivateOrBlockedHostname(hostname) {
    const host = String(hostname || '')
      .toLowerCase()
      .replace(/\.+$/, '')
      .replace(/^\[|\]$/g, '');
    if (!host) return true;
    if (blockedHosts.has(host)) return true;
    const mappedV4 = decodeMappedIpv4(host);
    if (mappedV4 && blockedHosts.has(mappedV4)) return true;
    if (
      !allowLocalHttp &&
      (host === 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal'))
    ) {
      return true;
    }
    if (PRIVATE_IP_PATTERNS.some((pattern) => pattern.test(host))) {
      return true;
    }
    return Boolean(
      mappedV4 && PRIVATE_IP_PATTERNS.some((pattern) => pattern.test(mappedV4)),
    );
  }

  function resolveBaseHref() {
    const href = win.location?.href;
    if (href && !/^about:/i.test(href)) {
      return href;
    }
    return 'https://invalid.forem.local/';
  }

  function validateOutboundUrl(rawUrl, kind) {
    let parsed;
    try {
      parsed = new URLCtor(String(rawUrl), resolveBaseHref());
    } catch (_err) {
      return { allowed: false, reason: 'invalid-url' };
    }

    const proto = parsed.protocol.toLowerCase();
    if (kind === 'fetch' || kind === 'xhr') {
      if (proto === 'blob:' || proto === 'data:') {
        return { allowed: true, url: parsed.href };
      }
    }

    const allowedProtocols =
      kind === 'websocket'
        ? allowLocalHttp
          ? ['wss:', 'ws:']
          : ['wss:']
        : allowLocalHttp
          ? ['https:', 'http:']
          : ['https:'];

    if (!allowedProtocols.includes(proto)) {
      return { allowed: false, reason: 'disallowed-scheme' };
    }

    if (isPrivateOrBlockedHostname(parsed.hostname)) {
      return { allowed: false, reason: 'blocked-host' };
    }

    return { allowed: true, url: parsed.href };
  }

  function consumeNetworkBudget() {
    if (activeFetchCount >= limits.maxConcurrentFetches) {
      return { allowed: false, reason: 'concurrency-limit' };
    }
    const now = nativePerfNow();
    fetchTimestamps = fetchTimestamps.filter(
      (ts) => now - ts <= limits.fetchWindowMs,
    );
    if (fetchTimestamps.length >= limits.maxFetchesPerWindow) {
      return { allowed: false, reason: 'rate-limit' };
    }
    fetchTimestamps.push(now);
    return { allowed: true };
  }

  // Defense-in-depth egress wrappers (alongside CSP connect-src/worker-src/frame-src).
  if (nativeFetch) {
    patchMethod([win, winProto], 'fetch', function guardedFetch(input, init) {
      const isNativeRequest = Boolean(
        RequestCtor && input instanceof RequestCtor,
      );
      const rawTarget = isNativeRequest
        ? requestUrlGetter
          ? ReflectApply(requestUrlGetter, input, [])
          : input.url
        : String(input);
      const check = validateOutboundUrl(rawTarget, 'fetch');
      if (!check.allowed) {
        reportGuard('network-blocked', { reason: check.reason });
        return Promise.reject(
          new TypeError(`Fetch blocked by embed sandbox (${check.reason})`),
        );
      }
      const budget = consumeNetworkBudget();
      if (!budget.allowed) {
        reportGuard('network-rate-limited', { reason: budget.reason });
        return Promise.reject(
          new TypeError(`Fetch rate-limited by embed sandbox (${budget.reason})`),
        );
      }

      const safeInput = isNativeRequest ? input : check.url;
      activeFetchCount += 1;
      return nativeFetch(safeInput, init).finally(() => {
        activeFetchCount = Math.max(0, activeFetchCount - 1);
      });
    });
  }

  if (nativeXHROpen && nativeXHRSend && win.XMLHttpRequest) {
    patchMethod(
      [win.XMLHttpRequest.prototype],
      'open',
      function guardedXHROpen(method, url, async = true, ...rest) {
        if (async === false) {
          reportGuard('sync-xhr-blocked');
          throw createSecurityError(
            'Synchronous XMLHttpRequest is disabled in Forem embeds',
          );
        }
        const check = validateOutboundUrl(String(url), 'xhr');
        xhrMeta.set(this, check);
        if (!check.allowed) {
          reportGuard('network-blocked', { reason: check.reason });
          throw createSecurityError(
            `XMLHttpRequest blocked by embed sandbox (${check.reason})`,
          );
        }
        return ReflectApply(nativeXHROpen, this, [
          method,
          check.url,
          true,
          ...rest,
        ]);
      },
    );

    patchMethod(
      [win.XMLHttpRequest.prototype],
      'send',
      function guardedXHRSend(body) {
        const meta = xhrMeta.get(this);
        if (meta && !meta.allowed) {
          throw createSecurityError('XMLHttpRequest blocked by embed sandbox');
        }
        const budget = consumeNetworkBudget();
        if (!budget.allowed) {
          reportGuard('network-rate-limited', { reason: budget.reason });
          throw createSecurityError('XMLHttpRequest rate-limited by embed sandbox');
        }
        activeFetchCount += 1;
        let settled = false;
        const finish = () => {
          if (settled) return;
          settled = true;
          activeFetchCount = Math.max(0, activeFetchCount - 1);
        };
        this.addEventListener('loadend', finish, { once: true });
        try {
          return ReflectApply(nativeXHRSend, this, [body]);
        } catch (err) {
          finish();
          throw err;
        }
      },
    );
  }

  if (nativeSendBeacon && win.Navigator) {
    patchMethod(
      [win.navigator, win.Navigator.prototype],
      'sendBeacon',
      function guardedSendBeacon(url, data) {
        const check = validateOutboundUrl(String(url), 'beacon');
        if (!check.allowed) {
          reportGuard('network-blocked', { reason: check.reason });
          return false;
        }
        const budget = consumeNetworkBudget();
        if (!budget.allowed) {
          reportGuard('network-rate-limited', { reason: budget.reason });
          return false;
        }
        return nativeSendBeacon(check.url, data);
      },
    );
  }

  if (NativeWebSocket) {
    const GuardedWebSocket = function WebSocket(url, protocols) {
      const check = validateOutboundUrl(String(url), 'websocket');
      if (!check.allowed) {
        reportGuard('network-blocked', { reason: check.reason });
        throw createSecurityError(
          `WebSocket blocked by embed sandbox (${check.reason})`,
        );
      }
      const budget = consumeNetworkBudget();
      if (!budget.allowed) {
        reportGuard('network-rate-limited', { reason: budget.reason });
        throw createSecurityError('WebSocket rate-limited by embed sandbox');
      }
      return protocols !== undefined
        ? new NativeWebSocket(check.url, protocols)
        : new NativeWebSocket(check.url);
    };
    GuardedWebSocket.prototype = NativeWebSocket.prototype;
    ['CONNECTING', 'OPEN', 'CLOSING', 'CLOSED'].forEach((k) => {
      GuardedWebSocket[k] = NativeWebSocket[k];
    });
    patchMethod([win, winProto], 'WebSocket', GuardedWebSocket);
  }

  if (NativeEventSource) {
    const GuardedEventSource = function EventSource(url, eventSourceInitDict) {
      const check = validateOutboundUrl(String(url), 'eventsource');
      if (!check.allowed) {
        reportGuard('network-blocked', { reason: check.reason });
        throw createSecurityError(
          `EventSource blocked by embed sandbox (${check.reason})`,
        );
      }
      const budget = consumeNetworkBudget();
      if (!budget.allowed) {
        reportGuard('network-rate-limited', { reason: budget.reason });
        throw createSecurityError('EventSource rate-limited by embed sandbox');
      }
      return new NativeEventSource(check.url, eventSourceInitDict);
    };
    GuardedEventSource.prototype = NativeEventSource.prototype;
    ['CONNECTING', 'OPEN', 'CLOSED'].forEach((k) => {
      GuardedEventSource[k] = NativeEventSource[k];
    });
    patchMethod([win, winProto], 'EventSource', GuardedEventSource);
  }

  // Block WebRTC IP leakage & Web Workers
  [
    'RTCPeerConnection',
    'webkitRTCPeerConnection',
    'mozRTCPeerConnection',
    'RTCSessionDescription',
    'RTCIceCandidate',
  ].forEach((apiName) => {
    if (apiName in win) {
      patchMethod([win, winProto], apiName, function disabledWebRTC() {
        reportGuard('webrtc-blocked');
        throw createSecurityError(
          `${apiName} is disabled in sandboxed Forem embeds`,
        );
      });
    }
  });

  ['Worker', 'SharedWorker'].forEach((workerName) => {
    if (workerName in win) {
      patchMethod([win, winProto], workerName, function disabledWorker() {
        reportGuard('worker-blocked');
        throw createSecurityError(
          `${workerName} is disabled in sandboxed Forem embeds`,
        );
      });
    }
  });

  // Protect document against post-load document.open / document.write wipe
  if (nativeDocOpen) {
    patchMethod([doc, win.Document?.prototype], 'open', function blockedDocOpen() {
      reportGuard('document-open-blocked');
      return doc;
    });
  }

  if (nativeDocWrite) {
    patchMethod(
      [doc, win.Document?.prototype],
      'write',
      function guardedDocWrite(...args) {
        if (doc.readyState !== 'loading') {
          reportGuard('document-write-blocked');
          return;
        }
        ReflectApply(nativeDocWrite, doc, args);
      },
    );
  }

  if (nativeDocWriteln) {
    patchMethod(
      [doc, win.Document?.prototype],
      'writeln',
      function guardedDocWriteln(...args) {
        if (doc.readyState !== 'loading') {
          reportGuard('document-write-blocked');
          return;
        }
        ReflectApply(nativeDocWriteln, doc, args);
      },
    );
  }

  // Prevent focus hijacking / page jump-scroll unless user interacted inside iframe
  if (nativeHtmlFocus && win.HTMLElement) {
    patchMethod(
      [win.HTMLElement.prototype],
      'focus',
      function guardedFocus(options) {
        if (!hasRecentUserActivation()) {
          reportGuard('focus-blocked');
          return;
        }
        return ReflectApply(nativeHtmlFocus, this, options !== undefined ? [options] : []);
      },
    );
  }

  if (nativeSvgFocus && win.SVGElement) {
    patchMethod(
      [win.SVGElement.prototype],
      'focus',
      function guardedSvgFocus(options) {
        if (!hasRecentUserActivation()) {
          reportGuard('focus-blocked');
          return;
        }
        return ReflectApply(nativeSvgFocus, this, options !== undefined ? [options] : []);
      },
    );
  }

  if (nativeWinFocus) {
    patchMethod([win, winProto], 'focus', function guardedWinFocus() {
      if (!hasRecentUserActivation()) {
        reportGuard('focus-blocked');
      }
    });
  }

  // Prevent unexpected print dialogs or native fullscreen spoofing
  patchMethod([win, winProto], 'print', function blockedPrint() {
    reportGuard('print-blocked');
  });

  if (win.Element) {
    const blockedFullscreen = function blockedFullscreen() {
      reportGuard('fullscreen-blocked');
      return Promise.reject(
        createSecurityError(
          'Use the Forem embed card fullscreen button instead of Element.requestFullscreen',
        ),
      );
    };
    if (nativeReqFullscreen) {
      patchMethod([win.Element.prototype], 'requestFullscreen', blockedFullscreen);
    }
    if (nativeWebkitReqFullscreen) {
      patchMethod(
        [win.Element.prototype],
        'webkitRequestFullscreen',
        blockedFullscreen,
      );
    }
  }

  // Gate clipboard writes behind active user gesture
  if (win.navigator?.clipboard) {
    if (nativeClipboardWriteText) {
      patchMethod(
        [win.navigator.clipboard],
        'writeText',
        function guardedWriteText(text) {
          if (!hasRecentUserActivation()) {
            reportGuard('clipboard-blocked');
            return Promise.reject(
              createSecurityError('Clipboard write requires user interaction'),
            );
          }
          return nativeClipboardWriteText(text);
        },
      );
    }
    if (nativeClipboardWrite) {
      patchMethod(
        [win.navigator.clipboard],
        'write',
        function guardedWrite(data) {
          if (!hasRecentUserActivation()) {
            reportGuard('clipboard-blocked');
            return Promise.reject(
              createSecurityError('Clipboard write requires user interaction'),
            );
          }
          return nativeClipboardWrite(data);
        },
      );
    }
  }

  // Safe, rate-limited window.open
  if (nativeWindowOpen) {
    patchMethod(
      [win, winProto],
      'open',
      function guardedOpen(url, _target, _features) {
        if (!hasRecentUserActivation()) {
          reportGuard('popup-blocked', { reason: 'no-user-activation' });
          return null;
        }

        const now = nativePerfNow();
        if (
          now - lastPopupAt < limits.popupCooldownMs &&
          popupsInCurrentGesture >= limits.maxPopupsPerGesture
        ) {
          reportGuard('popup-rate-limited');
          return null;
        }

        let parsed;
        try {
          parsed = new URLCtor(String(url || ''), resolveBaseHref());
        } catch (_err) {
          reportGuard('popup-blocked', { reason: 'invalid-url' });
          return null;
        }

        const proto = parsed.protocol.toLowerCase();
        if (proto !== 'https:' && proto !== 'http:') {
          reportGuard('popup-blocked', { reason: 'disallowed-scheme' });
          return null;
        }

        lastPopupAt = now;
        popupsInCurrentGesture += 1;
        nativeWindowOpen(parsed.href, '_blank', 'noopener,noreferrer');
        return null;
      },
    );
  }

  // Safe AudioContext & Media tracking for pause/mute coordination
  if (NativeAudioContext) {
    const GuardedAudioContext = function AudioContext(options) {
      const ctx = new NativeAudioContext(options);
      trackedAudioContexts.add(ctx);
      if ((!isActive || isMuted) && typeof ctx.suspend === 'function') {
        suspendedContextsByWrapper.add(ctx);
        ctx.suspend().catch(() => {});
      }
      return ctx;
    };
    GuardedAudioContext.prototype = NativeAudioContext.prototype;
    if (win.AudioContext) {
      patchMethod([win, winProto], 'AudioContext', GuardedAudioContext);
    }
    if (win.webkitAudioContext) {
      patchMethod([win, winProto], 'webkitAudioContext', GuardedAudioContext);
    }
  }

  if (nativeMediaPlay && win.HTMLMediaElement) {
    patchMethod(
      [win.HTMLMediaElement.prototype],
      'play',
      function guardedMediaPlay() {
        if (!isActive || isMuted) {
          pausedMediaByWrapper.add(this);
          return Promise.resolve();
        }
        return ReflectApply(nativeMediaPlay, this, []);
      },
    );
  }

  // Rate-limit console flooding so tight loops cannot wedge DevTools IPC
  if (win.console) {
    ['log', 'info', 'debug', 'warn', 'error'].forEach((method) => {
      const orig = win.console[method];
      if (typeof orig !== 'function') return;
      const boundOrig = orig.bind(win.console);
      patchMethod([win.console], method, function guardedConsole(...args) {
        const now = nativePerfNow();
        if (now - consoleWindowStart >= 1000) {
          consoleWindowStart = now;
          consoleCallsInWindow = 0;
        }
        consoleCallsInWindow += 1;
        if (consoleCallsInWindow > limits.maxConsolePerSec) {
          return;
        }
        boundOrig(...args);
      });
    });
  }

  // Safe link & form handling inside the document
  trackDocListener(
    'click',
    (event) => {
      const link = event.target?.closest?.('a[href], area[href]');
      if (!link) return;
      const rawHref = (link.getAttribute('href') || '').trim();
      if (!rawHref || rawHref.startsWith('#')) return;

      const normalized = rawHref.replace(/[\x00-\x20]+/g, '').toLowerCase();
      if (
        normalized.startsWith('javascript:') ||
        normalized.startsWith('vbscript:') ||
        normalized.startsWith('data:') ||
        normalized.startsWith('file:')
      ) {
        ReflectApply(eventPreventDefault, event, []);
        reportGuard('unsafe-link-blocked');
        return;
      }

      link.setAttribute('target', '_blank');
      const existingRel = (link.getAttribute('rel') || '')
        .split(/\s+/)
        .filter(Boolean);
      const mergedRel = Array.from(
        new Set([...existingRel, 'noopener', 'noreferrer']),
      ).join(' ');
      link.setAttribute('rel', mergedRel);
    },
    true,
  );

  trackWinListener(
    'submit',
    (event) => {
      const form = event.target;
      if (!form || form.method?.toLowerCase() === 'dialog') return;
      if (!event.defaultPrevented) {
        ReflectApply(eventPreventDefault, event, []);
        reportGuard('form-navigation-blocked');
      }
    },
    false,
  );

  // Forward Escape key during host fullscreen so users aren't trapped inside the iframe
  trackDocListener(
    'keydown',
    (event) => {
      if (event.key === 'Escape' && isFullscreen && !event.defaultPrevented) {
        sendToHost({ type: 'exit-fullscreen' });
      }
    },
    false,
  );

  // Runtime DOM mutation sanitizer: strip dynamically injected dangerous tags/autofocus
  const BLOCKED_DYNAMIC_TAGS = new SetCtor([
    'BASE',
    'IFRAME',
    'FRAME',
    'FRAMESET',
    'PORTAL',
    'OBJECT',
    'EMBED',
    'APPLET',
  ]);
  const BLOCKED_META_HTTP_EQUIV = new SetCtor([
    'refresh',
    'set-cookie',
    'content-security-policy',
    'x-frame-options',
    'location',
    'window-target',
  ]);

  function isBlockedMetaNode(node) {
    const equiv = (node.getAttribute('http-equiv') || '').trim().toLowerCase();
    const name = (node.getAttribute('name') || '').trim().toLowerCase();
    return (
      !node.hasAttribute('data-forem-wrapper-meta') &&
      ((equiv && BLOCKED_META_HTTP_EQUIV.has(equiv)) || name === 'referrer')
    );
  }

  function sanitizeInjectedNode(node) {
    if (!node || (node.nodeType !== 1 && node.nodeType !== 11)) return;
    if (node.nodeType === 1) {
      const tag = node.tagName ? node.tagName.toUpperCase() : '';
      if (BLOCKED_DYNAMIC_TAGS.has(tag)) {
        node.remove();
        reportGuard('dynamic-element-blocked', { tag: tag.toLowerCase() });
        return;
      }
      if (tag === 'META' && isBlockedMetaNode(node)) {
        const equiv = (node.getAttribute('http-equiv') || '').trim().toLowerCase();
        const name = (node.getAttribute('name') || '').trim().toLowerCase();
        node.remove();
        reportGuard('dynamic-meta-blocked', { equiv: equiv || name });
        return;
      }
      if (node.hasAttribute && node.hasAttribute('autofocus')) {
        node.removeAttribute('autofocus');
      }
    }
    if (typeof node.querySelectorAll === 'function') {
      node
        .querySelectorAll(
          'base, iframe, frame, frameset, portal, object, embed, applet, meta[http-equiv], meta[name="referrer"], [autofocus]',
        )
        .forEach((descendant) => {
          sanitizeInjectedNode(descendant);
        });
    }
  }

  function scrubNodeBeforeInsertion(node) {
    if (!node || (node.nodeType !== 1 && node.nodeType !== 11)) return true;
    if (node.nodeType === 1) {
      const tag = node.tagName ? node.tagName.toUpperCase() : '';
      if (BLOCKED_DYNAMIC_TAGS.has(tag)) {
        reportGuard('dynamic-element-blocked', { tag: tag.toLowerCase() });
        return false;
      }
      if (tag === 'META' && isBlockedMetaNode(node)) {
        const equiv = (node.getAttribute('http-equiv') || '').trim().toLowerCase();
        const name = (node.getAttribute('name') || '').trim().toLowerCase();
        reportGuard('dynamic-meta-blocked', { equiv: equiv || name });
        return false;
      }
      if (node.hasAttribute && node.hasAttribute('autofocus')) {
        node.removeAttribute('autofocus');
      }
    }
    if (typeof node.querySelectorAll === 'function') {
      node
        .querySelectorAll(
          'base, iframe, frame, frameset, portal, object, embed, applet, meta[http-equiv], meta[name="referrer"], [autofocus]',
        )
        .forEach((descendant) => {
          sanitizeInjectedNode(descendant);
        });
    }
    return true;
  }

  // Block child-realm escapes synchronously before DOM insertion or contentWindow access.
  if (win.HTMLIFrameElement?.prototype) {
    patchAccessor(
      [win.HTMLIFrameElement.prototype],
      'contentWindow',
      () => null,
      undefined,
    );
    patchAccessor(
      [win.HTMLIFrameElement.prototype],
      'contentDocument',
      () => null,
      undefined,
    );
    patchMethod([win.HTMLIFrameElement.prototype], 'getSVGDocument', () => null);
  }

  if (win.Node?.prototype) {
    const nativeAppendChild = win.Node.prototype.appendChild;
    const nativeInsertBefore = win.Node.prototype.insertBefore;
    const nativeReplaceChild = win.Node.prototype.replaceChild;

    if (typeof nativeAppendChild === 'function') {
      patchMethod([win.Node.prototype], 'appendChild', function guardedAppendChild(child) {
        if (!scrubNodeBeforeInsertion(child)) return child;
        return ReflectApply(nativeAppendChild, this, [child]);
      });
    }
    if (typeof nativeInsertBefore === 'function') {
      patchMethod([win.Node.prototype], 'insertBefore', function guardedInsertBefore(newNode, refNode) {
        if (!scrubNodeBeforeInsertion(newNode)) return newNode;
        return ReflectApply(nativeInsertBefore, this, [newNode, refNode]);
      });
    }
    if (typeof nativeReplaceChild === 'function') {
      patchMethod([win.Node.prototype], 'replaceChild', function guardedReplaceChild(newChild, oldChild) {
        if (!scrubNodeBeforeInsertion(newChild)) return oldChild;
        return ReflectApply(nativeReplaceChild, this, [newChild, oldChild]);
      });
    }
  }

  if (win.Element?.prototype) {
    ['append', 'prepend', 'before', 'after', 'replaceWith'].forEach((methodName) => {
      const nativeDomMethod = win.Element.prototype[methodName];
      if (typeof nativeDomMethod !== 'function') return;
      patchMethod([win.Element.prototype], methodName, function guardedDomInsert(...nodes) {
        const safeNodes = nodes.filter((item) => scrubNodeBeforeInsertion(item));
        return ReflectApply(nativeDomMethod, this, safeNodes);
      });
    });

    const nativeInsertAdjacentElement =
      win.Element.prototype.insertAdjacentElement;
    if (typeof nativeInsertAdjacentElement === 'function') {
      patchMethod(
        [win.Element.prototype],
        'insertAdjacentElement',
        function guardedInsertAdjacentElement(position, element) {
          if (!scrubNodeBeforeInsertion(element)) return null;
          return ReflectApply(nativeInsertAdjacentElement, this, [
            position,
            element,
          ]);
        },
      );
    }

    const nativeInsertAdjacentHTML = win.Element.prototype.insertAdjacentHTML;
    if (typeof nativeInsertAdjacentHTML === 'function') {
      patchMethod(
        [win.Element.prototype],
        'insertAdjacentHTML',
        function guardedInsertAdjacentHTML(position, text) {
          ReflectApply(nativeInsertAdjacentHTML, this, [position, text]);
          sanitizeInjectedNode(this.parentNode || this);
        },
      );
    }

    const innerHtmlDesc = ObjectGetOwnPropertyDescriptor(
      win.Element.prototype,
      'innerHTML',
    );
    if (innerHtmlDesc?.set && innerHtmlDesc.configurable) {
      patchAccessor(
        [win.Element.prototype],
        'innerHTML',
        innerHtmlDesc.get,
        function guardedInnerHtmlSetter(html) {
          ReflectApply(innerHtmlDesc.set, this, [html]);
          sanitizeInjectedNode(this);
        },
      );
    }

    const outerHtmlDesc = ObjectGetOwnPropertyDescriptor(
      win.Element.prototype,
      'outerHTML',
    );
    if (outerHtmlDesc?.set && outerHtmlDesc.configurable) {
      patchAccessor(
        [win.Element.prototype],
        'outerHTML',
        outerHtmlDesc.get,
        function guardedOuterHtmlSetter(html) {
          const parent = this.parentNode;
          ReflectApply(outerHtmlDesc.set, this, [html]);
          if (parent) sanitizeInjectedNode(parent);
        },
      );
    }
  }

  if (win.Range?.prototype?.createContextualFragment) {
    const nativeCreateFragment = win.Range.prototype.createContextualFragment;
    patchMethod(
      [win.Range.prototype],
      'createContextualFragment',
      function guardedCreateContextualFragment(fragmentString) {
        const frag = ReflectApply(nativeCreateFragment, this, [fragmentString]);
        scrubNodeBeforeInsertion(frag);
        return frag;
      },
    );
  }

  if (typeof win.MutationObserver === 'function' && doc.documentElement) {
    try {
      domGuardObserver = new win.MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === 'childList') {
            mutation.addedNodes.forEach((added) => sanitizeInjectedNode(added));
          } else if (
            mutation.type === 'attributes' &&
            mutation.attributeName === 'autofocus' &&
            mutation.target?.removeAttribute
          ) {
            mutation.target.removeAttribute('autofocus');
          }
        });
      });
      domGuardObserver.observe(doc.documentElement, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['autofocus'],
      });
    } catch (_err) {
      domGuardObserver = null;
    }
  }

  function onDomReady() {
    if (autoHeightEnabled) {
      setupResizeObserver();
    }
    sendToHost({
      type: 'ready',
      height: measureContentHeight(),
    });
  }

  if (doc.readyState === 'loading') {
    nativeDocAddEventListener('DOMContentLoaded', onDomReady, { once: true });
    nativeWinAddEventListener('load', () => {
      sendToHost({
        type: 'load',
        height: measureContentHeight(),
      });
    }, { once: true });
  } else {
    onDomReady();
  }

  // Initiate handshake immediately in <head> before author scripts execute
  connectChannel();

  let destroyed = false;

  return {
    destroy() {
      if (destroyed) return;
      destroyed = true;
      guardedWindows.delete(win);
      registeredListeners.forEach((entry) => entry.remove());
      registeredListeners.length = 0;
      if (resizeObserver) {
        resizeObserver.disconnect();
        resizeObserver = null;
      }
      if (domGuardObserver) {
        domGuardObserver.disconnect();
        domGuardObserver = null;
      }
      if (activePort) {
        try {
          activePort.close();
        } catch (_err) {
          // Ignore
        }
        activePort = null;
      }
      activeTimeouts.forEach((entry) => {
        if (entry.nativeId != null) nativeClearTimeout(entry.nativeId);
      });
      activeIntervals.forEach((entry) => {
        if (entry.nativeId != null) nativeClearInterval(entry.nativeId);
      });
      pendingRafs.forEach((entry) => {
        if (entry.nativeId != null) nativeCAF(entry.nativeId);
      });
      activeTimeouts.clear();
      activeIntervals.clear();
      pendingRafs.clear();
      pausedRafQueue = [];
      for (let i = patchedDescriptors.length - 1; i >= 0; i -= 1) {
        const { target, propName, hadOwn, descriptor } = patchedDescriptors[i];
        try {
          if (hadOwn && descriptor) {
            ObjectDefineProperty(target, propName, descriptor);
          } else {
            delete target[propName];
          }
        } catch (_err) {
          // Ignore non-restorable host descriptors
        }
      }
    },
  };
}
