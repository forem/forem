(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global.PullToRefresh = factory());
}(this, (function () {

  function _ptrMarkup () { return "\n<div class=\"__PREFIX__box\">\n  <div class=\"__PREFIX__content\">\n    <div class=\"__PREFIX__icon\"></div>\n    <div class=\"__PREFIX__text\"></div>\n  </div>\n</div>"; }

  function _ptrStyles () { return ".__PREFIX__ptr {\n  box-shadow: inset 0 -3px 5px rgba(0, 0, 0, 0.12);\n  pointer-events: none;\n  font-size: 0.85em;\n  font-weight: bold;\n  top: 0;\n  height: 0;\n  transition: height 0.3s, min-height 0.3s;\n  text-align: center;\n  width: 100%;\n  overflow: hidden;\n  display: flex;\n  align-items: flex-end;\n  align-content: stretch;\n}\n.__PREFIX__box {\n  padding: 10px;\n  flex-basis: 100%;\n}\n.__PREFIX__pull {\n  transition: none;\n}\n.__PREFIX__text {\n  margin-top: 0.33em;\n opacity: 0.7; }\n.__PREFIX__icon {\n transition: transform 0.3s;\n opacity: 0.7;}\n.__PREFIX__top {\n  touch-action: pan-x pan-down pinch-zoom;\n}\n.__PREFIX__release .__PREFIX__icon {\n  transform: rotate(180deg);\n}\n"; }

  var _defaults = {
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
    getMarkup: _ptrMarkup,
    getStyles: _ptrStyles,
    onInit: function () {},
    onRefresh: function () { return location.reload(); },
    resistanceFunction: function (t) { return Math.min(1, t / 2.5); },
    shouldPullToRefresh: function () {
      return !window.scrollY &&
        (document.getElementById('articles-list') || document.getElementById("user-dashboard") || document.getElementById("article-body") || document.getElementById('classifieds-index-container')) &&
        !document.body.classList.contains('modal-open')
    },
  };

  var _methods = ['mainElement', 'ptrElement', 'triggerElement'];

  var _shared = {
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
      get passive() { // eslint-disable-line getter-return
        _shared.supportsPassive = true;
      },
    });
  } catch (e) {
    // do nothing
  }

  var _ptr = {
    setupDOM: function setupDOM(handler) {
      if (!handler.ptrElement) {
        var ptr = document.createElement('div');

        if (handler.mainElement !== document.body) {
          handler.mainElement.parentNode.insertBefore(ptr, handler.mainElement);
        } else {
          document.body.insertBefore(ptr, document.body.firstChild);
        }

        ptr.classList.add(((handler.classPrefix) + "ptr"));
        ptr.innerHTML = handler.getMarkup()
          .replace(/__PREFIX__/g, handler.classPrefix);

        handler.ptrElement = ptr;

        if (typeof handler.onInit === 'function') {
          handler.onInit(handler);
        }

        // Add the css styles to the style node, and then
        // insert it into the dom
        if (!_shared.styleEl) {
          _shared.styleEl = document.createElement('style');
          _shared.styleEl.setAttribute('id', 'pull-to-refresh-js-style');

          document.head.appendChild(_shared.styleEl);
        }

        _shared.styleEl.textContent = handler.getStyles()
          .replace(/__PREFIX__/g, handler.classPrefix)
          .replace(/\s+/g, ' ');
      }

      return handler;
    },
    onReset: function onReset(handler) {
      handler.ptrElement.classList.remove(((handler.classPrefix) + "refresh"));
      handler.ptrElement.style[handler.cssProp] = '0px';
      setTimeout(function () {
        // remove previous ptr-element from DOM
        if (handler.ptrElement && handler.ptrElement.parentNode) {
          handler.ptrElement.parentNode.removeChild(handler.ptrElement);
          handler.ptrElement = null;
        }

        // reset state
        _shared.state = 'pending';
      }, handler.refreshTimeout);
    },
    update: function update(handler) {
      var iconEl = handler.ptrElement.querySelector(("." + (handler.classPrefix) + "icon"));
      var textEl = handler.ptrElement.querySelector(("." + (handler.classPrefix) + "text"));

      if (iconEl) {
        if (_shared.state === 'refreshing') {
          iconEl.innerHTML = handler.iconRefreshing;
        } else {
          iconEl.innerHTML = handler.iconArrow;
        }
      }

      if (textEl) {
        if (_shared.state === 'releasing') {
          textEl.innerHTML = handler.instructionsReleaseToRefresh;
          sendHapticMessage('medium');
        }

        if (_shared.state === 'pulling' || _shared.state === 'pending') {
          textEl.innerHTML = handler.instructionsPullToRefresh;
        }

        if (_shared.state === 'refreshing') {
          textEl.innerHTML = handler.instructionsRefreshing;
        }
      }
    },
  };

  function _setupEvents() {
    var _el;

    function _onTouchStart(e) {
      // here, we must pick a handler first, and then append their html/css on the DOM
      var target = _shared.handlers.filter(function (h) { return h.contains(e.target); })[0];

      _shared.enable = !!target;

      if (target && _shared.state === 'pending') {
        _el = _ptr.setupDOM(target);

        if (target.shouldPullToRefresh()) {
          _shared.pullStartY = e.touches[0].screenY;
        }

        clearTimeout(_shared.timeout);

        _ptr.update(target);
      }
    }

    function _onTouchMove(e) {
      if (!(_el && _el.ptrElement && _shared.enable)) {
        return;
      }

      if (!_shared.pullStartY) {
        if (_el.shouldPullToRefresh()) {
          _shared.pullStartY = e.touches[0].screenY;
        }
      } else {
        _shared.pullMoveY = e.touches[0].screenY;
      }

      if (_shared.state === 'refreshing') {
        if (_el.shouldPullToRefresh() && _shared.pullStartY < _shared.pullMoveY) {
          e.preventDefault();
        }

        return;
      }

      if (_shared.state === 'pending') {
        _el.ptrElement.classList.add(((_el.classPrefix) + "pull"));
        _shared.state = 'pulling';
        _ptr.update(_el);
      }

      if (_shared.pullStartY && _shared.pullMoveY) {
        _shared.dist = _shared.pullMoveY - _shared.pullStartY;
      }

      _shared.distExtra = _shared.dist - _el.distIgnore;

      if (_shared.distExtra > 0) {
        e.preventDefault();

        _el.ptrElement.style[_el.cssProp] = (_shared.distResisted) + "px";

        _shared.distResisted = _el.resistanceFunction(_shared.distExtra / _el.distThreshold)
          * Math.min(_el.distMax, _shared.distExtra);

        if (_shared.state === 'pulling' && _shared.distResisted > _el.distThreshold) {
          _el.ptrElement.classList.add(((_el.classPrefix) + "release"));
          _shared.state = 'releasing';
          _ptr.update(_el);
        }

        if (_shared.state === 'releasing' && _shared.distResisted < _el.distThreshold) {
          _el.ptrElement.classList.remove(((_el.classPrefix) + "release"));
          _shared.state = 'pulling';
          _ptr.update(_el);
        }
      }
    }

    function _onTouchEnd() {
      if (!(_el && _el.ptrElement && _shared.enable)) {
        return;
      }

      if (_shared.state === 'releasing' && _shared.distResisted > _el.distThreshold) {
        _shared.state = 'refreshing';

        _el.ptrElement.style[_el.cssProp] = (_el.distReload) + "px";
        _el.ptrElement.classList.add(((_el.classPrefix) + "refresh"));

        _shared.timeout = setTimeout(function () {
          var retval = _el.onRefresh(function () { return _ptr.onReset(_el); });

          if (retval && typeof retval.then === 'function') {
            retval.then(function () { return _ptr.onReset(_el); });
          }

          if (!retval && !_el.onRefresh.length) {
            _ptr.onReset(_el);
          }
        }, _el.refreshTimeout);
      } else {
        if (_shared.state === 'refreshing') {
          return;
        }

        _el.ptrElement.style[_el.cssProp] = '0px';

        _shared.state = 'pending';
      }

      _ptr.update(_el);

      _el.ptrElement.classList.remove(((_el.classPrefix) + "release"));
      _el.ptrElement.classList.remove(((_el.classPrefix) + "pull"));

      _shared.pullStartY = _shared.pullMoveY = null;
      _shared.dist = _shared.distResisted = 0;
    }

    function _onScroll() {
      if (_el) {
        _el.mainElement.classList.toggle(((_el.classPrefix) + "top"), _el.shouldPullToRefresh());
      }
    }

    var _passiveSettings = _shared.supportsPassive
      ? { passive: _shared.passive || false }
      : undefined;

    window.addEventListener('touchend', _onTouchEnd);
    window.addEventListener('touchstart', _onTouchStart);
    window.addEventListener('touchmove', _onTouchMove, _passiveSettings);
    window.addEventListener('scroll', _onScroll);

    return {
      onTouchEnd: _onTouchEnd,
      onTouchStart: _onTouchStart,
      onTouchMove: _onTouchMove,
      onScroll: _onScroll,

      destroy: function destroy() {
        // Teardown event listeners
        window.removeEventListener('touchstart', _onTouchStart);
        window.removeEventListener('touchend', _onTouchEnd);
        window.removeEventListener('touchmove', _onTouchMove, _passiveSettings);
        window.removeEventListener('scroll', _onScroll);
      },
    };
  }

  function _setupHandler(options) {
    var _handler = {};

    // merge options with defaults
    Object.keys(_defaults).forEach(function (key) {
      _handler[key] = options[key] || _defaults[key];
    });

    // normalize timeout value, even if it is zero
    _handler.refreshTimeout = typeof options.refreshTimeout === 'number'
      ? options.refreshTimeout
      : _defaults.refreshTimeout;

    // normalize elements
    _methods.forEach(function (method) {
      if (typeof _handler[method] === 'string') {
        _handler[method] = document.querySelector(_handler[method]);
      }
    });

    // attach events lazily
    if (!_shared.events) {
      _shared.events = _setupEvents();
    }

    _handler.contains = function (target) {
      return _handler.triggerElement.contains(target);
    };

    _handler.destroy = function () {
      // stop pending any pending callbacks
      clearTimeout(_shared.timeout);

      // remove handler from shared state
      _shared.handlers.splice(_handler.offset, 1);
    };

    return _handler;
  }

  // public API
  var index = {
    setPassiveMode: function setPassiveMode(isPassive) {
      _shared.passive = isPassive;
    },
    destroyAll: function destroyAll() {
      if (_shared.events) {
        _shared.events.destroy();
        _shared.events = null;
      }

      _shared.handlers.forEach(function (h) {
        h.destroy();
      });
    },
    init: function init(options) {
      if ( options === void 0 ) options = {};

      var handler = _setupHandler(options);

      // store offset for later unsubscription
      handler.offset = _shared.handlers.push(handler) - 1;

      return handler;
    },

    // export utils for testing
    _: {
      setupHandler: _setupHandler,
      setupEvents: _setupEvents,
      setupDOM: _ptr.setupDOM,
      onReset: _ptr.onReset,
      update: _ptr.update,
    },
  };

  return index;

})));