'use strict';

((g, factory) => {
  const global = g;
  if (typeof exports === 'object' && typeof module !== 'undefined') {
    module.exports = factory();
  } else if (typeof window.define === 'function' && window.define.amd) {
    window.define(factory);
  } else {
    global.PullToRefresh = factory();
  }
})(this, () => {
  function ptrMarkup() {
    return '\n<div class="__PREFIX__box">\n  <div class="__PREFIX__content">\n    <div class="__PREFIX__icon"></div>\n    <div class="__PREFIX__text"></div>\n  </div>\n</div>';
  }

  function ptrStyles() {
    return '.__PREFIX__ptr {\n  box-shadow: inset 0 -3px 5px rgba(0, 0, 0, 0.12);\n  pointer-events: none;\n  font-size: 0.85em;\n  font-weight: bold;\n  top: 0;\n  height: 0;\n  transition: height 0.3s, min-height 0.3s;\n  text-align: center;\n  width: 100%;\n  overflow: hidden;\n  display: flex;\n  align-items: flex-end;\n  align-content: stretch;\n}\n.__PREFIX__box {\n  padding: 10px;\n  flex-basis: 100%;\n}\n.__PREFIX__pull {\n  transition: none;\n}\n.__PREFIX__text {\n  margin-top: 0.33em;\n opacity: 0.7; }\n.__PREFIX__icon {\n transition: transform 0.3s;\n opacity: 0.7;}\n.__PREFIX__top {\n  touch-action: pan-x pan-down pinch-zoom;\n}\n.__PREFIX__release .__PREFIX__icon {\n  transform: rotate(180deg);\n}\n';
  }

  var defaults = {
    distThreshold: 60,
    distMax: 80,
    distReload: 50,
    distIgnore: 0,
    bodyOffset: 20,
    mainElement: 'body',
    triggerElement: 'body',
    ptrElement: '.ptr',
    classPrefix: 'ptr--',
    cssProp: 'min-height',
    iconArrow: '&#8675;',
    iconRefreshing: '&hellip;',
    instructionsPullToRefresh: 'Pull down to refresh',
    instructionsReleaseToRefresh: 'Release to refresh',
    instructionsRefreshing: 'Refreshing',
    refreshTimeout: 350,
    getMarkup: ptrMarkup,
    getStyles: ptrStyles,
    onInit: () => {},
    onRefresh: () => {
      return window.location.reload();
    },
    resistanceFunction: (t) => {
      return Math.min(1, t / 2.5);
    },
    shouldPullToRefresh: () => {
      return (
        !window.scrollY &&
        (document.getElementById('articles-list') ||
          document.getElementById('main-content') ||
          document.getElementById('user-dashboard') ||
          document.getElementById('article-body') ||
          document.getElementById('listings-index-container')) &&
        !document.body.classList.contains('modal-open')
      );
    },
  };

  var methods = ['mainElement', 'ptrElement', 'triggerElement'];

  var shared = {
    pullStartY: null,
    pullMoveY: null,
    handlers: [],
    styleEl: null,
    events: null,
    dist: 0,
    state: 'pending',
    timeout: null,
    distResisted: 0,
    supportsPassive: false,
  };

  try {
    window.addEventListener('test', null, {
      // eslint-disable-next-line getter-return
      get passive() {
        shared.supportsPassive = true;
      },
    });
  } catch (e) {
    // do nothing
  }

  var ptr = {
    setupDOM: function setupDOM(h) {
      const handler = h;
      if (!handler.ptrElement) {
        var innerPtr = document.createElement('div');

        if (handler.mainElement !== document.body) {
          handler.mainElement.parentNode.insertBefore(
            innerPtr,
            handler.mainElement,
          );
        } else {
          document.body.insertBefore(innerPtr, document.body.firstChild);
        }

        innerPtr.classList.add(handler.classPrefix + 'ptr');
        innerPtr.innerHTML = handler
          .getMarkup()
          .replace(/__PREFIX__/g, handler.classPrefix);

        handler.ptrElement = innerPtr;

        if (typeof handler.onInit === 'function') {
          handler.onInit(handler);
        }

        // Add the css styles to the style node, and then
        // insert it into the dom
        if (!shared.styleEl) {
          shared.styleEl = document.createElement('style');
          shared.styleEl.setAttribute('id', 'pull-to-refresh-js-style');

          document.head.appendChild(shared.styleEl);
        }

        shared.styleEl.textContent = handler
          .getStyles()
          .replace(/__PREFIX__/g, handler.classPrefix)
          .replace(/\s+/g, ' ');
      }

      return handler;
    },
    onReset: function onReset(h) {
      const handler = h;
      handler.ptrElement.classList.remove(handler.classPrefix + 'refresh');
      handler.ptrElement.style[handler.cssProp] = '0px';
      setTimeout(() => {
        // remove previous ptr-element from DOM
        if (handler.ptrElement && handler.ptrElement.parentNode) {
          handler.ptrElement.parentNode.removeChild(handler.ptrElement);
          handler.ptrElement = null;
        }

        // reset state
        shared.state = 'pending';
      }, handler.refreshTimeout);
    },
    update: function update(handler) {
      var iconEl = handler.ptrElement.querySelector(
        '.' + handler.classPrefix + 'icon',
      );
      var textEl = handler.ptrElement.querySelector(
        '.' + handler.classPrefix + 'text',
      );

      if (iconEl) {
        if (shared.state === 'refreshing') {
          iconEl.innerHTML = handler.iconRefreshing;
        } else {
          iconEl.innerHTML = handler.iconArrow;
        }
      }

      if (textEl) {
        if (shared.state === 'releasing') {
          textEl.innerHTML = handler.instructionsReleaseToRefresh;
          window.sendHapticMessage('medium');
        }

        if (shared.state === 'pulling' || shared.state === 'pending') {
          textEl.innerHTML = handler.instructionsPullToRefresh;
        }

        if (shared.state === 'refreshing') {
          textEl.innerHTML = handler.instructionsRefreshing;
        }
      }
    },
  };

  function setupEvents() {
    var el;

    function onTouchStart(e) {
      // here, we must pick a handler first, and then append their html/css on the DOM
      var target = shared.handlers.filter((h) => {
        return h.contains(e.target);
      })[0];

      shared.enable = !!target;

      if (target && shared.state === 'pending') {
        el = ptr.setupDOM(target);

        if (target.shouldPullToRefresh()) {
          shared.pullStartY = e.touches[0].screenY;
        }

        clearTimeout(shared.timeout);

        ptr.update(target);
      }
    }

    function onTouchMove(e) {
      if (!(el && el.ptrElement && shared.enable)) {
        return;
      }

      if (!shared.pullStartY) {
        if (el.shouldPullToRefresh()) {
          shared.pullStartY = e.touches[0].screenY;
        }
      } else {
        shared.pullMoveY = e.touches[0].screenY;
      }

      if (shared.state === 'refreshing') {
        if (el.shouldPullToRefresh() && shared.pullStartY < shared.pullMoveY) {
          e.preventDefault();
        }

        return;
      }

      if (shared.state === 'pending') {
        el.ptrElement.classList.add(el.classPrefix + 'pull');
        shared.state = 'pulling';
        ptr.update(el);
      }

      if (shared.pullStartY && shared.pullMoveY) {
        shared.dist = shared.pullMoveY - shared.pullStartY;
      }

      shared.distExtra = shared.dist - el.distIgnore;

      if (shared.distExtra > 0) {
        e.preventDefault();

        el.ptrElement.style[el.cssProp] = shared.distResisted + 'px';

        shared.distResisted =
          el.resistanceFunction(shared.distExtra / el.distThreshold) *
          Math.min(el.distMax, shared.distExtra);

        if (
          shared.state === 'pulling' &&
          shared.distResisted > el.distThreshold
        ) {
          el.ptrElement.classList.add(el.classPrefix + 'release');
          shared.state = 'releasing';
          ptr.update(el);
        }

        if (
          shared.state === 'releasing' &&
          shared.distResisted < el.distThreshold
        ) {
          el.ptrElement.classList.remove(el.classPrefix + 'release');
          shared.state = 'pulling';
          ptr.update(el);
        }
      }
    }

    function onTouchEnd() {
      if (!(el && el.ptrElement && shared.enable)) {
        return;
      }

      if (
        shared.state === 'releasing' &&
        shared.distResisted > el.distThreshold
      ) {
        shared.state = 'refreshing';

        el.ptrElement.style[el.cssProp] = el.distReload + 'px';
        el.ptrElement.classList.add(el.classPrefix + 'refresh');

        shared.timeout = setTimeout(() => {
          var retval = el.onRefresh(() => {
            return ptr.onReset(el);
          });

          if (retval && typeof retval.then === 'function') {
            retval.then(() => {
              return ptr.onReset(el);
            });
          }

          if (!retval && !el.onRefresh.length) {
            ptr.onReset(el);
          }
        }, el.refreshTimeout);
      } else {
        if (shared.state === 'refreshing') {
          return;
        }

        el.ptrElement.style[el.cssProp] = '0px';

        shared.state = 'pending';
      }

      ptr.update(el);

      el.ptrElement.classList.remove(el.classPrefix + 'release');
      el.ptrElement.classList.remove(el.classPrefix + 'pull');

      shared.pullStartY = null;
      shared.pullMoveY = null;
      shared.dist = 0;
      shared.distResisted = 0;
    }

    function onScroll() {
      if (el) {
        el.mainElement.classList.toggle(
          el.classPrefix + 'top',
          el.shouldPullToRefresh(),
        );
      }
    }

    var passiveSettings = shared.supportsPassive
      ? { passive: shared.passive || false }
      : undefined;

    window.addEventListener('touchend', onTouchEnd);
    window.addEventListener('touchstart', onTouchStart);
    window.addEventListener('touchmove', onTouchMove, passiveSettings);
    window.addEventListener('scroll', onScroll);

    return {
      onTouchEnd,
      onTouchStart,
      onTouchMove,
      onScroll,

      destroy: function destroy() {
        // Teardown event listeners
        window.removeEventListener('touchstart', onTouchStart);
        window.removeEventListener('touchend', onTouchEnd);
        window.removeEventListener('touchmove', onTouchMove, passiveSettings);
        window.removeEventListener('scroll', onScroll);
      },
    };
  }

  function setupHandler(options) {
    var handler = {};

    // merge options with defaults
    Object.keys(defaults).forEach((key) => {
      handler[key] = options[key] || defaults[key];
    });

    // normalize timeout value, even if it is zero
    handler.refreshTimeout =
      typeof options.refreshTimeout === 'number'
        ? options.refreshTimeout
        : defaults.refreshTimeout;

    // normalize elements
    methods.forEach((method) => {
      if (typeof handler[method] === 'string') {
        handler[method] = document.querySelector(handler[method]);
      }
    });

    // attach events lazily
    if (!shared.events) {
      shared.events = setupEvents();
    }

    handler.contains = (target) => {
      return handler.triggerElement.contains(target);
    };

    handler.destroy = () => {
      // stop pending any pending callbacks
      clearTimeout(shared.timeout);

      // remove handler from shared state
      shared.handlers.splice(handler.offset, 1);
    };

    return handler;
  }

  // public API
  var index = {
    setPassiveMode: function setPassiveMode(isPassive) {
      shared.passive = isPassive;
    },
    destroyAll: function destroyAll() {
      if (shared.events) {
        shared.events.destroy();
        shared.events = null;
      }

      shared.handlers.forEach((h) => {
        h.destroy();
      });
    },
    init: function init(o) {
      const options = typeof o === 'undefined' ? {} : o;

      var handler = setupHandler(options);

      // store offset for later unsubscription
      handler.offset = shared.handlers.push(handler) - 1;

      return handler;
    },

    // export utils for testing
    _: {
      setupHandler,
      setupEvents,
      setupDOM: ptr.setupDOM,
      onReset: ptr.onReset,
      update: ptr.update,
    },
  };

  return index;
});
