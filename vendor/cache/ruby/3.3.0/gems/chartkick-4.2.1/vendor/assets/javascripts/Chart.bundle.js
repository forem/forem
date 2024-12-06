/*!
 * Chart.js v3.9.0
 * https://www.chartjs.org
 * (c) 2022 Chart.js Contributors
 * Released under the MIT License
 *
 * chartjs-adapter-date-fns v2.0.0
 * https://www.chartjs.org
 * (c) 2021 chartjs-adapter-date-fns Contributors
 * Released under the MIT license
 *
 * date-fns v2.29.1
 * https://date-fns.org
 * (c) 2021 Sasha Koss and Lesha Koss
 * Released under the MIT License
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.Chart = factory());
})(this, (function () { 'use strict';

  function ownKeys(object, enumerableOnly) {
    var keys = Object.keys(object);

    if (Object.getOwnPropertySymbols) {
      var symbols = Object.getOwnPropertySymbols(object);
      enumerableOnly && (symbols = symbols.filter(function (sym) {
        return Object.getOwnPropertyDescriptor(object, sym).enumerable;
      })), keys.push.apply(keys, symbols);
    }

    return keys;
  }

  function _objectSpread2(target) {
    for (var i = 1; i < arguments.length; i++) {
      var source = null != arguments[i] ? arguments[i] : {};
      i % 2 ? ownKeys(Object(source), !0).forEach(function (key) {
        _defineProperty$x(target, key, source[key]);
      }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) {
        Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
      });
    }

    return target;
  }

  function _typeof(obj) {
    "@babel/helpers - typeof";

    return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) {
      return typeof obj;
    } : function (obj) {
      return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
    }, _typeof(obj);
  }

  function _classCallCheck(instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  }

  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps) _defineProperties(Constructor.prototype, protoProps);
    if (staticProps) _defineProperties(Constructor, staticProps);
    Object.defineProperty(Constructor, "prototype", {
      writable: false
    });
    return Constructor;
  }

  function _defineProperty$x(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  function _inherits(subClass, superClass) {
    if (typeof superClass !== "function" && superClass !== null) {
      throw new TypeError("Super expression must either be null or a function");
    }

    subClass.prototype = Object.create(superClass && superClass.prototype, {
      constructor: {
        value: subClass,
        writable: true,
        configurable: true
      }
    });
    Object.defineProperty(subClass, "prototype", {
      writable: false
    });
    if (superClass) _setPrototypeOf(subClass, superClass);
  }

  function _getPrototypeOf(o) {
    _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function _getPrototypeOf(o) {
      return o.__proto__ || Object.getPrototypeOf(o);
    };
    return _getPrototypeOf(o);
  }

  function _setPrototypeOf(o, p) {
    _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function _setPrototypeOf(o, p) {
      o.__proto__ = p;
      return o;
    };
    return _setPrototypeOf(o, p);
  }

  function _isNativeReflectConstruct() {
    if (typeof Reflect === "undefined" || !Reflect.construct) return false;
    if (Reflect.construct.sham) return false;
    if (typeof Proxy === "function") return true;

    try {
      Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
      return true;
    } catch (e) {
      return false;
    }
  }

  function _assertThisInitialized(self) {
    if (self === void 0) {
      throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
    }

    return self;
  }

  function _possibleConstructorReturn(self, call) {
    if (call && (typeof call === "object" || typeof call === "function")) {
      return call;
    } else if (call !== void 0) {
      throw new TypeError("Derived constructors may only return object or undefined");
    }

    return _assertThisInitialized(self);
  }

  function _createSuper(Derived) {
    var hasNativeReflectConstruct = _isNativeReflectConstruct();

    return function _createSuperInternal() {
      var Super = _getPrototypeOf(Derived),
          result;

      if (hasNativeReflectConstruct) {
        var NewTarget = _getPrototypeOf(this).constructor;

        result = Reflect.construct(Super, arguments, NewTarget);
      } else {
        result = Super.apply(this, arguments);
      }

      return _possibleConstructorReturn(this, result);
    };
  }

  function _superPropBase(object, property) {
    while (!Object.prototype.hasOwnProperty.call(object, property)) {
      object = _getPrototypeOf(object);
      if (object === null) break;
    }

    return object;
  }

  function _get() {
    if (typeof Reflect !== "undefined" && Reflect.get) {
      _get = Reflect.get.bind();
    } else {
      _get = function _get(target, property, receiver) {
        var base = _superPropBase(target, property);

        if (!base) return;
        var desc = Object.getOwnPropertyDescriptor(base, property);

        if (desc.get) {
          return desc.get.call(arguments.length < 3 ? target : receiver);
        }

        return desc.value;
      };
    }

    return _get.apply(this, arguments);
  }

  function _slicedToArray(arr, i) {
    return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest();
  }

  function _toConsumableArray(arr) {
    return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
  }

  function _arrayWithoutHoles(arr) {
    if (Array.isArray(arr)) return _arrayLikeToArray(arr);
  }

  function _arrayWithHoles(arr) {
    if (Array.isArray(arr)) return arr;
  }

  function _iterableToArray(iter) {
    if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter);
  }

  function _iterableToArrayLimit(arr, i) {
    var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"];

    if (_i == null) return;
    var _arr = [];
    var _n = true;
    var _d = false;

    var _s, _e;

    try {
      for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) {
        _arr.push(_s.value);

        if (i && _arr.length === i) break;
      }
    } catch (err) {
      _d = true;
      _e = err;
    } finally {
      try {
        if (!_n && _i["return"] != null) _i["return"]();
      } finally {
        if (_d) throw _e;
      }
    }

    return _arr;
  }

  function _unsupportedIterableToArray(o, minLen) {
    if (!o) return;
    if (typeof o === "string") return _arrayLikeToArray(o, minLen);
    var n = Object.prototype.toString.call(o).slice(8, -1);
    if (n === "Object" && o.constructor) n = o.constructor.name;
    if (n === "Map" || n === "Set") return Array.from(o);
    if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen);
  }

  function _arrayLikeToArray(arr, len) {
    if (len == null || len > arr.length) len = arr.length;

    for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i];

    return arr2;
  }

  function _nonIterableSpread() {
    throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
  }

  function _nonIterableRest() {
    throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
  }

  function _createForOfIteratorHelper(o, allowArrayLike) {
    var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"];

    if (!it) {
      if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") {
        if (it) o = it;
        var i = 0;

        var F = function () {};

        return {
          s: F,
          n: function () {
            if (i >= o.length) return {
              done: true
            };
            return {
              done: false,
              value: o[i++]
            };
          },
          e: function (e) {
            throw e;
          },
          f: F
        };
      }

      throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
    }

    var normalCompletion = true,
        didErr = false,
        err;
    return {
      s: function () {
        it = it.call(o);
      },
      n: function () {
        var step = it.next();
        normalCompletion = step.done;
        return step;
      },
      e: function (e) {
        didErr = true;
        err = e;
      },
      f: function () {
        try {
          if (!normalCompletion && it.return != null) it.return();
        } finally {
          if (didErr) throw err;
        }
      }
    };
  }

  /*!
   * Chart.js v3.9.0
   * https://www.chartjs.org
   * (c) 2022 Chart.js Contributors
   * Released under the MIT License
   */
  function noop() {}

  var uid = function () {
    var id = 0;
    return function () {
      return id++;
    };
  }();

  function isNullOrUndef(value) {
    return value === null || typeof value === 'undefined';
  }

  function isArray(value) {
    if (Array.isArray && Array.isArray(value)) {
      return true;
    }

    var type = Object.prototype.toString.call(value);

    if (type.slice(0, 7) === '[object' && type.slice(-6) === 'Array]') {
      return true;
    }

    return false;
  }

  function isObject(value) {
    return value !== null && Object.prototype.toString.call(value) === '[object Object]';
  }

  var isNumberFinite = function isNumberFinite(value) {
    return (typeof value === 'number' || value instanceof Number) && isFinite(+value);
  };

  function finiteOrDefault(value, defaultValue) {
    return isNumberFinite(value) ? value : defaultValue;
  }

  function valueOrDefault(value, defaultValue) {
    return typeof value === 'undefined' ? defaultValue : value;
  }

  var toPercentage = function toPercentage(value, dimension) {
    return typeof value === 'string' && value.endsWith('%') ? parseFloat(value) / 100 : value / dimension;
  };

  var toDimension = function toDimension(value, dimension) {
    return typeof value === 'string' && value.endsWith('%') ? parseFloat(value) / 100 * dimension : +value;
  };

  function callback(fn, args, thisArg) {
    if (fn && typeof fn.call === 'function') {
      return fn.apply(thisArg, args);
    }
  }

  function each(loopable, fn, thisArg, reverse) {
    var i, len, keys;

    if (isArray(loopable)) {
      len = loopable.length;

      if (reverse) {
        for (i = len - 1; i >= 0; i--) {
          fn.call(thisArg, loopable[i], i);
        }
      } else {
        for (i = 0; i < len; i++) {
          fn.call(thisArg, loopable[i], i);
        }
      }
    } else if (isObject(loopable)) {
      keys = Object.keys(loopable);
      len = keys.length;

      for (i = 0; i < len; i++) {
        fn.call(thisArg, loopable[keys[i]], keys[i]);
      }
    }
  }

  function _elementsEqual(a0, a1) {
    var i, ilen, v0, v1;

    if (!a0 || !a1 || a0.length !== a1.length) {
      return false;
    }

    for (i = 0, ilen = a0.length; i < ilen; ++i) {
      v0 = a0[i];
      v1 = a1[i];

      if (v0.datasetIndex !== v1.datasetIndex || v0.index !== v1.index) {
        return false;
      }
    }

    return true;
  }

  function clone$1(source) {
    if (isArray(source)) {
      return source.map(clone$1);
    }

    if (isObject(source)) {
      var target = Object.create(null);
      var keys = Object.keys(source);
      var klen = keys.length;
      var k = 0;

      for (; k < klen; ++k) {
        target[keys[k]] = clone$1(source[keys[k]]);
      }

      return target;
    }

    return source;
  }

  function isValidKey(key) {
    return ['__proto__', 'prototype', 'constructor'].indexOf(key) === -1;
  }

  function _merger(key, target, source, options) {
    if (!isValidKey(key)) {
      return;
    }

    var tval = target[key];
    var sval = source[key];

    if (isObject(tval) && isObject(sval)) {
      merge(tval, sval, options);
    } else {
      target[key] = clone$1(sval);
    }
  }

  function merge(target, source, options) {
    var sources = isArray(source) ? source : [source];
    var ilen = sources.length;

    if (!isObject(target)) {
      return target;
    }

    options = options || {};
    var merger = options.merger || _merger;

    for (var i = 0; i < ilen; ++i) {
      source = sources[i];

      if (!isObject(source)) {
        continue;
      }

      var keys = Object.keys(source);

      for (var k = 0, klen = keys.length; k < klen; ++k) {
        merger(keys[k], target, source, options);
      }
    }

    return target;
  }

  function mergeIf(target, source) {
    return merge(target, source, {
      merger: _mergerIf
    });
  }

  function _mergerIf(key, target, source) {
    if (!isValidKey(key)) {
      return;
    }

    var tval = target[key];
    var sval = source[key];

    if (isObject(tval) && isObject(sval)) {
      mergeIf(tval, sval);
    } else if (!Object.prototype.hasOwnProperty.call(target, key)) {
      target[key] = clone$1(sval);
    }
  }

  var keyResolvers = {
    '': function _(v) {
      return v;
    },
    x: function x(o) {
      return o.x;
    },
    y: function y(o) {
      return o.y;
    }
  };

  function resolveObjectKey(obj, key) {
    var resolver = keyResolvers[key] || (keyResolvers[key] = _getKeyResolver(key));

    return resolver(obj);
  }

  function _getKeyResolver(key) {
    var keys = _splitKey(key);

    return function (obj) {
      var _iterator = _createForOfIteratorHelper(keys),
          _step;

      try {
        for (_iterator.s(); !(_step = _iterator.n()).done;) {
          var k = _step.value;

          if (k === '') {
            break;
          }

          obj = obj && obj[k];
        }
      } catch (err) {
        _iterator.e(err);
      } finally {
        _iterator.f();
      }

      return obj;
    };
  }

  function _splitKey(key) {
    var parts = key.split('.');
    var keys = [];
    var tmp = '';

    var _iterator2 = _createForOfIteratorHelper(parts),
        _step2;

    try {
      for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
        var part = _step2.value;
        tmp += part;

        if (tmp.endsWith('\\')) {
          tmp = tmp.slice(0, -1) + '.';
        } else {
          keys.push(tmp);
          tmp = '';
        }
      }
    } catch (err) {
      _iterator2.e(err);
    } finally {
      _iterator2.f();
    }

    return keys;
  }

  function _capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  var defined = function defined(value) {
    return typeof value !== 'undefined';
  };

  var isFunction = function isFunction(value) {
    return typeof value === 'function';
  };

  var setsEqual = function setsEqual(a, b) {
    if (a.size !== b.size) {
      return false;
    }

    var _iterator3 = _createForOfIteratorHelper(a),
        _step3;

    try {
      for (_iterator3.s(); !(_step3 = _iterator3.n()).done;) {
        var item = _step3.value;

        if (!b.has(item)) {
          return false;
        }
      }
    } catch (err) {
      _iterator3.e(err);
    } finally {
      _iterator3.f();
    }

    return true;
  };

  function _isClickEvent(e) {
    return e.type === 'mouseup' || e.type === 'click' || e.type === 'contextmenu';
  }

  var PI = Math.PI;
  var TAU = 2 * PI;
  var PITAU = TAU + PI;
  var INFINITY = Number.POSITIVE_INFINITY;
  var RAD_PER_DEG = PI / 180;
  var HALF_PI = PI / 2;
  var QUARTER_PI = PI / 4;
  var TWO_THIRDS_PI = PI * 2 / 3;
  var log10 = Math.log10;
  var sign = Math.sign;

  function niceNum(range) {
    var roundedRange = Math.round(range);
    range = almostEquals(range, roundedRange, range / 1000) ? roundedRange : range;
    var niceRange = Math.pow(10, Math.floor(log10(range)));
    var fraction = range / niceRange;
    var niceFraction = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 5 ? 5 : 10;
    return niceFraction * niceRange;
  }

  function _factorize(value) {
    var result = [];
    var sqrt = Math.sqrt(value);
    var i;

    for (i = 1; i < sqrt; i++) {
      if (value % i === 0) {
        result.push(i);
        result.push(value / i);
      }
    }

    if (sqrt === (sqrt | 0)) {
      result.push(sqrt);
    }

    result.sort(function (a, b) {
      return a - b;
    }).pop();
    return result;
  }

  function isNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
  }

  function almostEquals(x, y, epsilon) {
    return Math.abs(x - y) < epsilon;
  }

  function almostWhole(x, epsilon) {
    var rounded = Math.round(x);
    return rounded - epsilon <= x && rounded + epsilon >= x;
  }

  function _setMinAndMaxByKey(array, target, property) {
    var i, ilen, value;

    for (i = 0, ilen = array.length; i < ilen; i++) {
      value = array[i][property];

      if (!isNaN(value)) {
        target.min = Math.min(target.min, value);
        target.max = Math.max(target.max, value);
      }
    }
  }

  function toRadians(degrees) {
    return degrees * (PI / 180);
  }

  function toDegrees(radians) {
    return radians * (180 / PI);
  }

  function _decimalPlaces(x) {
    if (!isNumberFinite(x)) {
      return;
    }

    var e = 1;
    var p = 0;

    while (Math.round(x * e) / e !== x) {
      e *= 10;
      p++;
    }

    return p;
  }

  function getAngleFromPoint(centrePoint, anglePoint) {
    var distanceFromXCenter = anglePoint.x - centrePoint.x;
    var distanceFromYCenter = anglePoint.y - centrePoint.y;
    var radialDistanceFromCenter = Math.sqrt(distanceFromXCenter * distanceFromXCenter + distanceFromYCenter * distanceFromYCenter);
    var angle = Math.atan2(distanceFromYCenter, distanceFromXCenter);

    if (angle < -0.5 * PI) {
      angle += TAU;
    }

    return {
      angle: angle,
      distance: radialDistanceFromCenter
    };
  }

  function distanceBetweenPoints(pt1, pt2) {
    return Math.sqrt(Math.pow(pt2.x - pt1.x, 2) + Math.pow(pt2.y - pt1.y, 2));
  }

  function _angleDiff(a, b) {
    return (a - b + PITAU) % TAU - PI;
  }

  function _normalizeAngle(a) {
    return (a % TAU + TAU) % TAU;
  }

  function _angleBetween(angle, start, end, sameAngleIsFullCircle) {
    var a = _normalizeAngle(angle);

    var s = _normalizeAngle(start);

    var e = _normalizeAngle(end);

    var angleToStart = _normalizeAngle(s - a);

    var angleToEnd = _normalizeAngle(e - a);

    var startToAngle = _normalizeAngle(a - s);

    var endToAngle = _normalizeAngle(a - e);

    return a === s || a === e || sameAngleIsFullCircle && s === e || angleToStart > angleToEnd && startToAngle < endToAngle;
  }

  function _limitValue(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function _int16Range(value) {
    return _limitValue(value, -32768, 32767);
  }

  function _isBetween(value, start, end) {
    var epsilon = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 1e-6;
    return value >= Math.min(start, end) - epsilon && value <= Math.max(start, end) + epsilon;
  }

  function _lookup(table, value, cmp) {
    cmp = cmp || function (index) {
      return table[index] < value;
    };

    var hi = table.length - 1;
    var lo = 0;
    var mid;

    while (hi - lo > 1) {
      mid = lo + hi >> 1;

      if (cmp(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    return {
      lo: lo,
      hi: hi
    };
  }

  var _lookupByKey = function _lookupByKey(table, key, value, last) {
    return _lookup(table, value, last ? function (index) {
      return table[index][key] <= value;
    } : function (index) {
      return table[index][key] < value;
    });
  };

  var _rlookupByKey = function _rlookupByKey(table, key, value) {
    return _lookup(table, value, function (index) {
      return table[index][key] >= value;
    });
  };

  function _filterBetween(values, min, max) {
    var start = 0;
    var end = values.length;

    while (start < end && values[start] < min) {
      start++;
    }

    while (end > start && values[end - 1] > max) {
      end--;
    }

    return start > 0 || end < values.length ? values.slice(start, end) : values;
  }

  var arrayEvents = ['push', 'pop', 'shift', 'splice', 'unshift'];

  function listenArrayEvents(array, listener) {
    if (array._chartjs) {
      array._chartjs.listeners.push(listener);

      return;
    }

    Object.defineProperty(array, '_chartjs', {
      configurable: true,
      enumerable: false,
      value: {
        listeners: [listener]
      }
    });
    arrayEvents.forEach(function (key) {
      var method = '_onData' + _capitalize(key);

      var base = array[key];
      Object.defineProperty(array, key, {
        configurable: true,
        enumerable: false,
        value: function value() {
          for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
            args[_key] = arguments[_key];
          }

          var res = base.apply(this, args);

          array._chartjs.listeners.forEach(function (object) {
            if (typeof object[method] === 'function') {
              object[method].apply(object, args);
            }
          });

          return res;
        }
      });
    });
  }

  function unlistenArrayEvents(array, listener) {
    var stub = array._chartjs;

    if (!stub) {
      return;
    }

    var listeners = stub.listeners;
    var index = listeners.indexOf(listener);

    if (index !== -1) {
      listeners.splice(index, 1);
    }

    if (listeners.length > 0) {
      return;
    }

    arrayEvents.forEach(function (key) {
      delete array[key];
    });
    delete array._chartjs;
  }

  function _arrayUnique(items) {
    var set = new Set();
    var i, ilen;

    for (i = 0, ilen = items.length; i < ilen; ++i) {
      set.add(items[i]);
    }

    if (set.size === ilen) {
      return items;
    }

    return Array.from(set);
  }

  var requestAnimFrame = function () {
    if (typeof window === 'undefined') {
      return function (callback) {
        return callback();
      };
    }

    return window.requestAnimationFrame;
  }();

  function throttled(fn, thisArg, updateFn) {
    var updateArgs = updateFn || function (args) {
      return Array.prototype.slice.call(args);
    };

    var ticking = false;
    var args = [];
    return function () {
      for (var _len2 = arguments.length, rest = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        rest[_key2] = arguments[_key2];
      }

      args = updateArgs(rest);

      if (!ticking) {
        ticking = true;
        requestAnimFrame.call(window, function () {
          ticking = false;
          fn.apply(thisArg, args);
        });
      }
    };
  }

  function debounce(fn, delay) {
    var timeout;
    return function () {
      for (var _len3 = arguments.length, args = new Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
        args[_key3] = arguments[_key3];
      }

      if (delay) {
        clearTimeout(timeout);
        timeout = setTimeout(fn, delay, args);
      } else {
        fn.apply(this, args);
      }

      return delay;
    };
  }

  var _toLeftRightCenter = function _toLeftRightCenter(align) {
    return align === 'start' ? 'left' : align === 'end' ? 'right' : 'center';
  };

  var _alignStartEnd = function _alignStartEnd(align, start, end) {
    return align === 'start' ? start : align === 'end' ? end : (start + end) / 2;
  };

  var _textX = function _textX(align, left, right, rtl) {
    var check = rtl ? 'left' : 'right';
    return align === check ? right : align === 'center' ? (left + right) / 2 : left;
  };

  function _getStartAndCountOfVisiblePoints(meta, points, animationsDisabled) {
    var pointCount = points.length;
    var start = 0;
    var count = pointCount;

    if (meta._sorted) {
      var iScale = meta.iScale,
          _parsed = meta._parsed;
      var axis = iScale.axis;

      var _iScale$getUserBounds = iScale.getUserBounds(),
          min = _iScale$getUserBounds.min,
          max = _iScale$getUserBounds.max,
          minDefined = _iScale$getUserBounds.minDefined,
          maxDefined = _iScale$getUserBounds.maxDefined;

      if (minDefined) {
        start = _limitValue(Math.min(_lookupByKey(_parsed, iScale.axis, min).lo, animationsDisabled ? pointCount : _lookupByKey(points, axis, iScale.getPixelForValue(min)).lo), 0, pointCount - 1);
      }

      if (maxDefined) {
        count = _limitValue(Math.max(_lookupByKey(_parsed, iScale.axis, max, true).hi + 1, animationsDisabled ? 0 : _lookupByKey(points, axis, iScale.getPixelForValue(max), true).hi + 1), start, pointCount) - start;
      } else {
        count = pointCount - start;
      }
    }

    return {
      start: start,
      count: count
    };
  }

  function _scaleRangesChanged(meta) {
    var xScale = meta.xScale,
        yScale = meta.yScale,
        _scaleRanges = meta._scaleRanges;
    var newRanges = {
      xmin: xScale.min,
      xmax: xScale.max,
      ymin: yScale.min,
      ymax: yScale.max
    };

    if (!_scaleRanges) {
      meta._scaleRanges = newRanges;
      return true;
    }

    var changed = _scaleRanges.xmin !== xScale.min || _scaleRanges.xmax !== xScale.max || _scaleRanges.ymin !== yScale.min || _scaleRanges.ymax !== yScale.max;
    Object.assign(_scaleRanges, newRanges);
    return changed;
  }

  var atEdge = function atEdge(t) {
    return t === 0 || t === 1;
  };

  var elasticIn = function elasticIn(t, s, p) {
    return -(Math.pow(2, 10 * (t -= 1)) * Math.sin((t - s) * TAU / p));
  };

  var elasticOut = function elasticOut(t, s, p) {
    return Math.pow(2, -10 * t) * Math.sin((t - s) * TAU / p) + 1;
  };

  var effects = {
    linear: function linear(t) {
      return t;
    },
    easeInQuad: function easeInQuad(t) {
      return t * t;
    },
    easeOutQuad: function easeOutQuad(t) {
      return -t * (t - 2);
    },
    easeInOutQuad: function easeInOutQuad(t) {
      return (t /= 0.5) < 1 ? 0.5 * t * t : -0.5 * (--t * (t - 2) - 1);
    },
    easeInCubic: function easeInCubic(t) {
      return t * t * t;
    },
    easeOutCubic: function easeOutCubic(t) {
      return (t -= 1) * t * t + 1;
    },
    easeInOutCubic: function easeInOutCubic(t) {
      return (t /= 0.5) < 1 ? 0.5 * t * t * t : 0.5 * ((t -= 2) * t * t + 2);
    },
    easeInQuart: function easeInQuart(t) {
      return t * t * t * t;
    },
    easeOutQuart: function easeOutQuart(t) {
      return -((t -= 1) * t * t * t - 1);
    },
    easeInOutQuart: function easeInOutQuart(t) {
      return (t /= 0.5) < 1 ? 0.5 * t * t * t * t : -0.5 * ((t -= 2) * t * t * t - 2);
    },
    easeInQuint: function easeInQuint(t) {
      return t * t * t * t * t;
    },
    easeOutQuint: function easeOutQuint(t) {
      return (t -= 1) * t * t * t * t + 1;
    },
    easeInOutQuint: function easeInOutQuint(t) {
      return (t /= 0.5) < 1 ? 0.5 * t * t * t * t * t : 0.5 * ((t -= 2) * t * t * t * t + 2);
    },
    easeInSine: function easeInSine(t) {
      return -Math.cos(t * HALF_PI) + 1;
    },
    easeOutSine: function easeOutSine(t) {
      return Math.sin(t * HALF_PI);
    },
    easeInOutSine: function easeInOutSine(t) {
      return -0.5 * (Math.cos(PI * t) - 1);
    },
    easeInExpo: function easeInExpo(t) {
      return t === 0 ? 0 : Math.pow(2, 10 * (t - 1));
    },
    easeOutExpo: function easeOutExpo(t) {
      return t === 1 ? 1 : -Math.pow(2, -10 * t) + 1;
    },
    easeInOutExpo: function easeInOutExpo(t) {
      return atEdge(t) ? t : t < 0.5 ? 0.5 * Math.pow(2, 10 * (t * 2 - 1)) : 0.5 * (-Math.pow(2, -10 * (t * 2 - 1)) + 2);
    },
    easeInCirc: function easeInCirc(t) {
      return t >= 1 ? t : -(Math.sqrt(1 - t * t) - 1);
    },
    easeOutCirc: function easeOutCirc(t) {
      return Math.sqrt(1 - (t -= 1) * t);
    },
    easeInOutCirc: function easeInOutCirc(t) {
      return (t /= 0.5) < 1 ? -0.5 * (Math.sqrt(1 - t * t) - 1) : 0.5 * (Math.sqrt(1 - (t -= 2) * t) + 1);
    },
    easeInElastic: function easeInElastic(t) {
      return atEdge(t) ? t : elasticIn(t, 0.075, 0.3);
    },
    easeOutElastic: function easeOutElastic(t) {
      return atEdge(t) ? t : elasticOut(t, 0.075, 0.3);
    },
    easeInOutElastic: function easeInOutElastic(t) {
      var s = 0.1125;
      var p = 0.45;
      return atEdge(t) ? t : t < 0.5 ? 0.5 * elasticIn(t * 2, s, p) : 0.5 + 0.5 * elasticOut(t * 2 - 1, s, p);
    },
    easeInBack: function easeInBack(t) {
      var s = 1.70158;
      return t * t * ((s + 1) * t - s);
    },
    easeOutBack: function easeOutBack(t) {
      var s = 1.70158;
      return (t -= 1) * t * ((s + 1) * t + s) + 1;
    },
    easeInOutBack: function easeInOutBack(t) {
      var s = 1.70158;

      if ((t /= 0.5) < 1) {
        return 0.5 * (t * t * (((s *= 1.525) + 1) * t - s));
      }

      return 0.5 * ((t -= 2) * t * (((s *= 1.525) + 1) * t + s) + 2);
    },
    easeInBounce: function easeInBounce(t) {
      return 1 - effects.easeOutBounce(1 - t);
    },
    easeOutBounce: function easeOutBounce(t) {
      var m = 7.5625;
      var d = 2.75;

      if (t < 1 / d) {
        return m * t * t;
      }

      if (t < 2 / d) {
        return m * (t -= 1.5 / d) * t + 0.75;
      }

      if (t < 2.5 / d) {
        return m * (t -= 2.25 / d) * t + 0.9375;
      }

      return m * (t -= 2.625 / d) * t + 0.984375;
    },
    easeInOutBounce: function easeInOutBounce(t) {
      return t < 0.5 ? effects.easeInBounce(t * 2) * 0.5 : effects.easeOutBounce(t * 2 - 1) * 0.5 + 0.5;
    }
  };
  /*!
   * @kurkle/color v0.2.1
   * https://github.com/kurkle/color#readme
   * (c) 2022 Jukka Kurkela
   * Released under the MIT License
   */

  function round(v) {
    return v + 0.5 | 0;
  }

  var lim = function lim(v, l, h) {
    return Math.max(Math.min(v, h), l);
  };

  function p2b(v) {
    return lim(round(v * 2.55), 0, 255);
  }

  function n2b(v) {
    return lim(round(v * 255), 0, 255);
  }

  function b2n(v) {
    return lim(round(v / 2.55) / 100, 0, 1);
  }

  function n2p(v) {
    return lim(round(v * 100), 0, 100);
  }

  var map$1 = {
    0: 0,
    1: 1,
    2: 2,
    3: 3,
    4: 4,
    5: 5,
    6: 6,
    7: 7,
    8: 8,
    9: 9,
    A: 10,
    B: 11,
    C: 12,
    D: 13,
    E: 14,
    F: 15,
    a: 10,
    b: 11,
    c: 12,
    d: 13,
    e: 14,
    f: 15
  };

  var hex = _toConsumableArray('0123456789ABCDEF');

  var h1 = function h1(b) {
    return hex[b & 0xF];
  };

  var h2 = function h2(b) {
    return hex[(b & 0xF0) >> 4] + hex[b & 0xF];
  };

  var eq = function eq(b) {
    return (b & 0xF0) >> 4 === (b & 0xF);
  };

  var isShort = function isShort(v) {
    return eq(v.r) && eq(v.g) && eq(v.b) && eq(v.a);
  };

  function hexParse(str) {
    var len = str.length;
    var ret;

    if (str[0] === '#') {
      if (len === 4 || len === 5) {
        ret = {
          r: 255 & map$1[str[1]] * 17,
          g: 255 & map$1[str[2]] * 17,
          b: 255 & map$1[str[3]] * 17,
          a: len === 5 ? map$1[str[4]] * 17 : 255
        };
      } else if (len === 7 || len === 9) {
        ret = {
          r: map$1[str[1]] << 4 | map$1[str[2]],
          g: map$1[str[3]] << 4 | map$1[str[4]],
          b: map$1[str[5]] << 4 | map$1[str[6]],
          a: len === 9 ? map$1[str[7]] << 4 | map$1[str[8]] : 255
        };
      }
    }

    return ret;
  }

  var alpha = function alpha(a, f) {
    return a < 255 ? f(a) : '';
  };

  function _hexString(v) {
    var f = isShort(v) ? h1 : h2;
    return v ? '#' + f(v.r) + f(v.g) + f(v.b) + alpha(v.a, f) : undefined;
  }

  var HUE_RE = /^(hsla?|hwb|hsv)\(\s*([-+.e\d]+)(?:deg)?[\s,]+([-+.e\d]+)%[\s,]+([-+.e\d]+)%(?:[\s,]+([-+.e\d]+)(%)?)?\s*\)$/;

  function hsl2rgbn(h, s, l) {
    var a = s * Math.min(l, 1 - l);

    var f = function f(n) {
      var k = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : (n + h / 30) % 12;
      return l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
    };

    return [f(0), f(8), f(4)];
  }

  function hsv2rgbn(h, s, v) {
    var f = function f(n) {
      var k = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : (n + h / 60) % 6;
      return v - v * s * Math.max(Math.min(k, 4 - k, 1), 0);
    };

    return [f(5), f(3), f(1)];
  }

  function hwb2rgbn(h, w, b) {
    var rgb = hsl2rgbn(h, 1, 0.5);
    var i;

    if (w + b > 1) {
      i = 1 / (w + b);
      w *= i;
      b *= i;
    }

    for (i = 0; i < 3; i++) {
      rgb[i] *= 1 - w - b;
      rgb[i] += w;
    }

    return rgb;
  }

  function hueValue(r, g, b, d, max) {
    if (r === max) {
      return (g - b) / d + (g < b ? 6 : 0);
    }

    if (g === max) {
      return (b - r) / d + 2;
    }

    return (r - g) / d + 4;
  }

  function rgb2hsl(v) {
    var range = 255;
    var r = v.r / range;
    var g = v.g / range;
    var b = v.b / range;
    var max = Math.max(r, g, b);
    var min = Math.min(r, g, b);
    var l = (max + min) / 2;
    var h, s, d;

    if (max !== min) {
      d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      h = hueValue(r, g, b, d, max);
      h = h * 60 + 0.5;
    }

    return [h | 0, s || 0, l];
  }

  function calln(f, a, b, c) {
    return (Array.isArray(a) ? f(a[0], a[1], a[2]) : f(a, b, c)).map(n2b);
  }

  function hsl2rgb(h, s, l) {
    return calln(hsl2rgbn, h, s, l);
  }

  function hwb2rgb(h, w, b) {
    return calln(hwb2rgbn, h, w, b);
  }

  function hsv2rgb(h, s, v) {
    return calln(hsv2rgbn, h, s, v);
  }

  function hue(h) {
    return (h % 360 + 360) % 360;
  }

  function hueParse(str) {
    var m = HUE_RE.exec(str);
    var a = 255;
    var v;

    if (!m) {
      return;
    }

    if (m[5] !== v) {
      a = m[6] ? p2b(+m[5]) : n2b(+m[5]);
    }

    var h = hue(+m[2]);
    var p1 = +m[3] / 100;
    var p2 = +m[4] / 100;

    if (m[1] === 'hwb') {
      v = hwb2rgb(h, p1, p2);
    } else if (m[1] === 'hsv') {
      v = hsv2rgb(h, p1, p2);
    } else {
      v = hsl2rgb(h, p1, p2);
    }

    return {
      r: v[0],
      g: v[1],
      b: v[2],
      a: a
    };
  }

  function _rotate(v, deg) {
    var h = rgb2hsl(v);
    h[0] = hue(h[0] + deg);
    h = hsl2rgb(h);
    v.r = h[0];
    v.g = h[1];
    v.b = h[2];
  }

  function _hslString(v) {
    if (!v) {
      return;
    }

    var a = rgb2hsl(v);
    var h = a[0];
    var s = n2p(a[1]);
    var l = n2p(a[2]);
    return v.a < 255 ? "hsla(".concat(h, ", ").concat(s, "%, ").concat(l, "%, ").concat(b2n(v.a), ")") : "hsl(".concat(h, ", ").concat(s, "%, ").concat(l, "%)");
  }

  var map$2 = {
    x: 'dark',
    Z: 'light',
    Y: 're',
    X: 'blu',
    W: 'gr',
    V: 'medium',
    U: 'slate',
    A: 'ee',
    T: 'ol',
    S: 'or',
    B: 'ra',
    C: 'lateg',
    D: 'ights',
    R: 'in',
    Q: 'turquois',
    E: 'hi',
    P: 'ro',
    O: 'al',
    N: 'le',
    M: 'de',
    L: 'yello',
    F: 'en',
    K: 'ch',
    G: 'arks',
    H: 'ea',
    I: 'ightg',
    J: 'wh'
  };
  var names$1 = {
    OiceXe: 'f0f8ff',
    antiquewEte: 'faebd7',
    aqua: 'ffff',
    aquamarRe: '7fffd4',
    azuY: 'f0ffff',
    beige: 'f5f5dc',
    bisque: 'ffe4c4',
    black: '0',
    blanKedOmond: 'ffebcd',
    Xe: 'ff',
    XeviTet: '8a2be2',
    bPwn: 'a52a2a',
    burlywood: 'deb887',
    caMtXe: '5f9ea0',
    KartYuse: '7fff00',
    KocTate: 'd2691e',
    cSO: 'ff7f50',
    cSnflowerXe: '6495ed',
    cSnsilk: 'fff8dc',
    crimson: 'dc143c',
    cyan: 'ffff',
    xXe: '8b',
    xcyan: '8b8b',
    xgTMnPd: 'b8860b',
    xWay: 'a9a9a9',
    xgYF: '6400',
    xgYy: 'a9a9a9',
    xkhaki: 'bdb76b',
    xmagFta: '8b008b',
    xTivegYF: '556b2f',
    xSange: 'ff8c00',
    xScEd: '9932cc',
    xYd: '8b0000',
    xsOmon: 'e9967a',
    xsHgYF: '8fbc8f',
    xUXe: '483d8b',
    xUWay: '2f4f4f',
    xUgYy: '2f4f4f',
    xQe: 'ced1',
    xviTet: '9400d3',
    dAppRk: 'ff1493',
    dApskyXe: 'bfff',
    dimWay: '696969',
    dimgYy: '696969',
    dodgerXe: '1e90ff',
    fiYbrick: 'b22222',
    flSOwEte: 'fffaf0',
    foYstWAn: '228b22',
    fuKsia: 'ff00ff',
    gaRsbSo: 'dcdcdc',
    ghostwEte: 'f8f8ff',
    gTd: 'ffd700',
    gTMnPd: 'daa520',
    Way: '808080',
    gYF: '8000',
    gYFLw: 'adff2f',
    gYy: '808080',
    honeyMw: 'f0fff0',
    hotpRk: 'ff69b4',
    RdianYd: 'cd5c5c',
    Rdigo: '4b0082',
    ivSy: 'fffff0',
    khaki: 'f0e68c',
    lavFMr: 'e6e6fa',
    lavFMrXsh: 'fff0f5',
    lawngYF: '7cfc00',
    NmoncEffon: 'fffacd',
    ZXe: 'add8e6',
    ZcSO: 'f08080',
    Zcyan: 'e0ffff',
    ZgTMnPdLw: 'fafad2',
    ZWay: 'd3d3d3',
    ZgYF: '90ee90',
    ZgYy: 'd3d3d3',
    ZpRk: 'ffb6c1',
    ZsOmon: 'ffa07a',
    ZsHgYF: '20b2aa',
    ZskyXe: '87cefa',
    ZUWay: '778899',
    ZUgYy: '778899',
    ZstAlXe: 'b0c4de',
    ZLw: 'ffffe0',
    lime: 'ff00',
    limegYF: '32cd32',
    lRF: 'faf0e6',
    magFta: 'ff00ff',
    maPon: '800000',
    VaquamarRe: '66cdaa',
    VXe: 'cd',
    VScEd: 'ba55d3',
    VpurpN: '9370db',
    VsHgYF: '3cb371',
    VUXe: '7b68ee',
    VsprRggYF: 'fa9a',
    VQe: '48d1cc',
    VviTetYd: 'c71585',
    midnightXe: '191970',
    mRtcYam: 'f5fffa',
    mistyPse: 'ffe4e1',
    moccasR: 'ffe4b5',
    navajowEte: 'ffdead',
    navy: '80',
    Tdlace: 'fdf5e6',
    Tive: '808000',
    TivedBb: '6b8e23',
    Sange: 'ffa500',
    SangeYd: 'ff4500',
    ScEd: 'da70d6',
    pOegTMnPd: 'eee8aa',
    pOegYF: '98fb98',
    pOeQe: 'afeeee',
    pOeviTetYd: 'db7093',
    papayawEp: 'ffefd5',
    pHKpuff: 'ffdab9',
    peru: 'cd853f',
    pRk: 'ffc0cb',
    plum: 'dda0dd',
    powMrXe: 'b0e0e6',
    purpN: '800080',
    YbeccapurpN: '663399',
    Yd: 'ff0000',
    Psybrown: 'bc8f8f',
    PyOXe: '4169e1',
    saddNbPwn: '8b4513',
    sOmon: 'fa8072',
    sandybPwn: 'f4a460',
    sHgYF: '2e8b57',
    sHshell: 'fff5ee',
    siFna: 'a0522d',
    silver: 'c0c0c0',
    skyXe: '87ceeb',
    UXe: '6a5acd',
    UWay: '708090',
    UgYy: '708090',
    snow: 'fffafa',
    sprRggYF: 'ff7f',
    stAlXe: '4682b4',
    tan: 'd2b48c',
    teO: '8080',
    tEstN: 'd8bfd8',
    tomato: 'ff6347',
    Qe: '40e0d0',
    viTet: 'ee82ee',
    JHt: 'f5deb3',
    wEte: 'ffffff',
    wEtesmoke: 'f5f5f5',
    Lw: 'ffff00',
    LwgYF: '9acd32'
  };

  function unpack() {
    var unpacked = {};
    var keys = Object.keys(names$1);
    var tkeys = Object.keys(map$2);
    var i, j, k, ok, nk;

    for (i = 0; i < keys.length; i++) {
      ok = nk = keys[i];

      for (j = 0; j < tkeys.length; j++) {
        k = tkeys[j];
        nk = nk.replace(k, map$2[k]);
      }

      k = parseInt(names$1[ok], 16);
      unpacked[nk] = [k >> 16 & 0xFF, k >> 8 & 0xFF, k & 0xFF];
    }

    return unpacked;
  }

  var names;

  function nameParse(str) {
    if (!names) {
      names = unpack();
      names.transparent = [0, 0, 0, 0];
    }

    var a = names[str.toLowerCase()];
    return a && {
      r: a[0],
      g: a[1],
      b: a[2],
      a: a.length === 4 ? a[3] : 255
    };
  }

  var RGB_RE = /^rgba?\(\s*([-+.\d]+)(%)?[\s,]+([-+.e\d]+)(%)?[\s,]+([-+.e\d]+)(%)?(?:[\s,/]+([-+.e\d]+)(%)?)?\s*\)$/;

  function rgbParse(str) {
    var m = RGB_RE.exec(str);
    var a = 255;
    var r, g, b;

    if (!m) {
      return;
    }

    if (m[7] !== r) {
      var v = +m[7];
      a = m[8] ? p2b(v) : lim(v * 255, 0, 255);
    }

    r = +m[1];
    g = +m[3];
    b = +m[5];
    r = 255 & (m[2] ? p2b(r) : lim(r, 0, 255));
    g = 255 & (m[4] ? p2b(g) : lim(g, 0, 255));
    b = 255 & (m[6] ? p2b(b) : lim(b, 0, 255));
    return {
      r: r,
      g: g,
      b: b,
      a: a
    };
  }

  function _rgbString(v) {
    return v && (v.a < 255 ? "rgba(".concat(v.r, ", ").concat(v.g, ", ").concat(v.b, ", ").concat(b2n(v.a), ")") : "rgb(".concat(v.r, ", ").concat(v.g, ", ").concat(v.b, ")"));
  }

  var to = function to(v) {
    return v <= 0.0031308 ? v * 12.92 : Math.pow(v, 1.0 / 2.4) * 1.055 - 0.055;
  };

  var from = function from(v) {
    return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };

  function _interpolate(rgb1, rgb2, t) {
    var r = from(b2n(rgb1.r));
    var g = from(b2n(rgb1.g));
    var b = from(b2n(rgb1.b));
    return {
      r: n2b(to(r + t * (from(b2n(rgb2.r)) - r))),
      g: n2b(to(g + t * (from(b2n(rgb2.g)) - g))),
      b: n2b(to(b + t * (from(b2n(rgb2.b)) - b))),
      a: rgb1.a + t * (rgb2.a - rgb1.a)
    };
  }

  function modHSL(v, i, ratio) {
    if (v) {
      var tmp = rgb2hsl(v);
      tmp[i] = Math.max(0, Math.min(tmp[i] + tmp[i] * ratio, i === 0 ? 360 : 1));
      tmp = hsl2rgb(tmp);
      v.r = tmp[0];
      v.g = tmp[1];
      v.b = tmp[2];
    }
  }

  function clone(v, proto) {
    return v ? Object.assign(proto || {}, v) : v;
  }

  function fromObject(input) {
    var v = {
      r: 0,
      g: 0,
      b: 0,
      a: 255
    };

    if (Array.isArray(input)) {
      if (input.length >= 3) {
        v = {
          r: input[0],
          g: input[1],
          b: input[2],
          a: 255
        };

        if (input.length > 3) {
          v.a = n2b(input[3]);
        }
      }
    } else {
      v = clone(input, {
        r: 0,
        g: 0,
        b: 0,
        a: 1
      });
      v.a = n2b(v.a);
    }

    return v;
  }

  function functionParse(str) {
    if (str.charAt(0) === 'r') {
      return rgbParse(str);
    }

    return hueParse(str);
  }

  var Color = /*#__PURE__*/function () {
    function Color(input) {
      _classCallCheck(this, Color);

      if (input instanceof Color) {
        return input;
      }

      var type = _typeof(input);

      var v;

      if (type === 'object') {
        v = fromObject(input);
      } else if (type === 'string') {
        v = hexParse(input) || nameParse(input) || functionParse(input);
      }

      this._rgb = v;
      this._valid = !!v;
    }

    _createClass(Color, [{
      key: "valid",
      get: function get() {
        return this._valid;
      }
    }, {
      key: "rgb",
      get: function get() {
        var v = clone(this._rgb);

        if (v) {
          v.a = b2n(v.a);
        }

        return v;
      },
      set: function set(obj) {
        this._rgb = fromObject(obj);
      }
    }, {
      key: "rgbString",
      value: function rgbString() {
        return this._valid ? _rgbString(this._rgb) : undefined;
      }
    }, {
      key: "hexString",
      value: function hexString() {
        return this._valid ? _hexString(this._rgb) : undefined;
      }
    }, {
      key: "hslString",
      value: function hslString() {
        return this._valid ? _hslString(this._rgb) : undefined;
      }
    }, {
      key: "mix",
      value: function mix(color, weight) {
        if (color) {
          var c1 = this.rgb;
          var c2 = color.rgb;
          var w2;
          var p = weight === w2 ? 0.5 : weight;
          var w = 2 * p - 1;
          var a = c1.a - c2.a;
          var w1 = ((w * a === -1 ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
          w2 = 1 - w1;
          c1.r = 0xFF & w1 * c1.r + w2 * c2.r + 0.5;
          c1.g = 0xFF & w1 * c1.g + w2 * c2.g + 0.5;
          c1.b = 0xFF & w1 * c1.b + w2 * c2.b + 0.5;
          c1.a = p * c1.a + (1 - p) * c2.a;
          this.rgb = c1;
        }

        return this;
      }
    }, {
      key: "interpolate",
      value: function interpolate(color, t) {
        if (color) {
          this._rgb = _interpolate(this._rgb, color._rgb, t);
        }

        return this;
      }
    }, {
      key: "clone",
      value: function clone() {
        return new Color(this.rgb);
      }
    }, {
      key: "alpha",
      value: function alpha(a) {
        this._rgb.a = n2b(a);
        return this;
      }
    }, {
      key: "clearer",
      value: function clearer(ratio) {
        var rgb = this._rgb;
        rgb.a *= 1 - ratio;
        return this;
      }
    }, {
      key: "greyscale",
      value: function greyscale() {
        var rgb = this._rgb;
        var val = round(rgb.r * 0.3 + rgb.g * 0.59 + rgb.b * 0.11);
        rgb.r = rgb.g = rgb.b = val;
        return this;
      }
    }, {
      key: "opaquer",
      value: function opaquer(ratio) {
        var rgb = this._rgb;
        rgb.a *= 1 + ratio;
        return this;
      }
    }, {
      key: "negate",
      value: function negate() {
        var v = this._rgb;
        v.r = 255 - v.r;
        v.g = 255 - v.g;
        v.b = 255 - v.b;
        return this;
      }
    }, {
      key: "lighten",
      value: function lighten(ratio) {
        modHSL(this._rgb, 2, ratio);
        return this;
      }
    }, {
      key: "darken",
      value: function darken(ratio) {
        modHSL(this._rgb, 2, -ratio);
        return this;
      }
    }, {
      key: "saturate",
      value: function saturate(ratio) {
        modHSL(this._rgb, 1, ratio);
        return this;
      }
    }, {
      key: "desaturate",
      value: function desaturate(ratio) {
        modHSL(this._rgb, 1, -ratio);
        return this;
      }
    }, {
      key: "rotate",
      value: function rotate(deg) {
        _rotate(this._rgb, deg);

        return this;
      }
    }]);

    return Color;
  }();

  function index_esm(input) {
    return new Color(input);
  }

  function isPatternOrGradient(value) {
    if (value && _typeof(value) === 'object') {
      var type = value.toString();
      return type === '[object CanvasPattern]' || type === '[object CanvasGradient]';
    }

    return false;
  }

  function color(value) {
    return isPatternOrGradient(value) ? value : index_esm(value);
  }

  function getHoverColor(value) {
    return isPatternOrGradient(value) ? value : index_esm(value).saturate(0.5).darken(0.1).hexString();
  }

  var overrides = Object.create(null);
  var descriptors = Object.create(null);

  function getScope$1(node, key) {
    if (!key) {
      return node;
    }

    var keys = key.split('.');

    for (var i = 0, n = keys.length; i < n; ++i) {
      var k = keys[i];
      node = node[k] || (node[k] = Object.create(null));
    }

    return node;
  }

  function _set(root, scope, values) {
    if (typeof scope === 'string') {
      return merge(getScope$1(root, scope), values);
    }

    return merge(getScope$1(root, ''), scope);
  }

  var Defaults = /*#__PURE__*/function () {
    function Defaults(_descriptors) {
      _classCallCheck(this, Defaults);

      this.animation = undefined;
      this.backgroundColor = 'rgba(0,0,0,0.1)';
      this.borderColor = 'rgba(0,0,0,0.1)';
      this.color = '#666';
      this.datasets = {};

      this.devicePixelRatio = function (context) {
        return context.chart.platform.getDevicePixelRatio();
      };

      this.elements = {};
      this.events = ['mousemove', 'mouseout', 'click', 'touchstart', 'touchmove'];
      this.font = {
        family: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        size: 12,
        style: 'normal',
        lineHeight: 1.2,
        weight: null
      };
      this.hover = {};

      this.hoverBackgroundColor = function (ctx, options) {
        return getHoverColor(options.backgroundColor);
      };

      this.hoverBorderColor = function (ctx, options) {
        return getHoverColor(options.borderColor);
      };

      this.hoverColor = function (ctx, options) {
        return getHoverColor(options.color);
      };

      this.indexAxis = 'x';
      this.interaction = {
        mode: 'nearest',
        intersect: true,
        includeInvisible: false
      };
      this.maintainAspectRatio = true;
      this.onHover = null;
      this.onClick = null;
      this.parsing = true;
      this.plugins = {};
      this.responsive = true;
      this.scale = undefined;
      this.scales = {};
      this.showLine = true;
      this.drawActiveElementsOnTop = true;
      this.describe(_descriptors);
    }

    _createClass(Defaults, [{
      key: "set",
      value: function set(scope, values) {
        return _set(this, scope, values);
      }
    }, {
      key: "get",
      value: function get(scope) {
        return getScope$1(this, scope);
      }
    }, {
      key: "describe",
      value: function describe(scope, values) {
        return _set(descriptors, scope, values);
      }
    }, {
      key: "override",
      value: function override(scope, values) {
        return _set(overrides, scope, values);
      }
    }, {
      key: "route",
      value: function route(scope, name, targetScope, targetName) {
        var _Object$definePropert;

        var scopeObject = getScope$1(this, scope);
        var targetScopeObject = getScope$1(this, targetScope);
        var privateName = '_' + name;
        Object.defineProperties(scopeObject, (_Object$definePropert = {}, _defineProperty$x(_Object$definePropert, privateName, {
          value: scopeObject[name],
          writable: true
        }), _defineProperty$x(_Object$definePropert, name, {
          enumerable: true,
          get: function get() {
            var local = this[privateName];
            var target = targetScopeObject[targetName];

            if (isObject(local)) {
              return Object.assign({}, target, local);
            }

            return valueOrDefault(local, target);
          },
          set: function set(value) {
            this[privateName] = value;
          }
        }), _Object$definePropert));
      }
    }]);

    return Defaults;
  }();

  var defaults = new Defaults({
    _scriptable: function _scriptable(name) {
      return !name.startsWith('on');
    },
    _indexable: function _indexable(name) {
      return name !== 'events';
    },
    hover: {
      _fallback: 'interaction'
    },
    interaction: {
      _scriptable: false,
      _indexable: false
    }
  });

  function toFontString(font) {
    if (!font || isNullOrUndef(font.size) || isNullOrUndef(font.family)) {
      return null;
    }

    return (font.style ? font.style + ' ' : '') + (font.weight ? font.weight + ' ' : '') + font.size + 'px ' + font.family;
  }

  function _measureText(ctx, data, gc, longest, string) {
    var textWidth = data[string];

    if (!textWidth) {
      textWidth = data[string] = ctx.measureText(string).width;
      gc.push(string);
    }

    if (textWidth > longest) {
      longest = textWidth;
    }

    return longest;
  }

  function _longestText(ctx, font, arrayOfThings, cache) {
    cache = cache || {};
    var data = cache.data = cache.data || {};
    var gc = cache.garbageCollect = cache.garbageCollect || [];

    if (cache.font !== font) {
      data = cache.data = {};
      gc = cache.garbageCollect = [];
      cache.font = font;
    }

    ctx.save();
    ctx.font = font;
    var longest = 0;
    var ilen = arrayOfThings.length;
    var i, j, jlen, thing, nestedThing;

    for (i = 0; i < ilen; i++) {
      thing = arrayOfThings[i];

      if (thing !== undefined && thing !== null && isArray(thing) !== true) {
        longest = _measureText(ctx, data, gc, longest, thing);
      } else if (isArray(thing)) {
        for (j = 0, jlen = thing.length; j < jlen; j++) {
          nestedThing = thing[j];

          if (nestedThing !== undefined && nestedThing !== null && !isArray(nestedThing)) {
            longest = _measureText(ctx, data, gc, longest, nestedThing);
          }
        }
      }
    }

    ctx.restore();
    var gcLen = gc.length / 2;

    if (gcLen > arrayOfThings.length) {
      for (i = 0; i < gcLen; i++) {
        delete data[gc[i]];
      }

      gc.splice(0, gcLen);
    }

    return longest;
  }

  function _alignPixel(chart, pixel, width) {
    var devicePixelRatio = chart.currentDevicePixelRatio;
    var halfWidth = width !== 0 ? Math.max(width / 2, 0.5) : 0;
    return Math.round((pixel - halfWidth) * devicePixelRatio) / devicePixelRatio + halfWidth;
  }

  function clearCanvas(canvas, ctx) {
    ctx = ctx || canvas.getContext('2d');
    ctx.save();
    ctx.resetTransform();
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.restore();
  }

  function drawPoint(ctx, options, x, y) {
    drawPointLegend(ctx, options, x, y, null);
  }

  function drawPointLegend(ctx, options, x, y, w) {
    var type, xOffset, yOffset, size, cornerRadius, width;
    var style = options.pointStyle;
    var rotation = options.rotation;
    var radius = options.radius;
    var rad = (rotation || 0) * RAD_PER_DEG;

    if (style && _typeof(style) === 'object') {
      type = style.toString();

      if (type === '[object HTMLImageElement]' || type === '[object HTMLCanvasElement]') {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(rad);
        ctx.drawImage(style, -style.width / 2, -style.height / 2, style.width, style.height);
        ctx.restore();
        return;
      }
    }

    if (isNaN(radius) || radius <= 0) {
      return;
    }

    ctx.beginPath();

    switch (style) {
      default:
        if (w) {
          ctx.ellipse(x, y, w / 2, radius, 0, 0, TAU);
        } else {
          ctx.arc(x, y, radius, 0, TAU);
        }

        ctx.closePath();
        break;

      case 'triangle':
        ctx.moveTo(x + Math.sin(rad) * radius, y - Math.cos(rad) * radius);
        rad += TWO_THIRDS_PI;
        ctx.lineTo(x + Math.sin(rad) * radius, y - Math.cos(rad) * radius);
        rad += TWO_THIRDS_PI;
        ctx.lineTo(x + Math.sin(rad) * radius, y - Math.cos(rad) * radius);
        ctx.closePath();
        break;

      case 'rectRounded':
        cornerRadius = radius * 0.516;
        size = radius - cornerRadius;
        xOffset = Math.cos(rad + QUARTER_PI) * size;
        yOffset = Math.sin(rad + QUARTER_PI) * size;
        ctx.arc(x - xOffset, y - yOffset, cornerRadius, rad - PI, rad - HALF_PI);
        ctx.arc(x + yOffset, y - xOffset, cornerRadius, rad - HALF_PI, rad);
        ctx.arc(x + xOffset, y + yOffset, cornerRadius, rad, rad + HALF_PI);
        ctx.arc(x - yOffset, y + xOffset, cornerRadius, rad + HALF_PI, rad + PI);
        ctx.closePath();
        break;

      case 'rect':
        if (!rotation) {
          size = Math.SQRT1_2 * radius;
          width = w ? w / 2 : size;
          ctx.rect(x - width, y - size, 2 * width, 2 * size);
          break;
        }

        rad += QUARTER_PI;

      case 'rectRot':
        xOffset = Math.cos(rad) * radius;
        yOffset = Math.sin(rad) * radius;
        ctx.moveTo(x - xOffset, y - yOffset);
        ctx.lineTo(x + yOffset, y - xOffset);
        ctx.lineTo(x + xOffset, y + yOffset);
        ctx.lineTo(x - yOffset, y + xOffset);
        ctx.closePath();
        break;

      case 'crossRot':
        rad += QUARTER_PI;

      case 'cross':
        xOffset = Math.cos(rad) * radius;
        yOffset = Math.sin(rad) * radius;
        ctx.moveTo(x - xOffset, y - yOffset);
        ctx.lineTo(x + xOffset, y + yOffset);
        ctx.moveTo(x + yOffset, y - xOffset);
        ctx.lineTo(x - yOffset, y + xOffset);
        break;

      case 'star':
        xOffset = Math.cos(rad) * radius;
        yOffset = Math.sin(rad) * radius;
        ctx.moveTo(x - xOffset, y - yOffset);
        ctx.lineTo(x + xOffset, y + yOffset);
        ctx.moveTo(x + yOffset, y - xOffset);
        ctx.lineTo(x - yOffset, y + xOffset);
        rad += QUARTER_PI;
        xOffset = Math.cos(rad) * radius;
        yOffset = Math.sin(rad) * radius;
        ctx.moveTo(x - xOffset, y - yOffset);
        ctx.lineTo(x + xOffset, y + yOffset);
        ctx.moveTo(x + yOffset, y - xOffset);
        ctx.lineTo(x - yOffset, y + xOffset);
        break;

      case 'line':
        xOffset = w ? w / 2 : Math.cos(rad) * radius;
        yOffset = Math.sin(rad) * radius;
        ctx.moveTo(x - xOffset, y - yOffset);
        ctx.lineTo(x + xOffset, y + yOffset);
        break;

      case 'dash':
        ctx.moveTo(x, y);
        ctx.lineTo(x + Math.cos(rad) * radius, y + Math.sin(rad) * radius);
        break;
    }

    ctx.fill();

    if (options.borderWidth > 0) {
      ctx.stroke();
    }
  }

  function _isPointInArea(point, area, margin) {
    margin = margin || 0.5;
    return !area || point && point.x > area.left - margin && point.x < area.right + margin && point.y > area.top - margin && point.y < area.bottom + margin;
  }

  function clipArea(ctx, area) {
    ctx.save();
    ctx.beginPath();
    ctx.rect(area.left, area.top, area.right - area.left, area.bottom - area.top);
    ctx.clip();
  }

  function unclipArea(ctx) {
    ctx.restore();
  }

  function _steppedLineTo(ctx, previous, target, flip, mode) {
    if (!previous) {
      return ctx.lineTo(target.x, target.y);
    }

    if (mode === 'middle') {
      var midpoint = (previous.x + target.x) / 2.0;
      ctx.lineTo(midpoint, previous.y);
      ctx.lineTo(midpoint, target.y);
    } else if (mode === 'after' !== !!flip) {
      ctx.lineTo(previous.x, target.y);
    } else {
      ctx.lineTo(target.x, previous.y);
    }

    ctx.lineTo(target.x, target.y);
  }

  function _bezierCurveTo(ctx, previous, target, flip) {
    if (!previous) {
      return ctx.lineTo(target.x, target.y);
    }

    ctx.bezierCurveTo(flip ? previous.cp1x : previous.cp2x, flip ? previous.cp1y : previous.cp2y, flip ? target.cp2x : target.cp1x, flip ? target.cp2y : target.cp1y, target.x, target.y);
  }

  function renderText(ctx, text, x, y, font) {
    var opts = arguments.length > 5 && arguments[5] !== undefined ? arguments[5] : {};
    var lines = isArray(text) ? text : [text];
    var stroke = opts.strokeWidth > 0 && opts.strokeColor !== '';
    var i, line;
    ctx.save();
    ctx.font = font.string;
    setRenderOpts(ctx, opts);

    for (i = 0; i < lines.length; ++i) {
      line = lines[i];

      if (stroke) {
        if (opts.strokeColor) {
          ctx.strokeStyle = opts.strokeColor;
        }

        if (!isNullOrUndef(opts.strokeWidth)) {
          ctx.lineWidth = opts.strokeWidth;
        }

        ctx.strokeText(line, x, y, opts.maxWidth);
      }

      ctx.fillText(line, x, y, opts.maxWidth);
      decorateText(ctx, x, y, line, opts);
      y += font.lineHeight;
    }

    ctx.restore();
  }

  function setRenderOpts(ctx, opts) {
    if (opts.translation) {
      ctx.translate(opts.translation[0], opts.translation[1]);
    }

    if (!isNullOrUndef(opts.rotation)) {
      ctx.rotate(opts.rotation);
    }

    if (opts.color) {
      ctx.fillStyle = opts.color;
    }

    if (opts.textAlign) {
      ctx.textAlign = opts.textAlign;
    }

    if (opts.textBaseline) {
      ctx.textBaseline = opts.textBaseline;
    }
  }

  function decorateText(ctx, x, y, line, opts) {
    if (opts.strikethrough || opts.underline) {
      var metrics = ctx.measureText(line);
      var left = x - metrics.actualBoundingBoxLeft;
      var right = x + metrics.actualBoundingBoxRight;
      var top = y - metrics.actualBoundingBoxAscent;
      var bottom = y + metrics.actualBoundingBoxDescent;
      var yDecoration = opts.strikethrough ? (top + bottom) / 2 : bottom;
      ctx.strokeStyle = ctx.fillStyle;
      ctx.beginPath();
      ctx.lineWidth = opts.decorationWidth || 2;
      ctx.moveTo(left, yDecoration);
      ctx.lineTo(right, yDecoration);
      ctx.stroke();
    }
  }

  function addRoundedRectPath(ctx, rect) {
    var x = rect.x,
        y = rect.y,
        w = rect.w,
        h = rect.h,
        radius = rect.radius;
    ctx.arc(x + radius.topLeft, y + radius.topLeft, radius.topLeft, -HALF_PI, PI, true);
    ctx.lineTo(x, y + h - radius.bottomLeft);
    ctx.arc(x + radius.bottomLeft, y + h - radius.bottomLeft, radius.bottomLeft, PI, HALF_PI, true);
    ctx.lineTo(x + w - radius.bottomRight, y + h);
    ctx.arc(x + w - radius.bottomRight, y + h - radius.bottomRight, radius.bottomRight, HALF_PI, 0, true);
    ctx.lineTo(x + w, y + radius.topRight);
    ctx.arc(x + w - radius.topRight, y + radius.topRight, radius.topRight, 0, -HALF_PI, true);
    ctx.lineTo(x + radius.topLeft, y);
  }

  var LINE_HEIGHT = new RegExp(/^(normal|(\d+(?:\.\d+)?)(px|em|%)?)$/);
  var FONT_STYLE = new RegExp(/^(normal|italic|initial|inherit|unset|(oblique( -?[0-9]?[0-9]deg)?))$/);

  function toLineHeight(value, size) {
    var matches = ('' + value).match(LINE_HEIGHT);

    if (!matches || matches[1] === 'normal') {
      return size * 1.2;
    }

    value = +matches[2];

    switch (matches[3]) {
      case 'px':
        return value;

      case '%':
        value /= 100;
        break;
    }

    return size * value;
  }

  var numberOrZero = function numberOrZero(v) {
    return +v || 0;
  };

  function _readValueToProps(value, props) {
    var ret = {};
    var objProps = isObject(props);
    var keys = objProps ? Object.keys(props) : props;
    var read = isObject(value) ? objProps ? function (prop) {
      return valueOrDefault(value[prop], value[props[prop]]);
    } : function (prop) {
      return value[prop];
    } : function () {
      return value;
    };

    var _iterator4 = _createForOfIteratorHelper(keys),
        _step4;

    try {
      for (_iterator4.s(); !(_step4 = _iterator4.n()).done;) {
        var prop = _step4.value;
        ret[prop] = numberOrZero(read(prop));
      }
    } catch (err) {
      _iterator4.e(err);
    } finally {
      _iterator4.f();
    }

    return ret;
  }

  function toTRBL(value) {
    return _readValueToProps(value, {
      top: 'y',
      right: 'x',
      bottom: 'y',
      left: 'x'
    });
  }

  function toTRBLCorners(value) {
    return _readValueToProps(value, ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']);
  }

  function toPadding(value) {
    var obj = toTRBL(value);
    obj.width = obj.left + obj.right;
    obj.height = obj.top + obj.bottom;
    return obj;
  }

  function toFont(options, fallback) {
    options = options || {};
    fallback = fallback || defaults.font;
    var size = valueOrDefault(options.size, fallback.size);

    if (typeof size === 'string') {
      size = parseInt(size, 10);
    }

    var style = valueOrDefault(options.style, fallback.style);

    if (style && !('' + style).match(FONT_STYLE)) {
      console.warn('Invalid font style specified: "' + style + '"');
      style = '';
    }

    var font = {
      family: valueOrDefault(options.family, fallback.family),
      lineHeight: toLineHeight(valueOrDefault(options.lineHeight, fallback.lineHeight), size),
      size: size,
      style: style,
      weight: valueOrDefault(options.weight, fallback.weight),
      string: ''
    };
    font.string = toFontString(font);
    return font;
  }

  function resolve(inputs, context, index, info) {
    var cacheable = true;
    var i, ilen, value;

    for (i = 0, ilen = inputs.length; i < ilen; ++i) {
      value = inputs[i];

      if (value === undefined) {
        continue;
      }

      if (context !== undefined && typeof value === 'function') {
        value = value(context);
        cacheable = false;
      }

      if (index !== undefined && isArray(value)) {
        value = value[index % value.length];
        cacheable = false;
      }

      if (value !== undefined) {
        if (info && !cacheable) {
          info.cacheable = false;
        }

        return value;
      }
    }
  }

  function _addGrace(minmax, grace, beginAtZero) {
    var min = minmax.min,
        max = minmax.max;
    var change = toDimension(grace, (max - min) / 2);

    var keepZero = function keepZero(value, add) {
      return beginAtZero && value === 0 ? 0 : value + add;
    };

    return {
      min: keepZero(min, -Math.abs(change)),
      max: keepZero(max, change)
    };
  }

  function createContext(parentContext, context) {
    return Object.assign(Object.create(parentContext), context);
  }

  function _createResolver(scopes) {
    var _cache;

    var prefixes = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [''];
    var rootScopes = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : scopes;
    var fallback = arguments.length > 3 ? arguments[3] : undefined;
    var getTarget = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : function () {
      return scopes[0];
    };

    if (!defined(fallback)) {
      fallback = _resolve('_fallback', scopes);
    }

    var cache = (_cache = {}, _defineProperty$x(_cache, Symbol.toStringTag, 'Object'), _defineProperty$x(_cache, "_cacheable", true), _defineProperty$x(_cache, "_scopes", scopes), _defineProperty$x(_cache, "_rootScopes", rootScopes), _defineProperty$x(_cache, "_fallback", fallback), _defineProperty$x(_cache, "_getTarget", getTarget), _defineProperty$x(_cache, "override", function override(scope) {
      return _createResolver([scope].concat(_toConsumableArray(scopes)), prefixes, rootScopes, fallback);
    }), _cache);
    return new Proxy(cache, {
      deleteProperty: function deleteProperty(target, prop) {
        delete target[prop];
        delete target._keys;
        delete scopes[0][prop];
        return true;
      },
      get: function get(target, prop) {
        return _cached(target, prop, function () {
          return _resolveWithPrefixes(prop, prefixes, scopes, target);
        });
      },
      getOwnPropertyDescriptor: function getOwnPropertyDescriptor(target, prop) {
        return Reflect.getOwnPropertyDescriptor(target._scopes[0], prop);
      },
      getPrototypeOf: function getPrototypeOf() {
        return Reflect.getPrototypeOf(scopes[0]);
      },
      has: function has(target, prop) {
        return getKeysFromAllScopes(target).includes(prop);
      },
      ownKeys: function ownKeys(target) {
        return getKeysFromAllScopes(target);
      },
      set: function set(target, prop, value) {
        var storage = target._storage || (target._storage = getTarget());
        target[prop] = storage[prop] = value;
        delete target._keys;
        return true;
      }
    });
  }

  function _attachContext(proxy, context, subProxy, descriptorDefaults) {
    var cache = {
      _cacheable: false,
      _proxy: proxy,
      _context: context,
      _subProxy: subProxy,
      _stack: new Set(),
      _descriptors: _descriptors(proxy, descriptorDefaults),
      setContext: function setContext(ctx) {
        return _attachContext(proxy, ctx, subProxy, descriptorDefaults);
      },
      override: function override(scope) {
        return _attachContext(proxy.override(scope), context, subProxy, descriptorDefaults);
      }
    };
    return new Proxy(cache, {
      deleteProperty: function deleteProperty(target, prop) {
        delete target[prop];
        delete proxy[prop];
        return true;
      },
      get: function get(target, prop, receiver) {
        return _cached(target, prop, function () {
          return _resolveWithContext(target, prop, receiver);
        });
      },
      getOwnPropertyDescriptor: function getOwnPropertyDescriptor(target, prop) {
        return target._descriptors.allKeys ? Reflect.has(proxy, prop) ? {
          enumerable: true,
          configurable: true
        } : undefined : Reflect.getOwnPropertyDescriptor(proxy, prop);
      },
      getPrototypeOf: function getPrototypeOf() {
        return Reflect.getPrototypeOf(proxy);
      },
      has: function has(target, prop) {
        return Reflect.has(proxy, prop);
      },
      ownKeys: function ownKeys() {
        return Reflect.ownKeys(proxy);
      },
      set: function set(target, prop, value) {
        proxy[prop] = value;
        delete target[prop];
        return true;
      }
    });
  }

  function _descriptors(proxy) {
    var defaults = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {
      scriptable: true,
      indexable: true
    };

    var _proxy$_scriptable = proxy._scriptable,
        _scriptable = _proxy$_scriptable === void 0 ? defaults.scriptable : _proxy$_scriptable,
        _proxy$_indexable = proxy._indexable,
        _indexable = _proxy$_indexable === void 0 ? defaults.indexable : _proxy$_indexable,
        _proxy$_allKeys = proxy._allKeys,
        _allKeys = _proxy$_allKeys === void 0 ? defaults.allKeys : _proxy$_allKeys;

    return {
      allKeys: _allKeys,
      scriptable: _scriptable,
      indexable: _indexable,
      isScriptable: isFunction(_scriptable) ? _scriptable : function () {
        return _scriptable;
      },
      isIndexable: isFunction(_indexable) ? _indexable : function () {
        return _indexable;
      }
    };
  }

  var readKey = function readKey(prefix, name) {
    return prefix ? prefix + _capitalize(name) : name;
  };

  var needsSubResolver = function needsSubResolver(prop, value) {
    return isObject(value) && prop !== 'adapters' && (Object.getPrototypeOf(value) === null || value.constructor === Object);
  };

  function _cached(target, prop, resolve) {
    if (Object.prototype.hasOwnProperty.call(target, prop)) {
      return target[prop];
    }

    var value = resolve();
    target[prop] = value;
    return value;
  }

  function _resolveWithContext(target, prop, receiver) {
    var _proxy = target._proxy,
        _context = target._context,
        _subProxy = target._subProxy,
        descriptors = target._descriptors;
    var value = _proxy[prop];

    if (isFunction(value) && descriptors.isScriptable(prop)) {
      value = _resolveScriptable(prop, value, target, receiver);
    }

    if (isArray(value) && value.length) {
      value = _resolveArray(prop, value, target, descriptors.isIndexable);
    }

    if (needsSubResolver(prop, value)) {
      value = _attachContext(value, _context, _subProxy && _subProxy[prop], descriptors);
    }

    return value;
  }

  function _resolveScriptable(prop, value, target, receiver) {
    var _proxy = target._proxy,
        _context = target._context,
        _subProxy = target._subProxy,
        _stack = target._stack;

    if (_stack.has(prop)) {
      throw new Error('Recursion detected: ' + Array.from(_stack).join('->') + '->' + prop);
    }

    _stack.add(prop);

    value = value(_context, _subProxy || receiver);

    _stack.delete(prop);

    if (needsSubResolver(prop, value)) {
      value = createSubResolver(_proxy._scopes, _proxy, prop, value);
    }

    return value;
  }

  function _resolveArray(prop, value, target, isIndexable) {
    var _proxy = target._proxy,
        _context = target._context,
        _subProxy = target._subProxy,
        descriptors = target._descriptors;

    if (defined(_context.index) && isIndexable(prop)) {
      value = value[_context.index % value.length];
    } else if (isObject(value[0])) {
      var arr = value;

      var scopes = _proxy._scopes.filter(function (s) {
        return s !== arr;
      });

      value = [];

      var _iterator5 = _createForOfIteratorHelper(arr),
          _step5;

      try {
        for (_iterator5.s(); !(_step5 = _iterator5.n()).done;) {
          var item = _step5.value;
          var resolver = createSubResolver(scopes, _proxy, prop, item);
          value.push(_attachContext(resolver, _context, _subProxy && _subProxy[prop], descriptors));
        }
      } catch (err) {
        _iterator5.e(err);
      } finally {
        _iterator5.f();
      }
    }

    return value;
  }

  function resolveFallback(fallback, prop, value) {
    return isFunction(fallback) ? fallback(prop, value) : fallback;
  }

  var getScope = function getScope(key, parent) {
    return key === true ? parent : typeof key === 'string' ? resolveObjectKey(parent, key) : undefined;
  };

  function addScopes(set, parentScopes, key, parentFallback, value) {
    var _iterator6 = _createForOfIteratorHelper(parentScopes),
        _step6;

    try {
      for (_iterator6.s(); !(_step6 = _iterator6.n()).done;) {
        var parent = _step6.value;
        var scope = getScope(key, parent);

        if (scope) {
          set.add(scope);
          var fallback = resolveFallback(scope._fallback, key, value);

          if (defined(fallback) && fallback !== key && fallback !== parentFallback) {
            return fallback;
          }
        } else if (scope === false && defined(parentFallback) && key !== parentFallback) {
          return null;
        }
      }
    } catch (err) {
      _iterator6.e(err);
    } finally {
      _iterator6.f();
    }

    return false;
  }

  function createSubResolver(parentScopes, resolver, prop, value) {
    var rootScopes = resolver._rootScopes;
    var fallback = resolveFallback(resolver._fallback, prop, value);
    var allScopes = [].concat(_toConsumableArray(parentScopes), _toConsumableArray(rootScopes));
    var set = new Set();
    set.add(value);
    var key = addScopesFromKey(set, allScopes, prop, fallback || prop, value);

    if (key === null) {
      return false;
    }

    if (defined(fallback) && fallback !== prop) {
      key = addScopesFromKey(set, allScopes, fallback, key, value);

      if (key === null) {
        return false;
      }
    }

    return _createResolver(Array.from(set), [''], rootScopes, fallback, function () {
      return subGetTarget(resolver, prop, value);
    });
  }

  function addScopesFromKey(set, allScopes, key, fallback, item) {
    while (key) {
      key = addScopes(set, allScopes, key, fallback, item);
    }

    return key;
  }

  function subGetTarget(resolver, prop, value) {
    var parent = resolver._getTarget();

    if (!(prop in parent)) {
      parent[prop] = {};
    }

    var target = parent[prop];

    if (isArray(target) && isObject(value)) {
      return value;
    }

    return target;
  }

  function _resolveWithPrefixes(prop, prefixes, scopes, proxy) {
    var value;

    var _iterator7 = _createForOfIteratorHelper(prefixes),
        _step7;

    try {
      for (_iterator7.s(); !(_step7 = _iterator7.n()).done;) {
        var prefix = _step7.value;
        value = _resolve(readKey(prefix, prop), scopes);

        if (defined(value)) {
          return needsSubResolver(prop, value) ? createSubResolver(scopes, proxy, prop, value) : value;
        }
      }
    } catch (err) {
      _iterator7.e(err);
    } finally {
      _iterator7.f();
    }
  }

  function _resolve(key, scopes) {
    var _iterator8 = _createForOfIteratorHelper(scopes),
        _step8;

    try {
      for (_iterator8.s(); !(_step8 = _iterator8.n()).done;) {
        var scope = _step8.value;

        if (!scope) {
          continue;
        }

        var value = scope[key];

        if (defined(value)) {
          return value;
        }
      }
    } catch (err) {
      _iterator8.e(err);
    } finally {
      _iterator8.f();
    }
  }

  function getKeysFromAllScopes(target) {
    var keys = target._keys;

    if (!keys) {
      keys = target._keys = resolveKeysFromAllScopes(target._scopes);
    }

    return keys;
  }

  function resolveKeysFromAllScopes(scopes) {
    var set = new Set();

    var _iterator9 = _createForOfIteratorHelper(scopes),
        _step9;

    try {
      for (_iterator9.s(); !(_step9 = _iterator9.n()).done;) {
        var scope = _step9.value;

        var _iterator10 = _createForOfIteratorHelper(Object.keys(scope).filter(function (k) {
          return !k.startsWith('_');
        })),
            _step10;

        try {
          for (_iterator10.s(); !(_step10 = _iterator10.n()).done;) {
            var key = _step10.value;
            set.add(key);
          }
        } catch (err) {
          _iterator10.e(err);
        } finally {
          _iterator10.f();
        }
      }
    } catch (err) {
      _iterator9.e(err);
    } finally {
      _iterator9.f();
    }

    return Array.from(set);
  }

  function _parseObjectDataRadialScale(meta, data, start, count) {
    var iScale = meta.iScale;
    var _this$_parsing$key = this._parsing.key,
        key = _this$_parsing$key === void 0 ? 'r' : _this$_parsing$key;
    var parsed = new Array(count);
    var i, ilen, index, item;

    for (i = 0, ilen = count; i < ilen; ++i) {
      index = i + start;
      item = data[index];
      parsed[i] = {
        r: iScale.parse(resolveObjectKey(item, key), index)
      };
    }

    return parsed;
  }

  var EPSILON = Number.EPSILON || 1e-14;

  var getPoint = function getPoint(points, i) {
    return i < points.length && !points[i].skip && points[i];
  };

  var getValueAxis = function getValueAxis(indexAxis) {
    return indexAxis === 'x' ? 'y' : 'x';
  };

  function splineCurve(firstPoint, middlePoint, afterPoint, t) {
    var previous = firstPoint.skip ? middlePoint : firstPoint;
    var current = middlePoint;
    var next = afterPoint.skip ? middlePoint : afterPoint;
    var d01 = distanceBetweenPoints(current, previous);
    var d12 = distanceBetweenPoints(next, current);
    var s01 = d01 / (d01 + d12);
    var s12 = d12 / (d01 + d12);
    s01 = isNaN(s01) ? 0 : s01;
    s12 = isNaN(s12) ? 0 : s12;
    var fa = t * s01;
    var fb = t * s12;
    return {
      previous: {
        x: current.x - fa * (next.x - previous.x),
        y: current.y - fa * (next.y - previous.y)
      },
      next: {
        x: current.x + fb * (next.x - previous.x),
        y: current.y + fb * (next.y - previous.y)
      }
    };
  }

  function monotoneAdjust(points, deltaK, mK) {
    var pointsLen = points.length;
    var alphaK, betaK, tauK, squaredMagnitude, pointCurrent;
    var pointAfter = getPoint(points, 0);

    for (var i = 0; i < pointsLen - 1; ++i) {
      pointCurrent = pointAfter;
      pointAfter = getPoint(points, i + 1);

      if (!pointCurrent || !pointAfter) {
        continue;
      }

      if (almostEquals(deltaK[i], 0, EPSILON)) {
        mK[i] = mK[i + 1] = 0;
        continue;
      }

      alphaK = mK[i] / deltaK[i];
      betaK = mK[i + 1] / deltaK[i];
      squaredMagnitude = Math.pow(alphaK, 2) + Math.pow(betaK, 2);

      if (squaredMagnitude <= 9) {
        continue;
      }

      tauK = 3 / Math.sqrt(squaredMagnitude);
      mK[i] = alphaK * tauK * deltaK[i];
      mK[i + 1] = betaK * tauK * deltaK[i];
    }
  }

  function monotoneCompute(points, mK) {
    var indexAxis = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 'x';
    var valueAxis = getValueAxis(indexAxis);
    var pointsLen = points.length;
    var delta, pointBefore, pointCurrent;
    var pointAfter = getPoint(points, 0);

    for (var i = 0; i < pointsLen; ++i) {
      pointBefore = pointCurrent;
      pointCurrent = pointAfter;
      pointAfter = getPoint(points, i + 1);

      if (!pointCurrent) {
        continue;
      }

      var iPixel = pointCurrent[indexAxis];
      var vPixel = pointCurrent[valueAxis];

      if (pointBefore) {
        delta = (iPixel - pointBefore[indexAxis]) / 3;
        pointCurrent["cp1".concat(indexAxis)] = iPixel - delta;
        pointCurrent["cp1".concat(valueAxis)] = vPixel - delta * mK[i];
      }

      if (pointAfter) {
        delta = (pointAfter[indexAxis] - iPixel) / 3;
        pointCurrent["cp2".concat(indexAxis)] = iPixel + delta;
        pointCurrent["cp2".concat(valueAxis)] = vPixel + delta * mK[i];
      }
    }
  }

  function splineCurveMonotone(points) {
    var indexAxis = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'x';
    var valueAxis = getValueAxis(indexAxis);
    var pointsLen = points.length;
    var deltaK = Array(pointsLen).fill(0);
    var mK = Array(pointsLen);
    var i, pointBefore, pointCurrent;
    var pointAfter = getPoint(points, 0);

    for (i = 0; i < pointsLen; ++i) {
      pointBefore = pointCurrent;
      pointCurrent = pointAfter;
      pointAfter = getPoint(points, i + 1);

      if (!pointCurrent) {
        continue;
      }

      if (pointAfter) {
        var slopeDelta = pointAfter[indexAxis] - pointCurrent[indexAxis];
        deltaK[i] = slopeDelta !== 0 ? (pointAfter[valueAxis] - pointCurrent[valueAxis]) / slopeDelta : 0;
      }

      mK[i] = !pointBefore ? deltaK[i] : !pointAfter ? deltaK[i - 1] : sign(deltaK[i - 1]) !== sign(deltaK[i]) ? 0 : (deltaK[i - 1] + deltaK[i]) / 2;
    }

    monotoneAdjust(points, deltaK, mK);
    monotoneCompute(points, mK, indexAxis);
  }

  function capControlPoint(pt, min, max) {
    return Math.max(Math.min(pt, max), min);
  }

  function capBezierPoints(points, area) {
    var i, ilen, point, inArea, inAreaPrev;

    var inAreaNext = _isPointInArea(points[0], area);

    for (i = 0, ilen = points.length; i < ilen; ++i) {
      inAreaPrev = inArea;
      inArea = inAreaNext;
      inAreaNext = i < ilen - 1 && _isPointInArea(points[i + 1], area);

      if (!inArea) {
        continue;
      }

      point = points[i];

      if (inAreaPrev) {
        point.cp1x = capControlPoint(point.cp1x, area.left, area.right);
        point.cp1y = capControlPoint(point.cp1y, area.top, area.bottom);
      }

      if (inAreaNext) {
        point.cp2x = capControlPoint(point.cp2x, area.left, area.right);
        point.cp2y = capControlPoint(point.cp2y, area.top, area.bottom);
      }
    }
  }

  function _updateBezierControlPoints(points, options, area, loop, indexAxis) {
    var i, ilen, point, controlPoints;

    if (options.spanGaps) {
      points = points.filter(function (pt) {
        return !pt.skip;
      });
    }

    if (options.cubicInterpolationMode === 'monotone') {
      splineCurveMonotone(points, indexAxis);
    } else {
      var prev = loop ? points[points.length - 1] : points[0];

      for (i = 0, ilen = points.length; i < ilen; ++i) {
        point = points[i];
        controlPoints = splineCurve(prev, point, points[Math.min(i + 1, ilen - (loop ? 0 : 1)) % ilen], options.tension);
        point.cp1x = controlPoints.previous.x;
        point.cp1y = controlPoints.previous.y;
        point.cp2x = controlPoints.next.x;
        point.cp2y = controlPoints.next.y;
        prev = point;
      }
    }

    if (options.capBezierPoints) {
      capBezierPoints(points, area);
    }
  }

  function _isDomSupported() {
    return typeof window !== 'undefined' && typeof document !== 'undefined';
  }

  function _getParentNode(domNode) {
    var parent = domNode.parentNode;

    if (parent && parent.toString() === '[object ShadowRoot]') {
      parent = parent.host;
    }

    return parent;
  }

  function parseMaxStyle(styleValue, node, parentProperty) {
    var valueInPixels;

    if (typeof styleValue === 'string') {
      valueInPixels = parseInt(styleValue, 10);

      if (styleValue.indexOf('%') !== -1) {
        valueInPixels = valueInPixels / 100 * node.parentNode[parentProperty];
      }
    } else {
      valueInPixels = styleValue;
    }

    return valueInPixels;
  }

  var getComputedStyle = function getComputedStyle(element) {
    return window.getComputedStyle(element, null);
  };

  function getStyle(el, property) {
    return getComputedStyle(el).getPropertyValue(property);
  }

  var positions = ['top', 'right', 'bottom', 'left'];

  function getPositionedStyle(styles, style, suffix) {
    var result = {};
    suffix = suffix ? '-' + suffix : '';

    for (var i = 0; i < 4; i++) {
      var pos = positions[i];
      result[pos] = parseFloat(styles[style + '-' + pos + suffix]) || 0;
    }

    result.width = result.left + result.right;
    result.height = result.top + result.bottom;
    return result;
  }

  var useOffsetPos = function useOffsetPos(x, y, target) {
    return (x > 0 || y > 0) && (!target || !target.shadowRoot);
  };

  function getCanvasPosition(e, canvas) {
    var touches = e.touches;
    var source = touches && touches.length ? touches[0] : e;
    var offsetX = source.offsetX,
        offsetY = source.offsetY;
    var box = false;
    var x, y;

    if (useOffsetPos(offsetX, offsetY, e.target)) {
      x = offsetX;
      y = offsetY;
    } else {
      var rect = canvas.getBoundingClientRect();
      x = source.clientX - rect.left;
      y = source.clientY - rect.top;
      box = true;
    }

    return {
      x: x,
      y: y,
      box: box
    };
  }

  function getRelativePosition(evt, chart) {
    if ('native' in evt) {
      return evt;
    }

    var canvas = chart.canvas,
        currentDevicePixelRatio = chart.currentDevicePixelRatio;
    var style = getComputedStyle(canvas);
    var borderBox = style.boxSizing === 'border-box';
    var paddings = getPositionedStyle(style, 'padding');
    var borders = getPositionedStyle(style, 'border', 'width');

    var _getCanvasPosition = getCanvasPosition(evt, canvas),
        x = _getCanvasPosition.x,
        y = _getCanvasPosition.y,
        box = _getCanvasPosition.box;

    var xOffset = paddings.left + (box && borders.left);
    var yOffset = paddings.top + (box && borders.top);
    var width = chart.width,
        height = chart.height;

    if (borderBox) {
      width -= paddings.width + borders.width;
      height -= paddings.height + borders.height;
    }

    return {
      x: Math.round((x - xOffset) / width * canvas.width / currentDevicePixelRatio),
      y: Math.round((y - yOffset) / height * canvas.height / currentDevicePixelRatio)
    };
  }

  function getContainerSize(canvas, width, height) {
    var maxWidth, maxHeight;

    if (width === undefined || height === undefined) {
      var container = _getParentNode(canvas);

      if (!container) {
        width = canvas.clientWidth;
        height = canvas.clientHeight;
      } else {
        var rect = container.getBoundingClientRect();
        var containerStyle = getComputedStyle(container);
        var containerBorder = getPositionedStyle(containerStyle, 'border', 'width');
        var containerPadding = getPositionedStyle(containerStyle, 'padding');
        width = rect.width - containerPadding.width - containerBorder.width;
        height = rect.height - containerPadding.height - containerBorder.height;
        maxWidth = parseMaxStyle(containerStyle.maxWidth, container, 'clientWidth');
        maxHeight = parseMaxStyle(containerStyle.maxHeight, container, 'clientHeight');
      }
    }

    return {
      width: width,
      height: height,
      maxWidth: maxWidth || INFINITY,
      maxHeight: maxHeight || INFINITY
    };
  }

  var round1 = function round1(v) {
    return Math.round(v * 10) / 10;
  };

  function getMaximumSize(canvas, bbWidth, bbHeight, aspectRatio) {
    var style = getComputedStyle(canvas);
    var margins = getPositionedStyle(style, 'margin');
    var maxWidth = parseMaxStyle(style.maxWidth, canvas, 'clientWidth') || INFINITY;
    var maxHeight = parseMaxStyle(style.maxHeight, canvas, 'clientHeight') || INFINITY;
    var containerSize = getContainerSize(canvas, bbWidth, bbHeight);
    var width = containerSize.width,
        height = containerSize.height;

    if (style.boxSizing === 'content-box') {
      var borders = getPositionedStyle(style, 'border', 'width');
      var paddings = getPositionedStyle(style, 'padding');
      width -= paddings.width + borders.width;
      height -= paddings.height + borders.height;
    }

    width = Math.max(0, width - margins.width);
    height = Math.max(0, aspectRatio ? Math.floor(width / aspectRatio) : height - margins.height);
    width = round1(Math.min(width, maxWidth, containerSize.maxWidth));
    height = round1(Math.min(height, maxHeight, containerSize.maxHeight));

    if (width && !height) {
      height = round1(width / 2);
    }

    return {
      width: width,
      height: height
    };
  }

  function retinaScale(chart, forceRatio, forceStyle) {
    var pixelRatio = forceRatio || 1;
    var deviceHeight = Math.floor(chart.height * pixelRatio);
    var deviceWidth = Math.floor(chart.width * pixelRatio);
    chart.height = deviceHeight / pixelRatio;
    chart.width = deviceWidth / pixelRatio;
    var canvas = chart.canvas;

    if (canvas.style && (forceStyle || !canvas.style.height && !canvas.style.width)) {
      canvas.style.height = "".concat(chart.height, "px");
      canvas.style.width = "".concat(chart.width, "px");
    }

    if (chart.currentDevicePixelRatio !== pixelRatio || canvas.height !== deviceHeight || canvas.width !== deviceWidth) {
      chart.currentDevicePixelRatio = pixelRatio;
      canvas.height = deviceHeight;
      canvas.width = deviceWidth;
      chart.ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
      return true;
    }

    return false;
  }

  var supportsEventListenerOptions = function () {
    var passiveSupported = false;

    try {
      var options = {
        get passive() {
          passiveSupported = true;
          return false;
        }

      };
      window.addEventListener('test', null, options);
      window.removeEventListener('test', null, options);
    } catch (e) {}

    return passiveSupported;
  }();

  function readUsedSize(element, property) {
    var value = getStyle(element, property);
    var matches = value && value.match(/^(\d+)(\.\d+)?px$/);
    return matches ? +matches[1] : undefined;
  }

  function _pointInLine(p1, p2, t, mode) {
    return {
      x: p1.x + t * (p2.x - p1.x),
      y: p1.y + t * (p2.y - p1.y)
    };
  }

  function _steppedInterpolation(p1, p2, t, mode) {
    return {
      x: p1.x + t * (p2.x - p1.x),
      y: mode === 'middle' ? t < 0.5 ? p1.y : p2.y : mode === 'after' ? t < 1 ? p1.y : p2.y : t > 0 ? p2.y : p1.y
    };
  }

  function _bezierInterpolation(p1, p2, t, mode) {
    var cp1 = {
      x: p1.cp2x,
      y: p1.cp2y
    };
    var cp2 = {
      x: p2.cp1x,
      y: p2.cp1y
    };

    var a = _pointInLine(p1, cp1, t);

    var b = _pointInLine(cp1, cp2, t);

    var c = _pointInLine(cp2, p2, t);

    var d = _pointInLine(a, b, t);

    var e = _pointInLine(b, c, t);

    return _pointInLine(d, e, t);
  }

  var intlCache = new Map();

  function getNumberFormat(locale, options) {
    options = options || {};
    var cacheKey = locale + JSON.stringify(options);
    var formatter = intlCache.get(cacheKey);

    if (!formatter) {
      formatter = new Intl.NumberFormat(locale, options);
      intlCache.set(cacheKey, formatter);
    }

    return formatter;
  }

  function formatNumber(num, locale, options) {
    return getNumberFormat(locale, options).format(num);
  }

  var getRightToLeftAdapter = function getRightToLeftAdapter(rectX, width) {
    return {
      x: function x(_x) {
        return rectX + rectX + width - _x;
      },
      setWidth: function setWidth(w) {
        width = w;
      },
      textAlign: function textAlign(align) {
        if (align === 'center') {
          return align;
        }

        return align === 'right' ? 'left' : 'right';
      },
      xPlus: function xPlus(x, value) {
        return x - value;
      },
      leftForLtr: function leftForLtr(x, itemWidth) {
        return x - itemWidth;
      }
    };
  };

  var getLeftToRightAdapter = function getLeftToRightAdapter() {
    return {
      x: function x(_x2) {
        return _x2;
      },
      setWidth: function setWidth(w) {},
      textAlign: function textAlign(align) {
        return align;
      },
      xPlus: function xPlus(x, value) {
        return x + value;
      },
      leftForLtr: function leftForLtr(x, _itemWidth) {
        return x;
      }
    };
  };

  function getRtlAdapter(rtl, rectX, width) {
    return rtl ? getRightToLeftAdapter(rectX, width) : getLeftToRightAdapter();
  }

  function overrideTextDirection(ctx, direction) {
    var style, original;

    if (direction === 'ltr' || direction === 'rtl') {
      style = ctx.canvas.style;
      original = [style.getPropertyValue('direction'), style.getPropertyPriority('direction')];
      style.setProperty('direction', direction, 'important');
      ctx.prevTextDirection = original;
    }
  }

  function restoreTextDirection(ctx, original) {
    if (original !== undefined) {
      delete ctx.prevTextDirection;
      ctx.canvas.style.setProperty('direction', original[0], original[1]);
    }
  }

  function propertyFn(property) {
    if (property === 'angle') {
      return {
        between: _angleBetween,
        compare: _angleDiff,
        normalize: _normalizeAngle
      };
    }

    return {
      between: _isBetween,
      compare: function compare(a, b) {
        return a - b;
      },
      normalize: function normalize(x) {
        return x;
      }
    };
  }

  function normalizeSegment(_ref) {
    var start = _ref.start,
        end = _ref.end,
        count = _ref.count,
        loop = _ref.loop,
        style = _ref.style;
    return {
      start: start % count,
      end: end % count,
      loop: loop && (end - start + 1) % count === 0,
      style: style
    };
  }

  function getSegment(segment, points, bounds) {
    var property = bounds.property,
        startBound = bounds.start,
        endBound = bounds.end;

    var _propertyFn = propertyFn(property),
        between = _propertyFn.between,
        normalize = _propertyFn.normalize;

    var count = points.length;
    var start = segment.start,
        end = segment.end,
        loop = segment.loop;
    var i, ilen;

    if (loop) {
      start += count;
      end += count;

      for (i = 0, ilen = count; i < ilen; ++i) {
        if (!between(normalize(points[start % count][property]), startBound, endBound)) {
          break;
        }

        start--;
        end--;
      }

      start %= count;
      end %= count;
    }

    if (end < start) {
      end += count;
    }

    return {
      start: start,
      end: end,
      loop: loop,
      style: segment.style
    };
  }

  function _boundSegment(segment, points, bounds) {
    if (!bounds) {
      return [segment];
    }

    var property = bounds.property,
        startBound = bounds.start,
        endBound = bounds.end;
    var count = points.length;

    var _propertyFn2 = propertyFn(property),
        compare = _propertyFn2.compare,
        between = _propertyFn2.between,
        normalize = _propertyFn2.normalize;

    var _getSegment = getSegment(segment, points, bounds),
        start = _getSegment.start,
        end = _getSegment.end,
        loop = _getSegment.loop,
        style = _getSegment.style;

    var result = [];
    var inside = false;
    var subStart = null;
    var value, point, prevValue;

    var startIsBefore = function startIsBefore() {
      return between(startBound, prevValue, value) && compare(startBound, prevValue) !== 0;
    };

    var endIsBefore = function endIsBefore() {
      return compare(endBound, value) === 0 || between(endBound, prevValue, value);
    };

    var shouldStart = function shouldStart() {
      return inside || startIsBefore();
    };

    var shouldStop = function shouldStop() {
      return !inside || endIsBefore();
    };

    for (var i = start, prev = start; i <= end; ++i) {
      point = points[i % count];

      if (point.skip) {
        continue;
      }

      value = normalize(point[property]);

      if (value === prevValue) {
        continue;
      }

      inside = between(value, startBound, endBound);

      if (subStart === null && shouldStart()) {
        subStart = compare(value, startBound) === 0 ? i : prev;
      }

      if (subStart !== null && shouldStop()) {
        result.push(normalizeSegment({
          start: subStart,
          end: i,
          loop: loop,
          count: count,
          style: style
        }));
        subStart = null;
      }

      prev = i;
      prevValue = value;
    }

    if (subStart !== null) {
      result.push(normalizeSegment({
        start: subStart,
        end: end,
        loop: loop,
        count: count,
        style: style
      }));
    }

    return result;
  }

  function _boundSegments(line, bounds) {
    var result = [];
    var segments = line.segments;

    for (var i = 0; i < segments.length; i++) {
      var sub = _boundSegment(segments[i], line.points, bounds);

      if (sub.length) {
        result.push.apply(result, _toConsumableArray(sub));
      }
    }

    return result;
  }

  function findStartAndEnd(points, count, loop, spanGaps) {
    var start = 0;
    var end = count - 1;

    if (loop && !spanGaps) {
      while (start < count && !points[start].skip) {
        start++;
      }
    }

    while (start < count && points[start].skip) {
      start++;
    }

    start %= count;

    if (loop) {
      end += start;
    }

    while (end > start && points[end % count].skip) {
      end--;
    }

    end %= count;
    return {
      start: start,
      end: end
    };
  }

  function solidSegments(points, start, max, loop) {
    var count = points.length;
    var result = [];
    var last = start;
    var prev = points[start];
    var end;

    for (end = start + 1; end <= max; ++end) {
      var cur = points[end % count];

      if (cur.skip || cur.stop) {
        if (!prev.skip) {
          loop = false;
          result.push({
            start: start % count,
            end: (end - 1) % count,
            loop: loop
          });
          start = last = cur.stop ? end : null;
        }
      } else {
        last = end;

        if (prev.skip) {
          start = end;
        }
      }

      prev = cur;
    }

    if (last !== null) {
      result.push({
        start: start % count,
        end: last % count,
        loop: loop
      });
    }

    return result;
  }

  function _computeSegments(line, segmentOptions) {
    var points = line.points;
    var spanGaps = line.options.spanGaps;
    var count = points.length;

    if (!count) {
      return [];
    }

    var loop = !!line._loop;

    var _findStartAndEnd = findStartAndEnd(points, count, loop, spanGaps),
        start = _findStartAndEnd.start,
        end = _findStartAndEnd.end;

    if (spanGaps === true) {
      return splitByStyles(line, [{
        start: start,
        end: end,
        loop: loop
      }], points, segmentOptions);
    }

    var max = end < start ? end + count : end;
    var completeLoop = !!line._fullLoop && start === 0 && end === count - 1;
    return splitByStyles(line, solidSegments(points, start, max, completeLoop), points, segmentOptions);
  }

  function splitByStyles(line, segments, points, segmentOptions) {
    if (!segmentOptions || !segmentOptions.setContext || !points) {
      return segments;
    }

    return doSplitByStyles(line, segments, points, segmentOptions);
  }

  function doSplitByStyles(line, segments, points, segmentOptions) {
    var chartContext = line._chart.getContext();

    var baseStyle = readStyle(line.options);
    var datasetIndex = line._datasetIndex,
        spanGaps = line.options.spanGaps;
    var count = points.length;
    var result = [];
    var prevStyle = baseStyle;
    var start = segments[0].start;
    var i = start;

    function addStyle(s, e, l, st) {
      var dir = spanGaps ? -1 : 1;

      if (s === e) {
        return;
      }

      s += count;

      while (points[s % count].skip) {
        s -= dir;
      }

      while (points[e % count].skip) {
        e += dir;
      }

      if (s % count !== e % count) {
        result.push({
          start: s % count,
          end: e % count,
          loop: l,
          style: st
        });
        prevStyle = st;
        start = e % count;
      }
    }

    var _iterator11 = _createForOfIteratorHelper(segments),
        _step11;

    try {
      for (_iterator11.s(); !(_step11 = _iterator11.n()).done;) {
        var segment = _step11.value;
        start = spanGaps ? start : segment.start;
        var prev = points[start % count];
        var style = void 0;

        for (i = start + 1; i <= segment.end; i++) {
          var pt = points[i % count];
          style = readStyle(segmentOptions.setContext(createContext(chartContext, {
            type: 'segment',
            p0: prev,
            p1: pt,
            p0DataIndex: (i - 1) % count,
            p1DataIndex: i % count,
            datasetIndex: datasetIndex
          })));

          if (styleChanged(style, prevStyle)) {
            addStyle(start, i - 1, segment.loop, prevStyle);
          }

          prev = pt;
          prevStyle = style;
        }

        if (start < i - 1) {
          addStyle(start, i - 1, segment.loop, prevStyle);
        }
      }
    } catch (err) {
      _iterator11.e(err);
    } finally {
      _iterator11.f();
    }

    return result;
  }

  function readStyle(options) {
    return {
      backgroundColor: options.backgroundColor,
      borderCapStyle: options.borderCapStyle,
      borderDash: options.borderDash,
      borderDashOffset: options.borderDashOffset,
      borderJoinStyle: options.borderJoinStyle,
      borderWidth: options.borderWidth,
      borderColor: options.borderColor
    };
  }

  function styleChanged(style, prevStyle) {
    return prevStyle && JSON.stringify(style) !== JSON.stringify(prevStyle);
  }

  var Animator = /*#__PURE__*/function () {
    function Animator() {
      _classCallCheck(this, Animator);

      this._request = null;
      this._charts = new Map();
      this._running = false;
      this._lastDate = undefined;
    }

    _createClass(Animator, [{
      key: "_notify",
      value: function _notify(chart, anims, date, type) {
        var callbacks = anims.listeners[type];
        var numSteps = anims.duration;
        callbacks.forEach(function (fn) {
          return fn({
            chart: chart,
            initial: anims.initial,
            numSteps: numSteps,
            currentStep: Math.min(date - anims.start, numSteps)
          });
        });
      }
    }, {
      key: "_refresh",
      value: function _refresh() {
        var _this = this;

        if (this._request) {
          return;
        }

        this._running = true;
        this._request = requestAnimFrame.call(window, function () {
          _this._update();

          _this._request = null;

          if (_this._running) {
            _this._refresh();
          }
        });
      }
    }, {
      key: "_update",
      value: function _update() {
        var _this2 = this;

        var date = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : Date.now();
        var remaining = 0;

        this._charts.forEach(function (anims, chart) {
          if (!anims.running || !anims.items.length) {
            return;
          }

          var items = anims.items;
          var i = items.length - 1;
          var draw = false;
          var item;

          for (; i >= 0; --i) {
            item = items[i];

            if (item._active) {
              if (item._total > anims.duration) {
                anims.duration = item._total;
              }

              item.tick(date);
              draw = true;
            } else {
              items[i] = items[items.length - 1];
              items.pop();
            }
          }

          if (draw) {
            chart.draw();

            _this2._notify(chart, anims, date, 'progress');
          }

          if (!items.length) {
            anims.running = false;

            _this2._notify(chart, anims, date, 'complete');

            anims.initial = false;
          }

          remaining += items.length;
        });

        this._lastDate = date;

        if (remaining === 0) {
          this._running = false;
        }
      }
    }, {
      key: "_getAnims",
      value: function _getAnims(chart) {
        var charts = this._charts;
        var anims = charts.get(chart);

        if (!anims) {
          anims = {
            running: false,
            initial: true,
            items: [],
            listeners: {
              complete: [],
              progress: []
            }
          };
          charts.set(chart, anims);
        }

        return anims;
      }
    }, {
      key: "listen",
      value: function listen(chart, event, cb) {
        this._getAnims(chart).listeners[event].push(cb);
      }
    }, {
      key: "add",
      value: function add(chart, items) {
        var _this$_getAnims$items;

        if (!items || !items.length) {
          return;
        }

        (_this$_getAnims$items = this._getAnims(chart).items).push.apply(_this$_getAnims$items, _toConsumableArray(items));
      }
    }, {
      key: "has",
      value: function has(chart) {
        return this._getAnims(chart).items.length > 0;
      }
    }, {
      key: "start",
      value: function start(chart) {
        var anims = this._charts.get(chart);

        if (!anims) {
          return;
        }

        anims.running = true;
        anims.start = Date.now();
        anims.duration = anims.items.reduce(function (acc, cur) {
          return Math.max(acc, cur._duration);
        }, 0);

        this._refresh();
      }
    }, {
      key: "running",
      value: function running(chart) {
        if (!this._running) {
          return false;
        }

        var anims = this._charts.get(chart);

        if (!anims || !anims.running || !anims.items.length) {
          return false;
        }

        return true;
      }
    }, {
      key: "stop",
      value: function stop(chart) {
        var anims = this._charts.get(chart);

        if (!anims || !anims.items.length) {
          return;
        }

        var items = anims.items;
        var i = items.length - 1;

        for (; i >= 0; --i) {
          items[i].cancel();
        }

        anims.items = [];

        this._notify(chart, anims, Date.now(), 'complete');
      }
    }, {
      key: "remove",
      value: function remove(chart) {
        return this._charts.delete(chart);
      }
    }]);

    return Animator;
  }();

  var animator = new Animator();
  var transparent = 'transparent';
  var interpolators = {
    boolean: function boolean(from, to, factor) {
      return factor > 0.5 ? to : from;
    },
    color: function color$1(from, to, factor) {
      var c0 = color(from || transparent);

      var c1 = c0.valid && color(to || transparent);

      return c1 && c1.valid ? c1.mix(c0, factor).hexString() : to;
    },
    number: function number(from, to, factor) {
      return from + (to - from) * factor;
    }
  };

  var Animation = /*#__PURE__*/function () {
    function Animation(cfg, target, prop, to) {
      _classCallCheck(this, Animation);

      var currentValue = target[prop];
      to = resolve([cfg.to, to, currentValue, cfg.from]);
      var from = resolve([cfg.from, currentValue, to]);
      this._active = true;
      this._fn = cfg.fn || interpolators[cfg.type || _typeof(from)];
      this._easing = effects[cfg.easing] || effects.linear;
      this._start = Math.floor(Date.now() + (cfg.delay || 0));
      this._duration = this._total = Math.floor(cfg.duration);
      this._loop = !!cfg.loop;
      this._target = target;
      this._prop = prop;
      this._from = from;
      this._to = to;
      this._promises = undefined;
    }

    _createClass(Animation, [{
      key: "active",
      value: function active() {
        return this._active;
      }
    }, {
      key: "update",
      value: function update(cfg, to, date) {
        if (this._active) {
          this._notify(false);

          var currentValue = this._target[this._prop];
          var elapsed = date - this._start;
          var remain = this._duration - elapsed;
          this._start = date;
          this._duration = Math.floor(Math.max(remain, cfg.duration));
          this._total += elapsed;
          this._loop = !!cfg.loop;
          this._to = resolve([cfg.to, to, currentValue, cfg.from]);
          this._from = resolve([cfg.from, currentValue, to]);
        }
      }
    }, {
      key: "cancel",
      value: function cancel() {
        if (this._active) {
          this.tick(Date.now());
          this._active = false;

          this._notify(false);
        }
      }
    }, {
      key: "tick",
      value: function tick(date) {
        var elapsed = date - this._start;
        var duration = this._duration;
        var prop = this._prop;
        var from = this._from;
        var loop = this._loop;
        var to = this._to;
        var factor;
        this._active = from !== to && (loop || elapsed < duration);

        if (!this._active) {
          this._target[prop] = to;

          this._notify(true);

          return;
        }

        if (elapsed < 0) {
          this._target[prop] = from;
          return;
        }

        factor = elapsed / duration % 2;
        factor = loop && factor > 1 ? 2 - factor : factor;
        factor = this._easing(Math.min(1, Math.max(0, factor)));
        this._target[prop] = this._fn(from, to, factor);
      }
    }, {
      key: "wait",
      value: function wait() {
        var promises = this._promises || (this._promises = []);
        return new Promise(function (res, rej) {
          promises.push({
            res: res,
            rej: rej
          });
        });
      }
    }, {
      key: "_notify",
      value: function _notify(resolved) {
        var method = resolved ? 'res' : 'rej';
        var promises = this._promises || [];

        for (var i = 0; i < promises.length; i++) {
          promises[i][method]();
        }
      }
    }]);

    return Animation;
  }();

  var numbers = ['x', 'y', 'borderWidth', 'radius', 'tension'];
  var colors = ['color', 'borderColor', 'backgroundColor'];
  defaults.set('animation', {
    delay: undefined,
    duration: 1000,
    easing: 'easeOutQuart',
    fn: undefined,
    from: undefined,
    loop: undefined,
    to: undefined,
    type: undefined
  });
  var animationOptions = Object.keys(defaults.animation);
  defaults.describe('animation', {
    _fallback: false,
    _indexable: false,
    _scriptable: function _scriptable(name) {
      return name !== 'onProgress' && name !== 'onComplete' && name !== 'fn';
    }
  });
  defaults.set('animations', {
    colors: {
      type: 'color',
      properties: colors
    },
    numbers: {
      type: 'number',
      properties: numbers
    }
  });
  defaults.describe('animations', {
    _fallback: 'animation'
  });
  defaults.set('transitions', {
    active: {
      animation: {
        duration: 400
      }
    },
    resize: {
      animation: {
        duration: 0
      }
    },
    show: {
      animations: {
        colors: {
          from: 'transparent'
        },
        visible: {
          type: 'boolean',
          duration: 0
        }
      }
    },
    hide: {
      animations: {
        colors: {
          to: 'transparent'
        },
        visible: {
          type: 'boolean',
          easing: 'linear',
          fn: function fn(v) {
            return v | 0;
          }
        }
      }
    }
  });

  var Animations = /*#__PURE__*/function () {
    function Animations(chart, config) {
      _classCallCheck(this, Animations);

      this._chart = chart;
      this._properties = new Map();
      this.configure(config);
    }

    _createClass(Animations, [{
      key: "configure",
      value: function configure(config) {
        if (!isObject(config)) {
          return;
        }

        var animatedProps = this._properties;
        Object.getOwnPropertyNames(config).forEach(function (key) {
          var cfg = config[key];

          if (!isObject(cfg)) {
            return;
          }

          var resolved = {};

          var _iterator = _createForOfIteratorHelper(animationOptions),
              _step;

          try {
            for (_iterator.s(); !(_step = _iterator.n()).done;) {
              var option = _step.value;
              resolved[option] = cfg[option];
            }
          } catch (err) {
            _iterator.e(err);
          } finally {
            _iterator.f();
          }

          (isArray(cfg.properties) && cfg.properties || [key]).forEach(function (prop) {
            if (prop === key || !animatedProps.has(prop)) {
              animatedProps.set(prop, resolved);
            }
          });
        });
      }
    }, {
      key: "_animateOptions",
      value: function _animateOptions(target, values) {
        var newOptions = values.options;
        var options = resolveTargetOptions(target, newOptions);

        if (!options) {
          return [];
        }

        var animations = this._createAnimations(options, newOptions);

        if (newOptions.$shared) {
          awaitAll(target.options.$animations, newOptions).then(function () {
            target.options = newOptions;
          }, function () {});
        }

        return animations;
      }
    }, {
      key: "_createAnimations",
      value: function _createAnimations(target, values) {
        var animatedProps = this._properties;
        var animations = [];
        var running = target.$animations || (target.$animations = {});
        var props = Object.keys(values);
        var date = Date.now();
        var i;

        for (i = props.length - 1; i >= 0; --i) {
          var prop = props[i];

          if (prop.charAt(0) === '$') {
            continue;
          }

          if (prop === 'options') {
            animations.push.apply(animations, _toConsumableArray(this._animateOptions(target, values)));
            continue;
          }

          var value = values[prop];
          var animation = running[prop];
          var cfg = animatedProps.get(prop);

          if (animation) {
            if (cfg && animation.active()) {
              animation.update(cfg, value, date);
              continue;
            } else {
              animation.cancel();
            }
          }

          if (!cfg || !cfg.duration) {
            target[prop] = value;
            continue;
          }

          running[prop] = animation = new Animation(cfg, target, prop, value);
          animations.push(animation);
        }

        return animations;
      }
    }, {
      key: "update",
      value: function update(target, values) {
        if (this._properties.size === 0) {
          Object.assign(target, values);
          return;
        }

        var animations = this._createAnimations(target, values);

        if (animations.length) {
          animator.add(this._chart, animations);
          return true;
        }
      }
    }]);

    return Animations;
  }();

  function awaitAll(animations, properties) {
    var running = [];
    var keys = Object.keys(properties);

    for (var i = 0; i < keys.length; i++) {
      var anim = animations[keys[i]];

      if (anim && anim.active()) {
        running.push(anim.wait());
      }
    }

    return Promise.all(running);
  }

  function resolveTargetOptions(target, newOptions) {
    if (!newOptions) {
      return;
    }

    var options = target.options;

    if (!options) {
      target.options = newOptions;
      return;
    }

    if (options.$shared) {
      target.options = options = Object.assign({}, options, {
        $shared: false,
        $animations: {}
      });
    }

    return options;
  }

  function scaleClip(scale, allowedOverflow) {
    var opts = scale && scale.options || {};
    var reverse = opts.reverse;
    var min = opts.min === undefined ? allowedOverflow : 0;
    var max = opts.max === undefined ? allowedOverflow : 0;
    return {
      start: reverse ? max : min,
      end: reverse ? min : max
    };
  }

  function defaultClip(xScale, yScale, allowedOverflow) {
    if (allowedOverflow === false) {
      return false;
    }

    var x = scaleClip(xScale, allowedOverflow);
    var y = scaleClip(yScale, allowedOverflow);
    return {
      top: y.end,
      right: x.end,
      bottom: y.start,
      left: x.start
    };
  }

  function toClip(value) {
    var t, r, b, l;

    if (isObject(value)) {
      t = value.top;
      r = value.right;
      b = value.bottom;
      l = value.left;
    } else {
      t = r = b = l = value;
    }

    return {
      top: t,
      right: r,
      bottom: b,
      left: l,
      disabled: value === false
    };
  }

  function getSortedDatasetIndices(chart, filterVisible) {
    var keys = [];

    var metasets = chart._getSortedDatasetMetas(filterVisible);

    var i, ilen;

    for (i = 0, ilen = metasets.length; i < ilen; ++i) {
      keys.push(metasets[i].index);
    }

    return keys;
  }

  function _applyStack(stack, value, dsIndex) {
    var options = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {};
    var keys = stack.keys;
    var singleMode = options.mode === 'single';
    var i, ilen, datasetIndex, otherValue;

    if (value === null) {
      return;
    }

    for (i = 0, ilen = keys.length; i < ilen; ++i) {
      datasetIndex = +keys[i];

      if (datasetIndex === dsIndex) {
        if (options.all) {
          continue;
        }

        break;
      }

      otherValue = stack.values[datasetIndex];

      if (isNumberFinite(otherValue) && (singleMode || value === 0 || sign(value) === sign(otherValue))) {
        value += otherValue;
      }
    }

    return value;
  }

  function convertObjectDataToArray(data) {
    var keys = Object.keys(data);
    var adata = new Array(keys.length);
    var i, ilen, key;

    for (i = 0, ilen = keys.length; i < ilen; ++i) {
      key = keys[i];
      adata[i] = {
        x: key,
        y: data[key]
      };
    }

    return adata;
  }

  function isStacked(scale, meta) {
    var stacked = scale && scale.options.stacked;
    return stacked || stacked === undefined && meta.stack !== undefined;
  }

  function getStackKey(indexScale, valueScale, meta) {
    return "".concat(indexScale.id, ".").concat(valueScale.id, ".").concat(meta.stack || meta.type);
  }

  function getUserBounds(scale) {
    var _scale$getUserBounds = scale.getUserBounds(),
        min = _scale$getUserBounds.min,
        max = _scale$getUserBounds.max,
        minDefined = _scale$getUserBounds.minDefined,
        maxDefined = _scale$getUserBounds.maxDefined;

    return {
      min: minDefined ? min : Number.NEGATIVE_INFINITY,
      max: maxDefined ? max : Number.POSITIVE_INFINITY
    };
  }

  function getOrCreateStack(stacks, stackKey, indexValue) {
    var subStack = stacks[stackKey] || (stacks[stackKey] = {});
    return subStack[indexValue] || (subStack[indexValue] = {});
  }

  function getLastIndexInStack(stack, vScale, positive, type) {
    var _iterator2 = _createForOfIteratorHelper(vScale.getMatchingVisibleMetas(type).reverse()),
        _step2;

    try {
      for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
        var meta = _step2.value;
        var value = stack[meta.index];

        if (positive && value > 0 || !positive && value < 0) {
          return meta.index;
        }
      }
    } catch (err) {
      _iterator2.e(err);
    } finally {
      _iterator2.f();
    }

    return null;
  }

  function updateStacks(controller, parsed) {
    var chart = controller.chart,
        meta = controller._cachedMeta;
    var stacks = chart._stacks || (chart._stacks = {});
    var iScale = meta.iScale,
        vScale = meta.vScale,
        datasetIndex = meta.index;
    var iAxis = iScale.axis;
    var vAxis = vScale.axis;
    var key = getStackKey(iScale, vScale, meta);
    var ilen = parsed.length;
    var stack;

    for (var i = 0; i < ilen; ++i) {
      var item = parsed[i];
      var _index = item[iAxis],
          value = item[vAxis];
      var itemStacks = item._stacks || (item._stacks = {});
      stack = itemStacks[vAxis] = getOrCreateStack(stacks, key, _index);
      stack[datasetIndex] = value;
      stack._top = getLastIndexInStack(stack, vScale, true, meta.type);
      stack._bottom = getLastIndexInStack(stack, vScale, false, meta.type);
    }
  }

  function getFirstScaleId(chart, axis) {
    var scales = chart.scales;
    return Object.keys(scales).filter(function (key) {
      return scales[key].axis === axis;
    }).shift();
  }

  function createDatasetContext(parent, index) {
    return createContext(parent, {
      active: false,
      dataset: undefined,
      datasetIndex: index,
      index: index,
      mode: 'default',
      type: 'dataset'
    });
  }

  function createDataContext(parent, index, element) {
    return createContext(parent, {
      active: false,
      dataIndex: index,
      parsed: undefined,
      raw: undefined,
      element: element,
      index: index,
      mode: 'default',
      type: 'data'
    });
  }

  function clearStacks(meta, items) {
    var datasetIndex = meta.controller.index;
    var axis = meta.vScale && meta.vScale.axis;

    if (!axis) {
      return;
    }

    items = items || meta._parsed;

    var _iterator3 = _createForOfIteratorHelper(items),
        _step3;

    try {
      for (_iterator3.s(); !(_step3 = _iterator3.n()).done;) {
        var parsed = _step3.value;
        var stacks = parsed._stacks;

        if (!stacks || stacks[axis] === undefined || stacks[axis][datasetIndex] === undefined) {
          return;
        }

        delete stacks[axis][datasetIndex];
      }
    } catch (err) {
      _iterator3.e(err);
    } finally {
      _iterator3.f();
    }
  }

  var isDirectUpdateMode = function isDirectUpdateMode(mode) {
    return mode === 'reset' || mode === 'none';
  };

  var cloneIfNotShared = function cloneIfNotShared(cached, shared) {
    return shared ? cached : Object.assign({}, cached);
  };

  var createStack = function createStack(canStack, meta, chart) {
    return canStack && !meta.hidden && meta._stacked && {
      keys: getSortedDatasetIndices(chart, true),
      values: null
    };
  };

  var DatasetController = /*#__PURE__*/function () {
    function DatasetController(chart, datasetIndex) {
      _classCallCheck(this, DatasetController);

      this.chart = chart;
      this._ctx = chart.ctx;
      this.index = datasetIndex;
      this._cachedDataOpts = {};
      this._cachedMeta = this.getMeta();
      this._type = this._cachedMeta.type;
      this.options = undefined;
      this._parsing = false;
      this._data = undefined;
      this._objectData = undefined;
      this._sharedOptions = undefined;
      this._drawStart = undefined;
      this._drawCount = undefined;
      this.enableOptionSharing = false;
      this.supportsDecimation = false;
      this.$context = undefined;
      this._syncList = [];
      this.initialize();
    }

    _createClass(DatasetController, [{
      key: "initialize",
      value: function initialize() {
        var meta = this._cachedMeta;
        this.configure();
        this.linkScales();
        meta._stacked = isStacked(meta.vScale, meta);
        this.addElements();
      }
    }, {
      key: "updateIndex",
      value: function updateIndex(datasetIndex) {
        if (this.index !== datasetIndex) {
          clearStacks(this._cachedMeta);
        }

        this.index = datasetIndex;
      }
    }, {
      key: "linkScales",
      value: function linkScales() {
        var chart = this.chart;
        var meta = this._cachedMeta;
        var dataset = this.getDataset();

        var chooseId = function chooseId(axis, x, y, r) {
          return axis === 'x' ? x : axis === 'r' ? r : y;
        };

        var xid = meta.xAxisID = valueOrDefault(dataset.xAxisID, getFirstScaleId(chart, 'x'));
        var yid = meta.yAxisID = valueOrDefault(dataset.yAxisID, getFirstScaleId(chart, 'y'));
        var rid = meta.rAxisID = valueOrDefault(dataset.rAxisID, getFirstScaleId(chart, 'r'));
        var indexAxis = meta.indexAxis;
        var iid = meta.iAxisID = chooseId(indexAxis, xid, yid, rid);
        var vid = meta.vAxisID = chooseId(indexAxis, yid, xid, rid);
        meta.xScale = this.getScaleForId(xid);
        meta.yScale = this.getScaleForId(yid);
        meta.rScale = this.getScaleForId(rid);
        meta.iScale = this.getScaleForId(iid);
        meta.vScale = this.getScaleForId(vid);
      }
    }, {
      key: "getDataset",
      value: function getDataset() {
        return this.chart.data.datasets[this.index];
      }
    }, {
      key: "getMeta",
      value: function getMeta() {
        return this.chart.getDatasetMeta(this.index);
      }
    }, {
      key: "getScaleForId",
      value: function getScaleForId(scaleID) {
        return this.chart.scales[scaleID];
      }
    }, {
      key: "_getOtherScale",
      value: function _getOtherScale(scale) {
        var meta = this._cachedMeta;
        return scale === meta.iScale ? meta.vScale : meta.iScale;
      }
    }, {
      key: "reset",
      value: function reset() {
        this._update('reset');
      }
    }, {
      key: "_destroy",
      value: function _destroy() {
        var meta = this._cachedMeta;

        if (this._data) {
          unlistenArrayEvents(this._data, this);
        }

        if (meta._stacked) {
          clearStacks(meta);
        }
      }
    }, {
      key: "_dataCheck",
      value: function _dataCheck() {
        var dataset = this.getDataset();
        var data = dataset.data || (dataset.data = []);
        var _data = this._data;

        if (isObject(data)) {
          this._data = convertObjectDataToArray(data);
        } else if (_data !== data) {
          if (_data) {
            unlistenArrayEvents(_data, this);
            var meta = this._cachedMeta;
            clearStacks(meta);
            meta._parsed = [];
          }

          if (data && Object.isExtensible(data)) {
            listenArrayEvents(data, this);
          }

          this._syncList = [];
          this._data = data;
        }
      }
    }, {
      key: "addElements",
      value: function addElements() {
        var meta = this._cachedMeta;

        this._dataCheck();

        if (this.datasetElementType) {
          meta.dataset = new this.datasetElementType();
        }
      }
    }, {
      key: "buildOrUpdateElements",
      value: function buildOrUpdateElements(resetNewElements) {
        var meta = this._cachedMeta;
        var dataset = this.getDataset();
        var stackChanged = false;

        this._dataCheck();

        var oldStacked = meta._stacked;
        meta._stacked = isStacked(meta.vScale, meta);

        if (meta.stack !== dataset.stack) {
          stackChanged = true;
          clearStacks(meta);
          meta.stack = dataset.stack;
        }

        this._resyncElements(resetNewElements);

        if (stackChanged || oldStacked !== meta._stacked) {
          updateStacks(this, meta._parsed);
        }
      }
    }, {
      key: "configure",
      value: function configure() {
        var config = this.chart.config;
        var scopeKeys = config.datasetScopeKeys(this._type);
        var scopes = config.getOptionScopes(this.getDataset(), scopeKeys, true);
        this.options = config.createResolver(scopes, this.getContext());
        this._parsing = this.options.parsing;
        this._cachedDataOpts = {};
      }
    }, {
      key: "parse",
      value: function parse(start, count) {
        var meta = this._cachedMeta,
            data = this._data;
        var iScale = meta.iScale,
            _stacked = meta._stacked;
        var iAxis = iScale.axis;
        var sorted = start === 0 && count === data.length ? true : meta._sorted;
        var prev = start > 0 && meta._parsed[start - 1];
        var i, cur, parsed;

        if (this._parsing === false) {
          meta._parsed = data;
          meta._sorted = true;
          parsed = data;
        } else {
          if (isArray(data[start])) {
            parsed = this.parseArrayData(meta, data, start, count);
          } else if (isObject(data[start])) {
            parsed = this.parseObjectData(meta, data, start, count);
          } else {
            parsed = this.parsePrimitiveData(meta, data, start, count);
          }

          var isNotInOrderComparedToPrev = function isNotInOrderComparedToPrev() {
            return cur[iAxis] === null || prev && cur[iAxis] < prev[iAxis];
          };

          for (i = 0; i < count; ++i) {
            meta._parsed[i + start] = cur = parsed[i];

            if (sorted) {
              if (isNotInOrderComparedToPrev()) {
                sorted = false;
              }

              prev = cur;
            }
          }

          meta._sorted = sorted;
        }

        if (_stacked) {
          updateStacks(this, parsed);
        }
      }
    }, {
      key: "parsePrimitiveData",
      value: function parsePrimitiveData(meta, data, start, count) {
        var iScale = meta.iScale,
            vScale = meta.vScale;
        var iAxis = iScale.axis;
        var vAxis = vScale.axis;
        var labels = iScale.getLabels();
        var singleScale = iScale === vScale;
        var parsed = new Array(count);
        var i, ilen, index;

        for (i = 0, ilen = count; i < ilen; ++i) {
          var _parsed$i;

          index = i + start;
          parsed[i] = (_parsed$i = {}, _defineProperty$x(_parsed$i, iAxis, singleScale || iScale.parse(labels[index], index)), _defineProperty$x(_parsed$i, vAxis, vScale.parse(data[index], index)), _parsed$i);
        }

        return parsed;
      }
    }, {
      key: "parseArrayData",
      value: function parseArrayData(meta, data, start, count) {
        var xScale = meta.xScale,
            yScale = meta.yScale;
        var parsed = new Array(count);
        var i, ilen, index, item;

        for (i = 0, ilen = count; i < ilen; ++i) {
          index = i + start;
          item = data[index];
          parsed[i] = {
            x: xScale.parse(item[0], index),
            y: yScale.parse(item[1], index)
          };
        }

        return parsed;
      }
    }, {
      key: "parseObjectData",
      value: function parseObjectData(meta, data, start, count) {
        var xScale = meta.xScale,
            yScale = meta.yScale;
        var _this$_parsing = this._parsing,
            _this$_parsing$xAxisK = _this$_parsing.xAxisKey,
            xAxisKey = _this$_parsing$xAxisK === void 0 ? 'x' : _this$_parsing$xAxisK,
            _this$_parsing$yAxisK = _this$_parsing.yAxisKey,
            yAxisKey = _this$_parsing$yAxisK === void 0 ? 'y' : _this$_parsing$yAxisK;
        var parsed = new Array(count);
        var i, ilen, index, item;

        for (i = 0, ilen = count; i < ilen; ++i) {
          index = i + start;
          item = data[index];
          parsed[i] = {
            x: xScale.parse(resolveObjectKey(item, xAxisKey), index),
            y: yScale.parse(resolveObjectKey(item, yAxisKey), index)
          };
        }

        return parsed;
      }
    }, {
      key: "getParsed",
      value: function getParsed(index) {
        return this._cachedMeta._parsed[index];
      }
    }, {
      key: "getDataElement",
      value: function getDataElement(index) {
        return this._cachedMeta.data[index];
      }
    }, {
      key: "applyStack",
      value: function applyStack(scale, parsed, mode) {
        var chart = this.chart;
        var meta = this._cachedMeta;
        var value = parsed[scale.axis];
        var stack = {
          keys: getSortedDatasetIndices(chart, true),
          values: parsed._stacks[scale.axis]
        };
        return _applyStack(stack, value, meta.index, {
          mode: mode
        });
      }
    }, {
      key: "updateRangeFromParsed",
      value: function updateRangeFromParsed(range, scale, parsed, stack) {
        var parsedValue = parsed[scale.axis];
        var value = parsedValue === null ? NaN : parsedValue;
        var values = stack && parsed._stacks[scale.axis];

        if (stack && values) {
          stack.values = values;
          value = _applyStack(stack, parsedValue, this._cachedMeta.index);
        }

        range.min = Math.min(range.min, value);
        range.max = Math.max(range.max, value);
      }
    }, {
      key: "getMinMax",
      value: function getMinMax(scale, canStack) {
        var meta = this._cachedMeta;
        var _parsed = meta._parsed;
        var sorted = meta._sorted && scale === meta.iScale;
        var ilen = _parsed.length;

        var otherScale = this._getOtherScale(scale);

        var stack = createStack(canStack, meta, this.chart);
        var range = {
          min: Number.POSITIVE_INFINITY,
          max: Number.NEGATIVE_INFINITY
        };

        var _getUserBounds = getUserBounds(otherScale),
            otherMin = _getUserBounds.min,
            otherMax = _getUserBounds.max;

        var i, parsed;

        function _skip() {
          parsed = _parsed[i];
          var otherValue = parsed[otherScale.axis];
          return !isNumberFinite(parsed[scale.axis]) || otherMin > otherValue || otherMax < otherValue;
        }

        for (i = 0; i < ilen; ++i) {
          if (_skip()) {
            continue;
          }

          this.updateRangeFromParsed(range, scale, parsed, stack);

          if (sorted) {
            break;
          }
        }

        if (sorted) {
          for (i = ilen - 1; i >= 0; --i) {
            if (_skip()) {
              continue;
            }

            this.updateRangeFromParsed(range, scale, parsed, stack);
            break;
          }
        }

        return range;
      }
    }, {
      key: "getAllParsedValues",
      value: function getAllParsedValues(scale) {
        var parsed = this._cachedMeta._parsed;
        var values = [];
        var i, ilen, value;

        for (i = 0, ilen = parsed.length; i < ilen; ++i) {
          value = parsed[i][scale.axis];

          if (isNumberFinite(value)) {
            values.push(value);
          }
        }

        return values;
      }
    }, {
      key: "getMaxOverflow",
      value: function getMaxOverflow() {
        return false;
      }
    }, {
      key: "getLabelAndValue",
      value: function getLabelAndValue(index) {
        var meta = this._cachedMeta;
        var iScale = meta.iScale;
        var vScale = meta.vScale;
        var parsed = this.getParsed(index);
        return {
          label: iScale ? '' + iScale.getLabelForValue(parsed[iScale.axis]) : '',
          value: vScale ? '' + vScale.getLabelForValue(parsed[vScale.axis]) : ''
        };
      }
    }, {
      key: "_update",
      value: function _update(mode) {
        var meta = this._cachedMeta;
        this.update(mode || 'default');
        meta._clip = toClip(valueOrDefault(this.options.clip, defaultClip(meta.xScale, meta.yScale, this.getMaxOverflow())));
      }
    }, {
      key: "update",
      value: function update(mode) {}
    }, {
      key: "draw",
      value: function draw() {
        var ctx = this._ctx;
        var chart = this.chart;
        var meta = this._cachedMeta;
        var elements = meta.data || [];
        var area = chart.chartArea;
        var active = [];
        var start = this._drawStart || 0;
        var count = this._drawCount || elements.length - start;
        var drawActiveElementsOnTop = this.options.drawActiveElementsOnTop;
        var i;

        if (meta.dataset) {
          meta.dataset.draw(ctx, area, start, count);
        }

        for (i = start; i < start + count; ++i) {
          var element = elements[i];

          if (element.hidden) {
            continue;
          }

          if (element.active && drawActiveElementsOnTop) {
            active.push(element);
          } else {
            element.draw(ctx, area);
          }
        }

        for (i = 0; i < active.length; ++i) {
          active[i].draw(ctx, area);
        }
      }
    }, {
      key: "getStyle",
      value: function getStyle(index, active) {
        var mode = active ? 'active' : 'default';
        return index === undefined && this._cachedMeta.dataset ? this.resolveDatasetElementOptions(mode) : this.resolveDataElementOptions(index || 0, mode);
      }
    }, {
      key: "getContext",
      value: function getContext(index, active, mode) {
        var dataset = this.getDataset();
        var context;

        if (index >= 0 && index < this._cachedMeta.data.length) {
          var element = this._cachedMeta.data[index];
          context = element.$context || (element.$context = createDataContext(this.getContext(), index, element));
          context.parsed = this.getParsed(index);
          context.raw = dataset.data[index];
          context.index = context.dataIndex = index;
        } else {
          context = this.$context || (this.$context = createDatasetContext(this.chart.getContext(), this.index));
          context.dataset = dataset;
          context.index = context.datasetIndex = this.index;
        }

        context.active = !!active;
        context.mode = mode;
        return context;
      }
    }, {
      key: "resolveDatasetElementOptions",
      value: function resolveDatasetElementOptions(mode) {
        return this._resolveElementOptions(this.datasetElementType.id, mode);
      }
    }, {
      key: "resolveDataElementOptions",
      value: function resolveDataElementOptions(index, mode) {
        return this._resolveElementOptions(this.dataElementType.id, mode, index);
      }
    }, {
      key: "_resolveElementOptions",
      value: function _resolveElementOptions(elementType) {
        var _this3 = this;

        var mode = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'default';
        var index = arguments.length > 2 ? arguments[2] : undefined;
        var active = mode === 'active';
        var cache = this._cachedDataOpts;
        var cacheKey = elementType + '-' + mode;
        var cached = cache[cacheKey];
        var sharing = this.enableOptionSharing && defined(index);

        if (cached) {
          return cloneIfNotShared(cached, sharing);
        }

        var config = this.chart.config;
        var scopeKeys = config.datasetElementScopeKeys(this._type, elementType);
        var prefixes = active ? ["".concat(elementType, "Hover"), 'hover', elementType, ''] : [elementType, ''];
        var scopes = config.getOptionScopes(this.getDataset(), scopeKeys);
        var names = Object.keys(defaults.elements[elementType]);

        var context = function context() {
          return _this3.getContext(index, active);
        };

        var values = config.resolveNamedOptions(scopes, names, context, prefixes);

        if (values.$shared) {
          values.$shared = sharing;
          cache[cacheKey] = Object.freeze(cloneIfNotShared(values, sharing));
        }

        return values;
      }
    }, {
      key: "_resolveAnimations",
      value: function _resolveAnimations(index, transition, active) {
        var chart = this.chart;
        var cache = this._cachedDataOpts;
        var cacheKey = "animation-".concat(transition);
        var cached = cache[cacheKey];

        if (cached) {
          return cached;
        }

        var options;

        if (chart.options.animation !== false) {
          var config = this.chart.config;
          var scopeKeys = config.datasetAnimationScopeKeys(this._type, transition);
          var scopes = config.getOptionScopes(this.getDataset(), scopeKeys);
          options = config.createResolver(scopes, this.getContext(index, active, transition));
        }

        var animations = new Animations(chart, options && options.animations);

        if (options && options._cacheable) {
          cache[cacheKey] = Object.freeze(animations);
        }

        return animations;
      }
    }, {
      key: "getSharedOptions",
      value: function getSharedOptions(options) {
        if (!options.$shared) {
          return;
        }

        return this._sharedOptions || (this._sharedOptions = Object.assign({}, options));
      }
    }, {
      key: "includeOptions",
      value: function includeOptions(mode, sharedOptions) {
        return !sharedOptions || isDirectUpdateMode(mode) || this.chart._animationsDisabled;
      }
    }, {
      key: "_getSharedOptions",
      value: function _getSharedOptions(start, mode) {
        var firstOpts = this.resolveDataElementOptions(start, mode);
        var previouslySharedOptions = this._sharedOptions;
        var sharedOptions = this.getSharedOptions(firstOpts);
        var includeOptions = this.includeOptions(mode, sharedOptions) || sharedOptions !== previouslySharedOptions;
        this.updateSharedOptions(sharedOptions, mode, firstOpts);
        return {
          sharedOptions: sharedOptions,
          includeOptions: includeOptions
        };
      }
    }, {
      key: "updateElement",
      value: function updateElement(element, index, properties, mode) {
        if (isDirectUpdateMode(mode)) {
          Object.assign(element, properties);
        } else {
          this._resolveAnimations(index, mode).update(element, properties);
        }
      }
    }, {
      key: "updateSharedOptions",
      value: function updateSharedOptions(sharedOptions, mode, newOptions) {
        if (sharedOptions && !isDirectUpdateMode(mode)) {
          this._resolveAnimations(undefined, mode).update(sharedOptions, newOptions);
        }
      }
    }, {
      key: "_setStyle",
      value: function _setStyle(element, index, mode, active) {
        element.active = active;
        var options = this.getStyle(index, active);

        this._resolveAnimations(index, mode, active).update(element, {
          options: !active && this.getSharedOptions(options) || options
        });
      }
    }, {
      key: "removeHoverStyle",
      value: function removeHoverStyle(element, datasetIndex, index) {
        this._setStyle(element, index, 'active', false);
      }
    }, {
      key: "setHoverStyle",
      value: function setHoverStyle(element, datasetIndex, index) {
        this._setStyle(element, index, 'active', true);
      }
    }, {
      key: "_removeDatasetHoverStyle",
      value: function _removeDatasetHoverStyle() {
        var element = this._cachedMeta.dataset;

        if (element) {
          this._setStyle(element, undefined, 'active', false);
        }
      }
    }, {
      key: "_setDatasetHoverStyle",
      value: function _setDatasetHoverStyle() {
        var element = this._cachedMeta.dataset;

        if (element) {
          this._setStyle(element, undefined, 'active', true);
        }
      }
    }, {
      key: "_resyncElements",
      value: function _resyncElements(resetNewElements) {
        var data = this._data;
        var elements = this._cachedMeta.data;

        var _iterator4 = _createForOfIteratorHelper(this._syncList),
            _step4;

        try {
          for (_iterator4.s(); !(_step4 = _iterator4.n()).done;) {
            var _step4$value = _slicedToArray(_step4.value, 3),
                method = _step4$value[0],
                arg1 = _step4$value[1],
                arg2 = _step4$value[2];

            this[method](arg1, arg2);
          }
        } catch (err) {
          _iterator4.e(err);
        } finally {
          _iterator4.f();
        }

        this._syncList = [];
        var numMeta = elements.length;
        var numData = data.length;
        var count = Math.min(numData, numMeta);

        if (count) {
          this.parse(0, count);
        }

        if (numData > numMeta) {
          this._insertElements(numMeta, numData - numMeta, resetNewElements);
        } else if (numData < numMeta) {
          this._removeElements(numData, numMeta - numData);
        }
      }
    }, {
      key: "_insertElements",
      value: function _insertElements(start, count) {
        var resetNewElements = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : true;
        var meta = this._cachedMeta;
        var data = meta.data;
        var end = start + count;
        var i;

        var move = function move(arr) {
          arr.length += count;

          for (i = arr.length - 1; i >= end; i--) {
            arr[i] = arr[i - count];
          }
        };

        move(data);

        for (i = start; i < end; ++i) {
          data[i] = new this.dataElementType();
        }

        if (this._parsing) {
          move(meta._parsed);
        }

        this.parse(start, count);

        if (resetNewElements) {
          this.updateElements(data, start, count, 'reset');
        }
      }
    }, {
      key: "updateElements",
      value: function updateElements(element, start, count, mode) {}
    }, {
      key: "_removeElements",
      value: function _removeElements(start, count) {
        var meta = this._cachedMeta;

        if (this._parsing) {
          var removed = meta._parsed.splice(start, count);

          if (meta._stacked) {
            clearStacks(meta, removed);
          }
        }

        meta.data.splice(start, count);
      }
    }, {
      key: "_sync",
      value: function _sync(args) {
        if (this._parsing) {
          this._syncList.push(args);
        } else {
          var _args2 = _slicedToArray(args, 3),
              method = _args2[0],
              arg1 = _args2[1],
              arg2 = _args2[2];

          this[method](arg1, arg2);
        }

        this.chart._dataChanges.push([this.index].concat(_toConsumableArray(args)));
      }
    }, {
      key: "_onDataPush",
      value: function _onDataPush() {
        var count = arguments.length;

        this._sync(['_insertElements', this.getDataset().data.length - count, count]);
      }
    }, {
      key: "_onDataPop",
      value: function _onDataPop() {
        this._sync(['_removeElements', this._cachedMeta.data.length - 1, 1]);
      }
    }, {
      key: "_onDataShift",
      value: function _onDataShift() {
        this._sync(['_removeElements', 0, 1]);
      }
    }, {
      key: "_onDataSplice",
      value: function _onDataSplice(start, count) {
        if (count) {
          this._sync(['_removeElements', start, count]);
        }

        var newCount = arguments.length - 2;

        if (newCount) {
          this._sync(['_insertElements', start, newCount]);
        }
      }
    }, {
      key: "_onDataUnshift",
      value: function _onDataUnshift() {
        this._sync(['_insertElements', 0, arguments.length]);
      }
    }]);

    return DatasetController;
  }();

  DatasetController.defaults = {};
  DatasetController.prototype.datasetElementType = null;
  DatasetController.prototype.dataElementType = null;

  function getAllScaleValues(scale, type) {
    if (!scale._cache.$bar) {
      var visibleMetas = scale.getMatchingVisibleMetas(type);
      var values = [];

      for (var i = 0, ilen = visibleMetas.length; i < ilen; i++) {
        values = values.concat(visibleMetas[i].controller.getAllParsedValues(scale));
      }

      scale._cache.$bar = _arrayUnique(values.sort(function (a, b) {
        return a - b;
      }));
    }

    return scale._cache.$bar;
  }

  function computeMinSampleSize(meta) {
    var scale = meta.iScale;
    var values = getAllScaleValues(scale, meta.type);
    var min = scale._length;
    var i, ilen, curr, prev;

    var updateMinAndPrev = function updateMinAndPrev() {
      if (curr === 32767 || curr === -32768) {
        return;
      }

      if (defined(prev)) {
        min = Math.min(min, Math.abs(curr - prev) || min);
      }

      prev = curr;
    };

    for (i = 0, ilen = values.length; i < ilen; ++i) {
      curr = scale.getPixelForValue(values[i]);
      updateMinAndPrev();
    }

    prev = undefined;

    for (i = 0, ilen = scale.ticks.length; i < ilen; ++i) {
      curr = scale.getPixelForTick(i);
      updateMinAndPrev();
    }

    return min;
  }

  function computeFitCategoryTraits(index, ruler, options, stackCount) {
    var thickness = options.barThickness;
    var size, ratio;

    if (isNullOrUndef(thickness)) {
      size = ruler.min * options.categoryPercentage;
      ratio = options.barPercentage;
    } else {
      size = thickness * stackCount;
      ratio = 1;
    }

    return {
      chunk: size / stackCount,
      ratio: ratio,
      start: ruler.pixels[index] - size / 2
    };
  }

  function computeFlexCategoryTraits(index, ruler, options, stackCount) {
    var pixels = ruler.pixels;
    var curr = pixels[index];
    var prev = index > 0 ? pixels[index - 1] : null;
    var next = index < pixels.length - 1 ? pixels[index + 1] : null;
    var percent = options.categoryPercentage;

    if (prev === null) {
      prev = curr - (next === null ? ruler.end - ruler.start : next - curr);
    }

    if (next === null) {
      next = curr + curr - prev;
    }

    var start = curr - (curr - Math.min(prev, next)) / 2 * percent;
    var size = Math.abs(next - prev) / 2 * percent;
    return {
      chunk: size / stackCount,
      ratio: options.barPercentage,
      start: start
    };
  }

  function parseFloatBar(entry, item, vScale, i) {
    var startValue = vScale.parse(entry[0], i);
    var endValue = vScale.parse(entry[1], i);
    var min = Math.min(startValue, endValue);
    var max = Math.max(startValue, endValue);
    var barStart = min;
    var barEnd = max;

    if (Math.abs(min) > Math.abs(max)) {
      barStart = max;
      barEnd = min;
    }

    item[vScale.axis] = barEnd;
    item._custom = {
      barStart: barStart,
      barEnd: barEnd,
      start: startValue,
      end: endValue,
      min: min,
      max: max
    };
  }

  function parseValue(entry, item, vScale, i) {
    if (isArray(entry)) {
      parseFloatBar(entry, item, vScale, i);
    } else {
      item[vScale.axis] = vScale.parse(entry, i);
    }

    return item;
  }

  function parseArrayOrPrimitive(meta, data, start, count) {
    var iScale = meta.iScale;
    var vScale = meta.vScale;
    var labels = iScale.getLabels();
    var singleScale = iScale === vScale;
    var parsed = [];
    var i, ilen, item, entry;

    for (i = start, ilen = start + count; i < ilen; ++i) {
      entry = data[i];
      item = {};
      item[iScale.axis] = singleScale || iScale.parse(labels[i], i);
      parsed.push(parseValue(entry, item, vScale, i));
    }

    return parsed;
  }

  function isFloatBar(custom) {
    return custom && custom.barStart !== undefined && custom.barEnd !== undefined;
  }

  function barSign(size, vScale, actualBase) {
    if (size !== 0) {
      return sign(size);
    }

    return (vScale.isHorizontal() ? 1 : -1) * (vScale.min >= actualBase ? 1 : -1);
  }

  function borderProps(properties) {
    var reverse, start, end, top, bottom;

    if (properties.horizontal) {
      reverse = properties.base > properties.x;
      start = 'left';
      end = 'right';
    } else {
      reverse = properties.base < properties.y;
      start = 'bottom';
      end = 'top';
    }

    if (reverse) {
      top = 'end';
      bottom = 'start';
    } else {
      top = 'start';
      bottom = 'end';
    }

    return {
      start: start,
      end: end,
      reverse: reverse,
      top: top,
      bottom: bottom
    };
  }

  function setBorderSkipped(properties, options, stack, index) {
    var edge = options.borderSkipped;
    var res = {};

    if (!edge) {
      properties.borderSkipped = res;
      return;
    }

    if (edge === true) {
      properties.borderSkipped = {
        top: true,
        right: true,
        bottom: true,
        left: true
      };
      return;
    }

    var _borderProps = borderProps(properties),
        start = _borderProps.start,
        end = _borderProps.end,
        reverse = _borderProps.reverse,
        top = _borderProps.top,
        bottom = _borderProps.bottom;

    if (edge === 'middle' && stack) {
      properties.enableBorderRadius = true;

      if ((stack._top || 0) === index) {
        edge = top;
      } else if ((stack._bottom || 0) === index) {
        edge = bottom;
      } else {
        res[parseEdge(bottom, start, end, reverse)] = true;
        edge = top;
      }
    }

    res[parseEdge(edge, start, end, reverse)] = true;
    properties.borderSkipped = res;
  }

  function parseEdge(edge, a, b, reverse) {
    if (reverse) {
      edge = swap(edge, a, b);
      edge = startEnd(edge, b, a);
    } else {
      edge = startEnd(edge, a, b);
    }

    return edge;
  }

  function swap(orig, v1, v2) {
    return orig === v1 ? v2 : orig === v2 ? v1 : orig;
  }

  function startEnd(v, start, end) {
    return v === 'start' ? start : v === 'end' ? end : v;
  }

  function setInflateAmount(properties, _ref, ratio) {
    var inflateAmount = _ref.inflateAmount;
    properties.inflateAmount = inflateAmount === 'auto' ? ratio === 1 ? 0.33 : 0 : inflateAmount;
  }

  var BarController = /*#__PURE__*/function (_DatasetController) {
    _inherits(BarController, _DatasetController);

    var _super = _createSuper(BarController);

    function BarController() {
      _classCallCheck(this, BarController);

      return _super.apply(this, arguments);
    }

    _createClass(BarController, [{
      key: "parsePrimitiveData",
      value: function parsePrimitiveData(meta, data, start, count) {
        return parseArrayOrPrimitive(meta, data, start, count);
      }
    }, {
      key: "parseArrayData",
      value: function parseArrayData(meta, data, start, count) {
        return parseArrayOrPrimitive(meta, data, start, count);
      }
    }, {
      key: "parseObjectData",
      value: function parseObjectData(meta, data, start, count) {
        var iScale = meta.iScale,
            vScale = meta.vScale;
        var _this$_parsing2 = this._parsing,
            _this$_parsing2$xAxis = _this$_parsing2.xAxisKey,
            xAxisKey = _this$_parsing2$xAxis === void 0 ? 'x' : _this$_parsing2$xAxis,
            _this$_parsing2$yAxis = _this$_parsing2.yAxisKey,
            yAxisKey = _this$_parsing2$yAxis === void 0 ? 'y' : _this$_parsing2$yAxis;
        var iAxisKey = iScale.axis === 'x' ? xAxisKey : yAxisKey;
        var vAxisKey = vScale.axis === 'x' ? xAxisKey : yAxisKey;
        var parsed = [];
        var i, ilen, item, obj;

        for (i = start, ilen = start + count; i < ilen; ++i) {
          obj = data[i];
          item = {};
          item[iScale.axis] = iScale.parse(resolveObjectKey(obj, iAxisKey), i);
          parsed.push(parseValue(resolveObjectKey(obj, vAxisKey), item, vScale, i));
        }

        return parsed;
      }
    }, {
      key: "updateRangeFromParsed",
      value: function updateRangeFromParsed(range, scale, parsed, stack) {
        _get(_getPrototypeOf(BarController.prototype), "updateRangeFromParsed", this).call(this, range, scale, parsed, stack);

        var custom = parsed._custom;

        if (custom && scale === this._cachedMeta.vScale) {
          range.min = Math.min(range.min, custom.min);
          range.max = Math.max(range.max, custom.max);
        }
      }
    }, {
      key: "getMaxOverflow",
      value: function getMaxOverflow() {
        return 0;
      }
    }, {
      key: "getLabelAndValue",
      value: function getLabelAndValue(index) {
        var meta = this._cachedMeta;
        var iScale = meta.iScale,
            vScale = meta.vScale;
        var parsed = this.getParsed(index);
        var custom = parsed._custom;
        var value = isFloatBar(custom) ? '[' + custom.start + ', ' + custom.end + ']' : '' + vScale.getLabelForValue(parsed[vScale.axis]);
        return {
          label: '' + iScale.getLabelForValue(parsed[iScale.axis]),
          value: value
        };
      }
    }, {
      key: "initialize",
      value: function initialize() {
        this.enableOptionSharing = true;

        _get(_getPrototypeOf(BarController.prototype), "initialize", this).call(this);

        var meta = this._cachedMeta;
        meta.stack = this.getDataset().stack;
      }
    }, {
      key: "update",
      value: function update(mode) {
        var meta = this._cachedMeta;
        this.updateElements(meta.data, 0, meta.data.length, mode);
      }
    }, {
      key: "updateElements",
      value: function updateElements(bars, start, count, mode) {
        var reset = mode === 'reset';
        var index = this.index,
            vScale = this._cachedMeta.vScale;
        var base = vScale.getBasePixel();
        var horizontal = vScale.isHorizontal();

        var ruler = this._getRuler();

        var _this$_getSharedOptio = this._getSharedOptions(start, mode),
            sharedOptions = _this$_getSharedOptio.sharedOptions,
            includeOptions = _this$_getSharedOptio.includeOptions;

        for (var i = start; i < start + count; i++) {
          var parsed = this.getParsed(i);
          var vpixels = reset || isNullOrUndef(parsed[vScale.axis]) ? {
            base: base,
            head: base
          } : this._calculateBarValuePixels(i);

          var ipixels = this._calculateBarIndexPixels(i, ruler);

          var stack = (parsed._stacks || {})[vScale.axis];
          var properties = {
            horizontal: horizontal,
            base: vpixels.base,
            enableBorderRadius: !stack || isFloatBar(parsed._custom) || index === stack._top || index === stack._bottom,
            x: horizontal ? vpixels.head : ipixels.center,
            y: horizontal ? ipixels.center : vpixels.head,
            height: horizontal ? ipixels.size : Math.abs(vpixels.size),
            width: horizontal ? Math.abs(vpixels.size) : ipixels.size
          };

          if (includeOptions) {
            properties.options = sharedOptions || this.resolveDataElementOptions(i, bars[i].active ? 'active' : mode);
          }

          var options = properties.options || bars[i].options;
          setBorderSkipped(properties, options, stack, index);
          setInflateAmount(properties, options, ruler.ratio);
          this.updateElement(bars[i], i, properties, mode);
        }
      }
    }, {
      key: "_getStacks",
      value: function _getStacks(last, dataIndex) {
        var iScale = this._cachedMeta.iScale;
        var metasets = iScale.getMatchingVisibleMetas(this._type).filter(function (meta) {
          return meta.controller.options.grouped;
        });
        var stacked = iScale.options.stacked;
        var stacks = [];

        var skipNull = function skipNull(meta) {
          var parsed = meta.controller.getParsed(dataIndex);
          var val = parsed && parsed[meta.vScale.axis];

          if (isNullOrUndef(val) || isNaN(val)) {
            return true;
          }
        };

        var _iterator5 = _createForOfIteratorHelper(metasets),
            _step5;

        try {
          for (_iterator5.s(); !(_step5 = _iterator5.n()).done;) {
            var meta = _step5.value;

            if (dataIndex !== undefined && skipNull(meta)) {
              continue;
            }

            if (stacked === false || stacks.indexOf(meta.stack) === -1 || stacked === undefined && meta.stack === undefined) {
              stacks.push(meta.stack);
            }

            if (meta.index === last) {
              break;
            }
          }
        } catch (err) {
          _iterator5.e(err);
        } finally {
          _iterator5.f();
        }

        if (!stacks.length) {
          stacks.push(undefined);
        }

        return stacks;
      }
    }, {
      key: "_getStackCount",
      value: function _getStackCount(index) {
        return this._getStacks(undefined, index).length;
      }
    }, {
      key: "_getStackIndex",
      value: function _getStackIndex(datasetIndex, name, dataIndex) {
        var stacks = this._getStacks(datasetIndex, dataIndex);

        var index = name !== undefined ? stacks.indexOf(name) : -1;
        return index === -1 ? stacks.length - 1 : index;
      }
    }, {
      key: "_getRuler",
      value: function _getRuler() {
        var opts = this.options;
        var meta = this._cachedMeta;
        var iScale = meta.iScale;
        var pixels = [];
        var i, ilen;

        for (i = 0, ilen = meta.data.length; i < ilen; ++i) {
          pixels.push(iScale.getPixelForValue(this.getParsed(i)[iScale.axis], i));
        }

        var barThickness = opts.barThickness;
        var min = barThickness || computeMinSampleSize(meta);
        return {
          min: min,
          pixels: pixels,
          start: iScale._startPixel,
          end: iScale._endPixel,
          stackCount: this._getStackCount(),
          scale: iScale,
          grouped: opts.grouped,
          ratio: barThickness ? 1 : opts.categoryPercentage * opts.barPercentage
        };
      }
    }, {
      key: "_calculateBarValuePixels",
      value: function _calculateBarValuePixels(index) {
        var _this$_cachedMeta = this._cachedMeta,
            vScale = _this$_cachedMeta.vScale,
            _stacked = _this$_cachedMeta._stacked,
            _this$options = this.options,
            baseValue = _this$options.base,
            minBarLength = _this$options.minBarLength;
        var actualBase = baseValue || 0;
        var parsed = this.getParsed(index);
        var custom = parsed._custom;
        var floating = isFloatBar(custom);
        var value = parsed[vScale.axis];
        var start = 0;
        var length = _stacked ? this.applyStack(vScale, parsed, _stacked) : value;
        var head, size;

        if (length !== value) {
          start = length - value;
          length = value;
        }

        if (floating) {
          value = custom.barStart;
          length = custom.barEnd - custom.barStart;

          if (value !== 0 && sign(value) !== sign(custom.barEnd)) {
            start = 0;
          }

          start += value;
        }

        var startValue = !isNullOrUndef(baseValue) && !floating ? baseValue : start;
        var base = vScale.getPixelForValue(startValue);

        if (this.chart.getDataVisibility(index)) {
          head = vScale.getPixelForValue(start + length);
        } else {
          head = base;
        }

        size = head - base;

        if (Math.abs(size) < minBarLength) {
          size = barSign(size, vScale, actualBase) * minBarLength;

          if (value === actualBase) {
            base -= size / 2;
          }

          var startPixel = vScale.getPixelForDecimal(0);
          var endPixel = vScale.getPixelForDecimal(1);
          var min = Math.min(startPixel, endPixel);
          var max = Math.max(startPixel, endPixel);
          base = Math.max(Math.min(base, max), min);
          head = base + size;
        }

        if (base === vScale.getPixelForValue(actualBase)) {
          var halfGrid = sign(size) * vScale.getLineWidthForValue(actualBase) / 2;
          base += halfGrid;
          size -= halfGrid;
        }

        return {
          size: size,
          base: base,
          head: head,
          center: head + size / 2
        };
      }
    }, {
      key: "_calculateBarIndexPixels",
      value: function _calculateBarIndexPixels(index, ruler) {
        var scale = ruler.scale;
        var options = this.options;
        var skipNull = options.skipNull;
        var maxBarThickness = valueOrDefault(options.maxBarThickness, Infinity);
        var center, size;

        if (ruler.grouped) {
          var stackCount = skipNull ? this._getStackCount(index) : ruler.stackCount;
          var range = options.barThickness === 'flex' ? computeFlexCategoryTraits(index, ruler, options, stackCount) : computeFitCategoryTraits(index, ruler, options, stackCount);

          var stackIndex = this._getStackIndex(this.index, this._cachedMeta.stack, skipNull ? index : undefined);

          center = range.start + range.chunk * stackIndex + range.chunk / 2;
          size = Math.min(maxBarThickness, range.chunk * range.ratio);
        } else {
          center = scale.getPixelForValue(this.getParsed(index)[scale.axis], index);
          size = Math.min(maxBarThickness, ruler.min * ruler.ratio);
        }

        return {
          base: center - size / 2,
          head: center + size / 2,
          center: center,
          size: size
        };
      }
    }, {
      key: "draw",
      value: function draw() {
        var meta = this._cachedMeta;
        var vScale = meta.vScale;
        var rects = meta.data;
        var ilen = rects.length;
        var i = 0;

        for (; i < ilen; ++i) {
          if (this.getParsed(i)[vScale.axis] !== null) {
            rects[i].draw(this._ctx);
          }
        }
      }
    }]);

    return BarController;
  }(DatasetController);

  BarController.id = 'bar';
  BarController.defaults = {
    datasetElementType: false,
    dataElementType: 'bar',
    categoryPercentage: 0.8,
    barPercentage: 0.9,
    grouped: true,
    animations: {
      numbers: {
        type: 'number',
        properties: ['x', 'y', 'base', 'width', 'height']
      }
    }
  };
  BarController.overrides = {
    scales: {
      _index_: {
        type: 'category',
        offset: true,
        grid: {
          offset: true
        }
      },
      _value_: {
        type: 'linear',
        beginAtZero: true
      }
    }
  };

  var BubbleController = /*#__PURE__*/function (_DatasetController2) {
    _inherits(BubbleController, _DatasetController2);

    var _super2 = _createSuper(BubbleController);

    function BubbleController() {
      _classCallCheck(this, BubbleController);

      return _super2.apply(this, arguments);
    }

    _createClass(BubbleController, [{
      key: "initialize",
      value: function initialize() {
        this.enableOptionSharing = true;

        _get(_getPrototypeOf(BubbleController.prototype), "initialize", this).call(this);
      }
    }, {
      key: "parsePrimitiveData",
      value: function parsePrimitiveData(meta, data, start, count) {
        var parsed = _get(_getPrototypeOf(BubbleController.prototype), "parsePrimitiveData", this).call(this, meta, data, start, count);

        for (var i = 0; i < parsed.length; i++) {
          parsed[i]._custom = this.resolveDataElementOptions(i + start).radius;
        }

        return parsed;
      }
    }, {
      key: "parseArrayData",
      value: function parseArrayData(meta, data, start, count) {
        var parsed = _get(_getPrototypeOf(BubbleController.prototype), "parseArrayData", this).call(this, meta, data, start, count);

        for (var i = 0; i < parsed.length; i++) {
          var item = data[start + i];
          parsed[i]._custom = valueOrDefault(item[2], this.resolveDataElementOptions(i + start).radius);
        }

        return parsed;
      }
    }, {
      key: "parseObjectData",
      value: function parseObjectData(meta, data, start, count) {
        var parsed = _get(_getPrototypeOf(BubbleController.prototype), "parseObjectData", this).call(this, meta, data, start, count);

        for (var i = 0; i < parsed.length; i++) {
          var item = data[start + i];
          parsed[i]._custom = valueOrDefault(item && item.r && +item.r, this.resolveDataElementOptions(i + start).radius);
        }

        return parsed;
      }
    }, {
      key: "getMaxOverflow",
      value: function getMaxOverflow() {
        var data = this._cachedMeta.data;
        var max = 0;

        for (var i = data.length - 1; i >= 0; --i) {
          max = Math.max(max, data[i].size(this.resolveDataElementOptions(i)) / 2);
        }

        return max > 0 && max;
      }
    }, {
      key: "getLabelAndValue",
      value: function getLabelAndValue(index) {
        var meta = this._cachedMeta;
        var xScale = meta.xScale,
            yScale = meta.yScale;
        var parsed = this.getParsed(index);
        var x = xScale.getLabelForValue(parsed.x);
        var y = yScale.getLabelForValue(parsed.y);
        var r = parsed._custom;
        return {
          label: meta.label,
          value: '(' + x + ', ' + y + (r ? ', ' + r : '') + ')'
        };
      }
    }, {
      key: "update",
      value: function update(mode) {
        var points = this._cachedMeta.data;
        this.updateElements(points, 0, points.length, mode);
      }
    }, {
      key: "updateElements",
      value: function updateElements(points, start, count, mode) {
        var reset = mode === 'reset';
        var _this$_cachedMeta2 = this._cachedMeta,
            iScale = _this$_cachedMeta2.iScale,
            vScale = _this$_cachedMeta2.vScale;

        var _this$_getSharedOptio2 = this._getSharedOptions(start, mode),
            sharedOptions = _this$_getSharedOptio2.sharedOptions,
            includeOptions = _this$_getSharedOptio2.includeOptions;

        var iAxis = iScale.axis;
        var vAxis = vScale.axis;

        for (var i = start; i < start + count; i++) {
          var point = points[i];
          var parsed = !reset && this.getParsed(i);
          var properties = {};
          var iPixel = properties[iAxis] = reset ? iScale.getPixelForDecimal(0.5) : iScale.getPixelForValue(parsed[iAxis]);
          var vPixel = properties[vAxis] = reset ? vScale.getBasePixel() : vScale.getPixelForValue(parsed[vAxis]);
          properties.skip = isNaN(iPixel) || isNaN(vPixel);

          if (includeOptions) {
            properties.options = sharedOptions || this.resolveDataElementOptions(i, point.active ? 'active' : mode);

            if (reset) {
              properties.options.radius = 0;
            }
          }

          this.updateElement(point, i, properties, mode);
        }
      }
    }, {
      key: "resolveDataElementOptions",
      value: function resolveDataElementOptions(index, mode) {
        var parsed = this.getParsed(index);

        var values = _get(_getPrototypeOf(BubbleController.prototype), "resolveDataElementOptions", this).call(this, index, mode);

        if (values.$shared) {
          values = Object.assign({}, values, {
            $shared: false
          });
        }

        var radius = values.radius;

        if (mode !== 'active') {
          values.radius = 0;
        }

        values.radius += valueOrDefault(parsed && parsed._custom, radius);
        return values;
      }
    }]);

    return BubbleController;
  }(DatasetController);

  BubbleController.id = 'bubble';
  BubbleController.defaults = {
    datasetElementType: false,
    dataElementType: 'point',
    animations: {
      numbers: {
        type: 'number',
        properties: ['x', 'y', 'borderWidth', 'radius']
      }
    }
  };
  BubbleController.overrides = {
    scales: {
      x: {
        type: 'linear'
      },
      y: {
        type: 'linear'
      }
    },
    plugins: {
      tooltip: {
        callbacks: {
          title: function title() {
            return '';
          }
        }
      }
    }
  };

  function getRatioAndOffset(rotation, circumference, cutout) {
    var ratioX = 1;
    var ratioY = 1;
    var offsetX = 0;
    var offsetY = 0;

    if (circumference < TAU) {
      var startAngle = rotation;
      var endAngle = startAngle + circumference;
      var startX = Math.cos(startAngle);
      var startY = Math.sin(startAngle);
      var endX = Math.cos(endAngle);
      var endY = Math.sin(endAngle);

      var calcMax = function calcMax(angle, a, b) {
        return _angleBetween(angle, startAngle, endAngle, true) ? 1 : Math.max(a, a * cutout, b, b * cutout);
      };

      var calcMin = function calcMin(angle, a, b) {
        return _angleBetween(angle, startAngle, endAngle, true) ? -1 : Math.min(a, a * cutout, b, b * cutout);
      };

      var maxX = calcMax(0, startX, endX);
      var maxY = calcMax(HALF_PI, startY, endY);
      var minX = calcMin(PI, startX, endX);
      var minY = calcMin(PI + HALF_PI, startY, endY);
      ratioX = (maxX - minX) / 2;
      ratioY = (maxY - minY) / 2;
      offsetX = -(maxX + minX) / 2;
      offsetY = -(maxY + minY) / 2;
    }

    return {
      ratioX: ratioX,
      ratioY: ratioY,
      offsetX: offsetX,
      offsetY: offsetY
    };
  }

  var DoughnutController = /*#__PURE__*/function (_DatasetController3) {
    _inherits(DoughnutController, _DatasetController3);

    var _super3 = _createSuper(DoughnutController);

    function DoughnutController(chart, datasetIndex) {
      var _this4;

      _classCallCheck(this, DoughnutController);

      _this4 = _super3.call(this, chart, datasetIndex);
      _this4.enableOptionSharing = true;
      _this4.innerRadius = undefined;
      _this4.outerRadius = undefined;
      _this4.offsetX = undefined;
      _this4.offsetY = undefined;
      return _this4;
    }

    _createClass(DoughnutController, [{
      key: "linkScales",
      value: function linkScales() {}
    }, {
      key: "parse",
      value: function parse(start, count) {
        var data = this.getDataset().data;
        var meta = this._cachedMeta;

        if (this._parsing === false) {
          meta._parsed = data;
        } else {
          var getter = function getter(i) {
            return +data[i];
          };

          if (isObject(data[start])) {
            var _this$_parsing$key = this._parsing.key,
                key = _this$_parsing$key === void 0 ? 'value' : _this$_parsing$key;

            getter = function getter(i) {
              return +resolveObjectKey(data[i], key);
            };
          }

          var i, ilen;

          for (i = start, ilen = start + count; i < ilen; ++i) {
            meta._parsed[i] = getter(i);
          }
        }
      }
    }, {
      key: "_getRotation",
      value: function _getRotation() {
        return toRadians(this.options.rotation - 90);
      }
    }, {
      key: "_getCircumference",
      value: function _getCircumference() {
        return toRadians(this.options.circumference);
      }
    }, {
      key: "_getRotationExtents",
      value: function _getRotationExtents() {
        var min = TAU;
        var max = -TAU;

        for (var i = 0; i < this.chart.data.datasets.length; ++i) {
          if (this.chart.isDatasetVisible(i)) {
            var controller = this.chart.getDatasetMeta(i).controller;

            var rotation = controller._getRotation();

            var circumference = controller._getCircumference();

            min = Math.min(min, rotation);
            max = Math.max(max, rotation + circumference);
          }
        }

        return {
          rotation: min,
          circumference: max - min
        };
      }
    }, {
      key: "update",
      value: function update(mode) {
        var chart = this.chart;
        var chartArea = chart.chartArea;
        var meta = this._cachedMeta;
        var arcs = meta.data;
        var spacing = this.getMaxBorderWidth() + this.getMaxOffset(arcs) + this.options.spacing;
        var maxSize = Math.max((Math.min(chartArea.width, chartArea.height) - spacing) / 2, 0);
        var cutout = Math.min(toPercentage(this.options.cutout, maxSize), 1);

        var chartWeight = this._getRingWeight(this.index);

        var _this$_getRotationExt = this._getRotationExtents(),
            circumference = _this$_getRotationExt.circumference,
            rotation = _this$_getRotationExt.rotation;

        var _getRatioAndOffset = getRatioAndOffset(rotation, circumference, cutout),
            ratioX = _getRatioAndOffset.ratioX,
            ratioY = _getRatioAndOffset.ratioY,
            offsetX = _getRatioAndOffset.offsetX,
            offsetY = _getRatioAndOffset.offsetY;

        var maxWidth = (chartArea.width - spacing) / ratioX;
        var maxHeight = (chartArea.height - spacing) / ratioY;
        var maxRadius = Math.max(Math.min(maxWidth, maxHeight) / 2, 0);
        var outerRadius = toDimension(this.options.radius, maxRadius);
        var innerRadius = Math.max(outerRadius * cutout, 0);

        var radiusLength = (outerRadius - innerRadius) / this._getVisibleDatasetWeightTotal();

        this.offsetX = offsetX * outerRadius;
        this.offsetY = offsetY * outerRadius;
        meta.total = this.calculateTotal();
        this.outerRadius = outerRadius - radiusLength * this._getRingWeightOffset(this.index);
        this.innerRadius = Math.max(this.outerRadius - radiusLength * chartWeight, 0);
        this.updateElements(arcs, 0, arcs.length, mode);
      }
    }, {
      key: "_circumference",
      value: function _circumference(i, reset) {
        var opts = this.options;
        var meta = this._cachedMeta;

        var circumference = this._getCircumference();

        if (reset && opts.animation.animateRotate || !this.chart.getDataVisibility(i) || meta._parsed[i] === null || meta.data[i].hidden) {
          return 0;
        }

        return this.calculateCircumference(meta._parsed[i] * circumference / TAU);
      }
    }, {
      key: "updateElements",
      value: function updateElements(arcs, start, count, mode) {
        var reset = mode === 'reset';
        var chart = this.chart;
        var chartArea = chart.chartArea;
        var opts = chart.options;
        var animationOpts = opts.animation;
        var centerX = (chartArea.left + chartArea.right) / 2;
        var centerY = (chartArea.top + chartArea.bottom) / 2;
        var animateScale = reset && animationOpts.animateScale;
        var innerRadius = animateScale ? 0 : this.innerRadius;
        var outerRadius = animateScale ? 0 : this.outerRadius;

        var _this$_getSharedOptio3 = this._getSharedOptions(start, mode),
            sharedOptions = _this$_getSharedOptio3.sharedOptions,
            includeOptions = _this$_getSharedOptio3.includeOptions;

        var startAngle = this._getRotation();

        var i;

        for (i = 0; i < start; ++i) {
          startAngle += this._circumference(i, reset);
        }

        for (i = start; i < start + count; ++i) {
          var circumference = this._circumference(i, reset);

          var arc = arcs[i];
          var properties = {
            x: centerX + this.offsetX,
            y: centerY + this.offsetY,
            startAngle: startAngle,
            endAngle: startAngle + circumference,
            circumference: circumference,
            outerRadius: outerRadius,
            innerRadius: innerRadius
          };

          if (includeOptions) {
            properties.options = sharedOptions || this.resolveDataElementOptions(i, arc.active ? 'active' : mode);
          }

          startAngle += circumference;
          this.updateElement(arc, i, properties, mode);
        }
      }
    }, {
      key: "calculateTotal",
      value: function calculateTotal() {
        var meta = this._cachedMeta;
        var metaData = meta.data;
        var total = 0;
        var i;

        for (i = 0; i < metaData.length; i++) {
          var value = meta._parsed[i];

          if (value !== null && !isNaN(value) && this.chart.getDataVisibility(i) && !metaData[i].hidden) {
            total += Math.abs(value);
          }
        }

        return total;
      }
    }, {
      key: "calculateCircumference",
      value: function calculateCircumference(value) {
        var total = this._cachedMeta.total;

        if (total > 0 && !isNaN(value)) {
          return TAU * (Math.abs(value) / total);
        }

        return 0;
      }
    }, {
      key: "getLabelAndValue",
      value: function getLabelAndValue(index) {
        var meta = this._cachedMeta;
        var chart = this.chart;
        var labels = chart.data.labels || [];
        var value = formatNumber(meta._parsed[index], chart.options.locale);
        return {
          label: labels[index] || '',
          value: value
        };
      }
    }, {
      key: "getMaxBorderWidth",
      value: function getMaxBorderWidth(arcs) {
        var max = 0;
        var chart = this.chart;
        var i, ilen, meta, controller, options;

        if (!arcs) {
          for (i = 0, ilen = chart.data.datasets.length; i < ilen; ++i) {
            if (chart.isDatasetVisible(i)) {
              meta = chart.getDatasetMeta(i);
              arcs = meta.data;
              controller = meta.controller;
              break;
            }
          }
        }

        if (!arcs) {
          return 0;
        }

        for (i = 0, ilen = arcs.length; i < ilen; ++i) {
          options = controller.resolveDataElementOptions(i);

          if (options.borderAlign !== 'inner') {
            max = Math.max(max, options.borderWidth || 0, options.hoverBorderWidth || 0);
          }
        }

        return max;
      }
    }, {
      key: "getMaxOffset",
      value: function getMaxOffset(arcs) {
        var max = 0;

        for (var i = 0, ilen = arcs.length; i < ilen; ++i) {
          var options = this.resolveDataElementOptions(i);
          max = Math.max(max, options.offset || 0, options.hoverOffset || 0);
        }

        return max;
      }
    }, {
      key: "_getRingWeightOffset",
      value: function _getRingWeightOffset(datasetIndex) {
        var ringWeightOffset = 0;

        for (var i = 0; i < datasetIndex; ++i) {
          if (this.chart.isDatasetVisible(i)) {
            ringWeightOffset += this._getRingWeight(i);
          }
        }

        return ringWeightOffset;
      }
    }, {
      key: "_getRingWeight",
      value: function _getRingWeight(datasetIndex) {
        return Math.max(valueOrDefault(this.chart.data.datasets[datasetIndex].weight, 1), 0);
      }
    }, {
      key: "_getVisibleDatasetWeightTotal",
      value: function _getVisibleDatasetWeightTotal() {
        return this._getRingWeightOffset(this.chart.data.datasets.length) || 1;
      }
    }]);

    return DoughnutController;
  }(DatasetController);

  DoughnutController.id = 'doughnut';
  DoughnutController.defaults = {
    datasetElementType: false,
    dataElementType: 'arc',
    animation: {
      animateRotate: true,
      animateScale: false
    },
    animations: {
      numbers: {
        type: 'number',
        properties: ['circumference', 'endAngle', 'innerRadius', 'outerRadius', 'startAngle', 'x', 'y', 'offset', 'borderWidth', 'spacing']
      }
    },
    cutout: '50%',
    rotation: 0,
    circumference: 360,
    radius: '100%',
    spacing: 0,
    indexAxis: 'r'
  };
  DoughnutController.descriptors = {
    _scriptable: function _scriptable(name) {
      return name !== 'spacing';
    },
    _indexable: function _indexable(name) {
      return name !== 'spacing';
    }
  };
  DoughnutController.overrides = {
    aspectRatio: 1,
    plugins: {
      legend: {
        labels: {
          generateLabels: function generateLabels(chart) {
            var data = chart.data;

            if (data.labels.length && data.datasets.length) {
              var pointStyle = chart.legend.options.labels.pointStyle;
              return data.labels.map(function (label, i) {
                var meta = chart.getDatasetMeta(0);
                var style = meta.controller.getStyle(i);
                return {
                  text: label,
                  fillStyle: style.backgroundColor,
                  strokeStyle: style.borderColor,
                  lineWidth: style.borderWidth,
                  pointStyle: pointStyle,
                  hidden: !chart.getDataVisibility(i),
                  index: i
                };
              });
            }

            return [];
          }
        },
        onClick: function onClick(e, legendItem, legend) {
          legend.chart.toggleDataVisibility(legendItem.index);
          legend.chart.update();
        }
      },
      tooltip: {
        callbacks: {
          title: function title() {
            return '';
          },
          label: function label(tooltipItem) {
            var dataLabel = tooltipItem.label;
            var value = ': ' + tooltipItem.formattedValue;

            if (isArray(dataLabel)) {
              dataLabel = dataLabel.slice();
              dataLabel[0] += value;
            } else {
              dataLabel += value;
            }

            return dataLabel;
          }
        }
      }
    }
  };

  var LineController = /*#__PURE__*/function (_DatasetController4) {
    _inherits(LineController, _DatasetController4);

    var _super4 = _createSuper(LineController);

    function LineController() {
      _classCallCheck(this, LineController);

      return _super4.apply(this, arguments);
    }

    _createClass(LineController, [{
      key: "initialize",
      value: function initialize() {
        this.enableOptionSharing = true;
        this.supportsDecimation = true;

        _get(_getPrototypeOf(LineController.prototype), "initialize", this).call(this);
      }
    }, {
      key: "update",
      value: function update(mode) {
        var meta = this._cachedMeta;
        var line = meta.dataset,
            _meta$data = meta.data,
            points = _meta$data === void 0 ? [] : _meta$data,
            _dataset = meta._dataset;
        var animationsDisabled = this.chart._animationsDisabled;

        var _getStartAndCountOfVi = _getStartAndCountOfVisiblePoints(meta, points, animationsDisabled),
            start = _getStartAndCountOfVi.start,
            count = _getStartAndCountOfVi.count;

        this._drawStart = start;
        this._drawCount = count;

        if (_scaleRangesChanged(meta)) {
          start = 0;
          count = points.length;
        }

        line._chart = this.chart;
        line._datasetIndex = this.index;
        line._decimated = !!_dataset._decimated;
        line.points = points;
        var options = this.resolveDatasetElementOptions(mode);

        if (!this.options.showLine) {
          options.borderWidth = 0;
        }

        options.segment = this.options.segment;
        this.updateElement(line, undefined, {
          animated: !animationsDisabled,
          options: options
        }, mode);
        this.updateElements(points, start, count, mode);
      }
    }, {
      key: "updateElements",
      value: function updateElements(points, start, count, mode) {
        var reset = mode === 'reset';
        var _this$_cachedMeta3 = this._cachedMeta,
            iScale = _this$_cachedMeta3.iScale,
            vScale = _this$_cachedMeta3.vScale,
            _stacked = _this$_cachedMeta3._stacked,
            _dataset = _this$_cachedMeta3._dataset;

        var _this$_getSharedOptio4 = this._getSharedOptions(start, mode),
            sharedOptions = _this$_getSharedOptio4.sharedOptions,
            includeOptions = _this$_getSharedOptio4.includeOptions;

        var iAxis = iScale.axis;
        var vAxis = vScale.axis;
        var _this$options2 = this.options,
            spanGaps = _this$options2.spanGaps,
            segment = _this$options2.segment;
        var maxGapLength = isNumber(spanGaps) ? spanGaps : Number.POSITIVE_INFINITY;
        var directUpdate = this.chart._animationsDisabled || reset || mode === 'none';
        var prevParsed = start > 0 && this.getParsed(start - 1);

        for (var i = start; i < start + count; ++i) {
          var point = points[i];
          var parsed = this.getParsed(i);
          var properties = directUpdate ? point : {};
          var nullData = isNullOrUndef(parsed[vAxis]);
          var iPixel = properties[iAxis] = iScale.getPixelForValue(parsed[iAxis], i);
          var vPixel = properties[vAxis] = reset || nullData ? vScale.getBasePixel() : vScale.getPixelForValue(_stacked ? this.applyStack(vScale, parsed, _stacked) : parsed[vAxis], i);
          properties.skip = isNaN(iPixel) || isNaN(vPixel) || nullData;
          properties.stop = i > 0 && Math.abs(parsed[iAxis] - prevParsed[iAxis]) > maxGapLength;

          if (segment) {
            properties.parsed = parsed;
            properties.raw = _dataset.data[i];
          }

          if (includeOptions) {
            properties.options = sharedOptions || this.resolveDataElementOptions(i, point.active ? 'active' : mode);
          }

          if (!directUpdate) {
            this.updateElement(point, i, properties, mode);
          }

          prevParsed = parsed;
        }
      }
    }, {
      key: "getMaxOverflow",
      value: function getMaxOverflow() {
        var meta = this._cachedMeta;
        var dataset = meta.dataset;
        var border = dataset.options && dataset.options.borderWidth || 0;
        var data = meta.data || [];

        if (!data.length) {
          return border;
        }

        var firstPoint = data[0].size(this.resolveDataElementOptions(0));
        var lastPoint = data[data.length - 1].size(this.resolveDataElementOptions(data.length - 1));
        return Math.max(border, firstPoint, lastPoint) / 2;
      }
    }, {
      key: "draw",
      value: function draw() {
        var meta = this._cachedMeta;
        meta.dataset.updateControlPoints(this.chart.chartArea, meta.iScale.axis);

        _get(_getPrototypeOf(LineController.prototype), "draw", this).call(this);
      }
    }]);

    return LineController;
  }(DatasetController);

  LineController.id = 'line';
  LineController.defaults = {
    datasetElementType: 'line',
    dataElementType: 'point',
    showLine: true,
    spanGaps: false
  };
  LineController.overrides = {
    scales: {
      _index_: {
        type: 'category'
      },
      _value_: {
        type: 'linear'
      }
    }
  };

  var PolarAreaController = /*#__PURE__*/function (_DatasetController5) {
    _inherits(PolarAreaController, _DatasetController5);

    var _super5 = _createSuper(PolarAreaController);

    function PolarAreaController(chart, datasetIndex) {
      var _this5;

      _classCallCheck(this, PolarAreaController);

      _this5 = _super5.call(this, chart, datasetIndex);
      _this5.innerRadius = undefined;
      _this5.outerRadius = undefined;
      return _this5;
    }

    _createClass(PolarAreaController, [{
      key: "getLabelAndValue",
      value: function getLabelAndValue(index) {
        var meta = this._cachedMeta;
        var chart = this.chart;
        var labels = chart.data.labels || [];
        var value = formatNumber(meta._parsed[index].r, chart.options.locale);
        return {
          label: labels[index] || '',
          value: value
        };
      }
    }, {
      key: "parseObjectData",
      value: function parseObjectData(meta, data, start, count) {
        return _parseObjectDataRadialScale.bind(this)(meta, data, start, count);
      }
    }, {
      key: "update",
      value: function update(mode) {
        var arcs = this._cachedMeta.data;

        this._updateRadius();

        this.updateElements(arcs, 0, arcs.length, mode);
      }
    }, {
      key: "getMinMax",
      value: function getMinMax() {
        var _this6 = this;

        var meta = this._cachedMeta;
        var range = {
          min: Number.POSITIVE_INFINITY,
          max: Number.NEGATIVE_INFINITY
        };
        meta.data.forEach(function (element, index) {
          var parsed = _this6.getParsed(index).r;

          if (!isNaN(parsed) && _this6.chart.getDataVisibility(index)) {
            if (parsed < range.min) {
              range.min = parsed;
            }

            if (parsed > range.max) {
              range.max = parsed;
            }
          }
        });
        return range;
      }
    }, {
      key: "_updateRadius",
      value: function _updateRadius() {
        var chart = this.chart;
        var chartArea = chart.chartArea;
        var opts = chart.options;
        var minSize = Math.min(chartArea.right - chartArea.left, chartArea.bottom - chartArea.top);
        var outerRadius = Math.max(minSize / 2, 0);
        var innerRadius = Math.max(opts.cutoutPercentage ? outerRadius / 100 * opts.cutoutPercentage : 1, 0);
        var radiusLength = (outerRadius - innerRadius) / chart.getVisibleDatasetCount();
        this.outerRadius = outerRadius - radiusLength * this.index;
        this.innerRadius = this.outerRadius - radiusLength;
      }
    }, {
      key: "updateElements",
      value: function updateElements(arcs, start, count, mode) {
        var reset = mode === 'reset';
        var chart = this.chart;
        var opts = chart.options;
        var animationOpts = opts.animation;
        var scale = this._cachedMeta.rScale;
        var centerX = scale.xCenter;
        var centerY = scale.yCenter;
        var datasetStartAngle = scale.getIndexAngle(0) - 0.5 * PI;
        var angle = datasetStartAngle;
        var i;
        var defaultAngle = 360 / this.countVisibleElements();

        for (i = 0; i < start; ++i) {
          angle += this._computeAngle(i, mode, defaultAngle);
        }

        for (i = start; i < start + count; i++) {
          var arc = arcs[i];
          var startAngle = angle;

          var endAngle = angle + this._computeAngle(i, mode, defaultAngle);

          var outerRadius = chart.getDataVisibility(i) ? scale.getDistanceFromCenterForValue(this.getParsed(i).r) : 0;
          angle = endAngle;

          if (reset) {
            if (animationOpts.animateScale) {
              outerRadius = 0;
            }

            if (animationOpts.animateRotate) {
              startAngle = endAngle = datasetStartAngle;
            }
          }

          var properties = {
            x: centerX,
            y: centerY,
            innerRadius: 0,
            outerRadius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            options: this.resolveDataElementOptions(i, arc.active ? 'active' : mode)
          };
          this.updateElement(arc, i, properties, mode);
        }
      }
    }, {
      key: "countVisibleElements",
      value: function countVisibleElements() {
        var _this7 = this;

        var meta = this._cachedMeta;
        var count = 0;
        meta.data.forEach(function (element, index) {
          if (!isNaN(_this7.getParsed(index).r) && _this7.chart.getDataVisibility(index)) {
            count++;
          }
        });
        return count;
      }
    }, {
      key: "_computeAngle",
      value: function _computeAngle(index, mode, defaultAngle) {
        return this.chart.getDataVisibility(index) ? toRadians(this.resolveDataElementOptions(index, mode).angle || defaultAngle) : 0;
      }
    }]);

    return PolarAreaController;
  }(DatasetController);

  PolarAreaController.id = 'polarArea';
  PolarAreaController.defaults = {
    dataElementType: 'arc',
    animation: {
      animateRotate: true,
      animateScale: true
    },
    animations: {
      numbers: {
        type: 'number',
        properties: ['x', 'y', 'startAngle', 'endAngle', 'innerRadius', 'outerRadius']
      }
    },
    indexAxis: 'r',
    startAngle: 0
  };
  PolarAreaController.overrides = {
    aspectRatio: 1,
    plugins: {
      legend: {
        labels: {
          generateLabels: function generateLabels(chart) {
            var data = chart.data;

            if (data.labels.length && data.datasets.length) {
              var pointStyle = chart.legend.options.labels.pointStyle;
              return data.labels.map(function (label, i) {
                var meta = chart.getDatasetMeta(0);
                var style = meta.controller.getStyle(i);
                return {
                  text: label,
                  fillStyle: style.backgroundColor,
                  strokeStyle: style.borderColor,
                  lineWidth: style.borderWidth,
                  pointStyle: pointStyle,
                  hidden: !chart.getDataVisibility(i),
                  index: i
                };
              });
            }

            return [];
          }
        },
        onClick: function onClick(e, legendItem, legend) {
          legend.chart.toggleDataVisibility(legendItem.index);
          legend.chart.update();
        }
      },
      tooltip: {
        callbacks: {
          title: function title() {
            return '';
          },
          label: function label(context) {
            return context.chart.data.labels[context.dataIndex] + ': ' + context.formattedValue;
          }
        }
      }
    },
    scales: {
      r: {
        type: 'radialLinear',
        angleLines: {
          display: false
        },
        beginAtZero: true,
        grid: {
          circular: true
        },
        pointLabels: {
          display: false
        },
        startAngle: 0
      }
    }
  };

  var PieController = /*#__PURE__*/function (_DoughnutController) {
    _inherits(PieController, _DoughnutController);

    var _super6 = _createSuper(PieController);

    function PieController() {
      _classCallCheck(this, PieController);

      return _super6.apply(this, arguments);
    }

    return _createClass(PieController);
  }(DoughnutController);

  PieController.id = 'pie';
  PieController.defaults = {
    cutout: 0,
    rotation: 0,
    circumference: 360,
    radius: '100%'
  };

  var RadarController = /*#__PURE__*/function (_DatasetController6) {
    _inherits(RadarController, _DatasetController6);

    var _super7 = _createSuper(RadarController);

    function RadarController() {
      _classCallCheck(this, RadarController);

      return _super7.apply(this, arguments);
    }

    _createClass(RadarController, [{
      key: "getLabelAndValue",
      value: function getLabelAndValue(index) {
        var vScale = this._cachedMeta.vScale;
        var parsed = this.getParsed(index);
        return {
          label: vScale.getLabels()[index],
          value: '' + vScale.getLabelForValue(parsed[vScale.axis])
        };
      }
    }, {
      key: "parseObjectData",
      value: function parseObjectData(meta, data, start, count) {
        return _parseObjectDataRadialScale.bind(this)(meta, data, start, count);
      }
    }, {
      key: "update",
      value: function update(mode) {
        var meta = this._cachedMeta;
        var line = meta.dataset;
        var points = meta.data || [];
        var labels = meta.iScale.getLabels();
        line.points = points;

        if (mode !== 'resize') {
          var options = this.resolveDatasetElementOptions(mode);

          if (!this.options.showLine) {
            options.borderWidth = 0;
          }

          var properties = {
            _loop: true,
            _fullLoop: labels.length === points.length,
            options: options
          };
          this.updateElement(line, undefined, properties, mode);
        }

        this.updateElements(points, 0, points.length, mode);
      }
    }, {
      key: "updateElements",
      value: function updateElements(points, start, count, mode) {
        var scale = this._cachedMeta.rScale;
        var reset = mode === 'reset';

        for (var i = start; i < start + count; i++) {
          var point = points[i];
          var options = this.resolveDataElementOptions(i, point.active ? 'active' : mode);
          var pointPosition = scale.getPointPositionForValue(i, this.getParsed(i).r);
          var x = reset ? scale.xCenter : pointPosition.x;
          var y = reset ? scale.yCenter : pointPosition.y;
          var properties = {
            x: x,
            y: y,
            angle: pointPosition.angle,
            skip: isNaN(x) || isNaN(y),
            options: options
          };
          this.updateElement(point, i, properties, mode);
        }
      }
    }]);

    return RadarController;
  }(DatasetController);

  RadarController.id = 'radar';
  RadarController.defaults = {
    datasetElementType: 'line',
    dataElementType: 'point',
    indexAxis: 'r',
    showLine: true,
    elements: {
      line: {
        fill: 'start'
      }
    }
  };
  RadarController.overrides = {
    aspectRatio: 1,
    scales: {
      r: {
        type: 'radialLinear'
      }
    }
  };

  var Element = /*#__PURE__*/function () {
    function Element() {
      _classCallCheck(this, Element);

      this.x = undefined;
      this.y = undefined;
      this.active = false;
      this.options = undefined;
      this.$animations = undefined;
    }

    _createClass(Element, [{
      key: "tooltipPosition",
      value: function tooltipPosition(useFinalPosition) {
        var _this$getProps = this.getProps(['x', 'y'], useFinalPosition),
            x = _this$getProps.x,
            y = _this$getProps.y;

        return {
          x: x,
          y: y
        };
      }
    }, {
      key: "hasValue",
      value: function hasValue() {
        return isNumber(this.x) && isNumber(this.y);
      }
    }, {
      key: "getProps",
      value: function getProps(props, final) {
        var _this8 = this;

        var anims = this.$animations;

        if (!final || !anims) {
          return this;
        }

        var ret = {};
        props.forEach(function (prop) {
          ret[prop] = anims[prop] && anims[prop].active() ? anims[prop]._to : _this8[prop];
        });
        return ret;
      }
    }]);

    return Element;
  }();

  Element.defaults = {};
  Element.defaultRoutes = undefined;
  var formatters$4 = {
    values: function values(value) {
      return isArray(value) ? value : '' + value;
    },
    numeric: function numeric(tickValue, index, ticks) {
      if (tickValue === 0) {
        return '0';
      }

      var locale = this.chart.options.locale;
      var notation;
      var delta = tickValue;

      if (ticks.length > 1) {
        var maxTick = Math.max(Math.abs(ticks[0].value), Math.abs(ticks[ticks.length - 1].value));

        if (maxTick < 1e-4 || maxTick > 1e+15) {
          notation = 'scientific';
        }

        delta = calculateDelta(tickValue, ticks);
      }

      var logDelta = log10(Math.abs(delta));
      var numDecimal = Math.max(Math.min(-1 * Math.floor(logDelta), 20), 0);
      var options = {
        notation: notation,
        minimumFractionDigits: numDecimal,
        maximumFractionDigits: numDecimal
      };
      Object.assign(options, this.options.ticks.format);
      return formatNumber(tickValue, locale, options);
    },
    logarithmic: function logarithmic(tickValue, index, ticks) {
      if (tickValue === 0) {
        return '0';
      }

      var remain = tickValue / Math.pow(10, Math.floor(log10(tickValue)));

      if (remain === 1 || remain === 2 || remain === 5) {
        return formatters$4.numeric.call(this, tickValue, index, ticks);
      }

      return '';
    }
  };

  function calculateDelta(tickValue, ticks) {
    var delta = ticks.length > 3 ? ticks[2].value - ticks[1].value : ticks[1].value - ticks[0].value;

    if (Math.abs(delta) >= 1 && tickValue !== Math.floor(tickValue)) {
      delta = tickValue - Math.floor(tickValue);
    }

    return delta;
  }

  var Ticks = {
    formatters: formatters$4
  };
  defaults.set('scale', {
    display: true,
    offset: false,
    reverse: false,
    beginAtZero: false,
    bounds: 'ticks',
    grace: 0,
    grid: {
      display: true,
      lineWidth: 1,
      drawBorder: true,
      drawOnChartArea: true,
      drawTicks: true,
      tickLength: 8,
      tickWidth: function tickWidth(_ctx, options) {
        return options.lineWidth;
      },
      tickColor: function tickColor(_ctx, options) {
        return options.color;
      },
      offset: false,
      borderDash: [],
      borderDashOffset: 0.0,
      borderWidth: 1
    },
    title: {
      display: false,
      text: '',
      padding: {
        top: 4,
        bottom: 4
      }
    },
    ticks: {
      minRotation: 0,
      maxRotation: 50,
      mirror: false,
      textStrokeWidth: 0,
      textStrokeColor: '',
      padding: 3,
      display: true,
      autoSkip: true,
      autoSkipPadding: 3,
      labelOffset: 0,
      callback: Ticks.formatters.values,
      minor: {},
      major: {},
      align: 'center',
      crossAlign: 'near',
      showLabelBackdrop: false,
      backdropColor: 'rgba(255, 255, 255, 0.75)',
      backdropPadding: 2
    }
  });
  defaults.route('scale.ticks', 'color', '', 'color');
  defaults.route('scale.grid', 'color', '', 'borderColor');
  defaults.route('scale.grid', 'borderColor', '', 'borderColor');
  defaults.route('scale.title', 'color', '', 'color');
  defaults.describe('scale', {
    _fallback: false,
    _scriptable: function _scriptable(name) {
      return !name.startsWith('before') && !name.startsWith('after') && name !== 'callback' && name !== 'parser';
    },
    _indexable: function _indexable(name) {
      return name !== 'borderDash' && name !== 'tickBorderDash';
    }
  });
  defaults.describe('scales', {
    _fallback: 'scale'
  });
  defaults.describe('scale.ticks', {
    _scriptable: function _scriptable(name) {
      return name !== 'backdropPadding' && name !== 'callback';
    },
    _indexable: function _indexable(name) {
      return name !== 'backdropPadding';
    }
  });

  function autoSkip(scale, ticks) {
    var tickOpts = scale.options.ticks;
    var ticksLimit = tickOpts.maxTicksLimit || determineMaxTicks(scale);
    var majorIndices = tickOpts.major.enabled ? getMajorIndices(ticks) : [];
    var numMajorIndices = majorIndices.length;
    var first = majorIndices[0];
    var last = majorIndices[numMajorIndices - 1];
    var newTicks = [];

    if (numMajorIndices > ticksLimit) {
      skipMajors(ticks, newTicks, majorIndices, numMajorIndices / ticksLimit);
      return newTicks;
    }

    var spacing = calculateSpacing(majorIndices, ticks, ticksLimit);

    if (numMajorIndices > 0) {
      var i, ilen;
      var avgMajorSpacing = numMajorIndices > 1 ? Math.round((last - first) / (numMajorIndices - 1)) : null;
      skip(ticks, newTicks, spacing, isNullOrUndef(avgMajorSpacing) ? 0 : first - avgMajorSpacing, first);

      for (i = 0, ilen = numMajorIndices - 1; i < ilen; i++) {
        skip(ticks, newTicks, spacing, majorIndices[i], majorIndices[i + 1]);
      }

      skip(ticks, newTicks, spacing, last, isNullOrUndef(avgMajorSpacing) ? ticks.length : last + avgMajorSpacing);
      return newTicks;
    }

    skip(ticks, newTicks, spacing);
    return newTicks;
  }

  function determineMaxTicks(scale) {
    var offset = scale.options.offset;

    var tickLength = scale._tickSize();

    var maxScale = scale._length / tickLength + (offset ? 0 : 1);
    var maxChart = scale._maxLength / tickLength;
    return Math.floor(Math.min(maxScale, maxChart));
  }

  function calculateSpacing(majorIndices, ticks, ticksLimit) {
    var evenMajorSpacing = getEvenSpacing(majorIndices);
    var spacing = ticks.length / ticksLimit;

    if (!evenMajorSpacing) {
      return Math.max(spacing, 1);
    }

    var factors = _factorize(evenMajorSpacing);

    for (var i = 0, ilen = factors.length - 1; i < ilen; i++) {
      var factor = factors[i];

      if (factor > spacing) {
        return factor;
      }
    }

    return Math.max(spacing, 1);
  }

  function getMajorIndices(ticks) {
    var result = [];
    var i, ilen;

    for (i = 0, ilen = ticks.length; i < ilen; i++) {
      if (ticks[i].major) {
        result.push(i);
      }
    }

    return result;
  }

  function skipMajors(ticks, newTicks, majorIndices, spacing) {
    var count = 0;
    var next = majorIndices[0];
    var i;
    spacing = Math.ceil(spacing);

    for (i = 0; i < ticks.length; i++) {
      if (i === next) {
        newTicks.push(ticks[i]);
        count++;
        next = majorIndices[count * spacing];
      }
    }
  }

  function skip(ticks, newTicks, spacing, majorStart, majorEnd) {
    var start = valueOrDefault(majorStart, 0);
    var end = Math.min(valueOrDefault(majorEnd, ticks.length), ticks.length);
    var count = 0;
    var length, i, next;
    spacing = Math.ceil(spacing);

    if (majorEnd) {
      length = majorEnd - majorStart;
      spacing = length / Math.floor(length / spacing);
    }

    next = start;

    while (next < 0) {
      count++;
      next = Math.round(start + count * spacing);
    }

    for (i = Math.max(start, 0); i < end; i++) {
      if (i === next) {
        newTicks.push(ticks[i]);
        count++;
        next = Math.round(start + count * spacing);
      }
    }
  }

  function getEvenSpacing(arr) {
    var len = arr.length;
    var i, diff;

    if (len < 2) {
      return false;
    }

    for (diff = arr[0], i = 1; i < len; ++i) {
      if (arr[i] - arr[i - 1] !== diff) {
        return false;
      }
    }

    return diff;
  }

  var reverseAlign = function reverseAlign(align) {
    return align === 'left' ? 'right' : align === 'right' ? 'left' : align;
  };

  var offsetFromEdge = function offsetFromEdge(scale, edge, offset) {
    return edge === 'top' || edge === 'left' ? scale[edge] + offset : scale[edge] - offset;
  };

  function sample(arr, numItems) {
    var result = [];
    var increment = arr.length / numItems;
    var len = arr.length;
    var i = 0;

    for (; i < len; i += increment) {
      result.push(arr[Math.floor(i)]);
    }

    return result;
  }

  function getPixelForGridLine(scale, index, offsetGridLines) {
    var length = scale.ticks.length;
    var validIndex = Math.min(index, length - 1);
    var start = scale._startPixel;
    var end = scale._endPixel;
    var epsilon = 1e-6;
    var lineValue = scale.getPixelForTick(validIndex);
    var offset;

    if (offsetGridLines) {
      if (length === 1) {
        offset = Math.max(lineValue - start, end - lineValue);
      } else if (index === 0) {
        offset = (scale.getPixelForTick(1) - lineValue) / 2;
      } else {
        offset = (lineValue - scale.getPixelForTick(validIndex - 1)) / 2;
      }

      lineValue += validIndex < index ? offset : -offset;

      if (lineValue < start - epsilon || lineValue > end + epsilon) {
        return;
      }
    }

    return lineValue;
  }

  function garbageCollect(caches, length) {
    each(caches, function (cache) {
      var gc = cache.gc;
      var gcLen = gc.length / 2;
      var i;

      if (gcLen > length) {
        for (i = 0; i < gcLen; ++i) {
          delete cache.data[gc[i]];
        }

        gc.splice(0, gcLen);
      }
    });
  }

  function getTickMarkLength(options) {
    return options.drawTicks ? options.tickLength : 0;
  }

  function getTitleHeight(options, fallback) {
    if (!options.display) {
      return 0;
    }

    var font = toFont(options.font, fallback);
    var padding = toPadding(options.padding);
    var lines = isArray(options.text) ? options.text.length : 1;
    return lines * font.lineHeight + padding.height;
  }

  function createScaleContext(parent, scale) {
    return createContext(parent, {
      scale: scale,
      type: 'scale'
    });
  }

  function createTickContext(parent, index, tick) {
    return createContext(parent, {
      tick: tick,
      index: index,
      type: 'tick'
    });
  }

  function titleAlign(align, position, reverse) {
    var ret = _toLeftRightCenter(align);

    if (reverse && position !== 'right' || !reverse && position === 'right') {
      ret = reverseAlign(ret);
    }

    return ret;
  }

  function titleArgs(scale, offset, position, align) {
    var top = scale.top,
        left = scale.left,
        bottom = scale.bottom,
        right = scale.right,
        chart = scale.chart;
    var chartArea = chart.chartArea,
        scales = chart.scales;
    var rotation = 0;
    var maxWidth, titleX, titleY;
    var height = bottom - top;
    var width = right - left;

    if (scale.isHorizontal()) {
      titleX = _alignStartEnd(align, left, right);

      if (isObject(position)) {
        var positionAxisID = Object.keys(position)[0];
        var value = position[positionAxisID];
        titleY = scales[positionAxisID].getPixelForValue(value) + height - offset;
      } else if (position === 'center') {
        titleY = (chartArea.bottom + chartArea.top) / 2 + height - offset;
      } else {
        titleY = offsetFromEdge(scale, position, offset);
      }

      maxWidth = right - left;
    } else {
      if (isObject(position)) {
        var _positionAxisID = Object.keys(position)[0];
        var _value = position[_positionAxisID];
        titleX = scales[_positionAxisID].getPixelForValue(_value) - width + offset;
      } else if (position === 'center') {
        titleX = (chartArea.left + chartArea.right) / 2 - width + offset;
      } else {
        titleX = offsetFromEdge(scale, position, offset);
      }

      titleY = _alignStartEnd(align, bottom, top);
      rotation = position === 'left' ? -HALF_PI : HALF_PI;
    }

    return {
      titleX: titleX,
      titleY: titleY,
      maxWidth: maxWidth,
      rotation: rotation
    };
  }

  var Scale = /*#__PURE__*/function (_Element) {
    _inherits(Scale, _Element);

    var _super8 = _createSuper(Scale);

    function Scale(cfg) {
      var _this9;

      _classCallCheck(this, Scale);

      _this9 = _super8.call(this);
      _this9.id = cfg.id;
      _this9.type = cfg.type;
      _this9.options = undefined;
      _this9.ctx = cfg.ctx;
      _this9.chart = cfg.chart;
      _this9.top = undefined;
      _this9.bottom = undefined;
      _this9.left = undefined;
      _this9.right = undefined;
      _this9.width = undefined;
      _this9.height = undefined;
      _this9._margins = {
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      };
      _this9.maxWidth = undefined;
      _this9.maxHeight = undefined;
      _this9.paddingTop = undefined;
      _this9.paddingBottom = undefined;
      _this9.paddingLeft = undefined;
      _this9.paddingRight = undefined;
      _this9.axis = undefined;
      _this9.labelRotation = undefined;
      _this9.min = undefined;
      _this9.max = undefined;
      _this9._range = undefined;
      _this9.ticks = [];
      _this9._gridLineItems = null;
      _this9._labelItems = null;
      _this9._labelSizes = null;
      _this9._length = 0;
      _this9._maxLength = 0;
      _this9._longestTextCache = {};
      _this9._startPixel = undefined;
      _this9._endPixel = undefined;
      _this9._reversePixels = false;
      _this9._userMax = undefined;
      _this9._userMin = undefined;
      _this9._suggestedMax = undefined;
      _this9._suggestedMin = undefined;
      _this9._ticksLength = 0;
      _this9._borderValue = 0;
      _this9._cache = {};
      _this9._dataLimitsCached = false;
      _this9.$context = undefined;
      return _this9;
    }

    _createClass(Scale, [{
      key: "init",
      value: function init(options) {
        this.options = options.setContext(this.getContext());
        this.axis = options.axis;
        this._userMin = this.parse(options.min);
        this._userMax = this.parse(options.max);
        this._suggestedMin = this.parse(options.suggestedMin);
        this._suggestedMax = this.parse(options.suggestedMax);
      }
    }, {
      key: "parse",
      value: function parse(raw, index) {
        return raw;
      }
    }, {
      key: "getUserBounds",
      value: function getUserBounds() {
        var _userMin = this._userMin,
            _userMax = this._userMax,
            _suggestedMin = this._suggestedMin,
            _suggestedMax = this._suggestedMax;
        _userMin = finiteOrDefault(_userMin, Number.POSITIVE_INFINITY);
        _userMax = finiteOrDefault(_userMax, Number.NEGATIVE_INFINITY);
        _suggestedMin = finiteOrDefault(_suggestedMin, Number.POSITIVE_INFINITY);
        _suggestedMax = finiteOrDefault(_suggestedMax, Number.NEGATIVE_INFINITY);
        return {
          min: finiteOrDefault(_userMin, _suggestedMin),
          max: finiteOrDefault(_userMax, _suggestedMax),
          minDefined: isNumberFinite(_userMin),
          maxDefined: isNumberFinite(_userMax)
        };
      }
    }, {
      key: "getMinMax",
      value: function getMinMax(canStack) {
        var _this$getUserBounds = this.getUserBounds(),
            min = _this$getUserBounds.min,
            max = _this$getUserBounds.max,
            minDefined = _this$getUserBounds.minDefined,
            maxDefined = _this$getUserBounds.maxDefined;

        var range;

        if (minDefined && maxDefined) {
          return {
            min: min,
            max: max
          };
        }

        var metas = this.getMatchingVisibleMetas();

        for (var i = 0, ilen = metas.length; i < ilen; ++i) {
          range = metas[i].controller.getMinMax(this, canStack);

          if (!minDefined) {
            min = Math.min(min, range.min);
          }

          if (!maxDefined) {
            max = Math.max(max, range.max);
          }
        }

        min = maxDefined && min > max ? max : min;
        max = minDefined && min > max ? min : max;
        return {
          min: finiteOrDefault(min, finiteOrDefault(max, min)),
          max: finiteOrDefault(max, finiteOrDefault(min, max))
        };
      }
    }, {
      key: "getPadding",
      value: function getPadding() {
        return {
          left: this.paddingLeft || 0,
          top: this.paddingTop || 0,
          right: this.paddingRight || 0,
          bottom: this.paddingBottom || 0
        };
      }
    }, {
      key: "getTicks",
      value: function getTicks() {
        return this.ticks;
      }
    }, {
      key: "getLabels",
      value: function getLabels() {
        var data = this.chart.data;
        return this.options.labels || (this.isHorizontal() ? data.xLabels : data.yLabels) || data.labels || [];
      }
    }, {
      key: "beforeLayout",
      value: function beforeLayout() {
        this._cache = {};
        this._dataLimitsCached = false;
      }
    }, {
      key: "beforeUpdate",
      value: function beforeUpdate() {
        callback(this.options.beforeUpdate, [this]);
      }
    }, {
      key: "update",
      value: function update(maxWidth, maxHeight, margins) {
        var _this$options3 = this.options,
            beginAtZero = _this$options3.beginAtZero,
            grace = _this$options3.grace,
            tickOpts = _this$options3.ticks;
        var sampleSize = tickOpts.sampleSize;
        this.beforeUpdate();
        this.maxWidth = maxWidth;
        this.maxHeight = maxHeight;
        this._margins = margins = Object.assign({
          left: 0,
          right: 0,
          top: 0,
          bottom: 0
        }, margins);
        this.ticks = null;
        this._labelSizes = null;
        this._gridLineItems = null;
        this._labelItems = null;
        this.beforeSetDimensions();
        this.setDimensions();
        this.afterSetDimensions();
        this._maxLength = this.isHorizontal() ? this.width + margins.left + margins.right : this.height + margins.top + margins.bottom;

        if (!this._dataLimitsCached) {
          this.beforeDataLimits();
          this.determineDataLimits();
          this.afterDataLimits();
          this._range = _addGrace(this, grace, beginAtZero);
          this._dataLimitsCached = true;
        }

        this.beforeBuildTicks();
        this.ticks = this.buildTicks() || [];
        this.afterBuildTicks();
        var samplingEnabled = sampleSize < this.ticks.length;

        this._convertTicksToLabels(samplingEnabled ? sample(this.ticks, sampleSize) : this.ticks);

        this.configure();
        this.beforeCalculateLabelRotation();
        this.calculateLabelRotation();
        this.afterCalculateLabelRotation();

        if (tickOpts.display && (tickOpts.autoSkip || tickOpts.source === 'auto')) {
          this.ticks = autoSkip(this, this.ticks);
          this._labelSizes = null;
          this.afterAutoSkip();
        }

        if (samplingEnabled) {
          this._convertTicksToLabels(this.ticks);
        }

        this.beforeFit();
        this.fit();
        this.afterFit();
        this.afterUpdate();
      }
    }, {
      key: "configure",
      value: function configure() {
        var reversePixels = this.options.reverse;
        var startPixel, endPixel;

        if (this.isHorizontal()) {
          startPixel = this.left;
          endPixel = this.right;
        } else {
          startPixel = this.top;
          endPixel = this.bottom;
          reversePixels = !reversePixels;
        }

        this._startPixel = startPixel;
        this._endPixel = endPixel;
        this._reversePixels = reversePixels;
        this._length = endPixel - startPixel;
        this._alignToPixels = this.options.alignToPixels;
      }
    }, {
      key: "afterUpdate",
      value: function afterUpdate() {
        callback(this.options.afterUpdate, [this]);
      }
    }, {
      key: "beforeSetDimensions",
      value: function beforeSetDimensions() {
        callback(this.options.beforeSetDimensions, [this]);
      }
    }, {
      key: "setDimensions",
      value: function setDimensions() {
        if (this.isHorizontal()) {
          this.width = this.maxWidth;
          this.left = 0;
          this.right = this.width;
        } else {
          this.height = this.maxHeight;
          this.top = 0;
          this.bottom = this.height;
        }

        this.paddingLeft = 0;
        this.paddingTop = 0;
        this.paddingRight = 0;
        this.paddingBottom = 0;
      }
    }, {
      key: "afterSetDimensions",
      value: function afterSetDimensions() {
        callback(this.options.afterSetDimensions, [this]);
      }
    }, {
      key: "_callHooks",
      value: function _callHooks(name) {
        this.chart.notifyPlugins(name, this.getContext());
        callback(this.options[name], [this]);
      }
    }, {
      key: "beforeDataLimits",
      value: function beforeDataLimits() {
        this._callHooks('beforeDataLimits');
      }
    }, {
      key: "determineDataLimits",
      value: function determineDataLimits() {}
    }, {
      key: "afterDataLimits",
      value: function afterDataLimits() {
        this._callHooks('afterDataLimits');
      }
    }, {
      key: "beforeBuildTicks",
      value: function beforeBuildTicks() {
        this._callHooks('beforeBuildTicks');
      }
    }, {
      key: "buildTicks",
      value: function buildTicks() {
        return [];
      }
    }, {
      key: "afterBuildTicks",
      value: function afterBuildTicks() {
        this._callHooks('afterBuildTicks');
      }
    }, {
      key: "beforeTickToLabelConversion",
      value: function beforeTickToLabelConversion() {
        callback(this.options.beforeTickToLabelConversion, [this]);
      }
    }, {
      key: "generateTickLabels",
      value: function generateTickLabels(ticks) {
        var tickOpts = this.options.ticks;
        var i, ilen, tick;

        for (i = 0, ilen = ticks.length; i < ilen; i++) {
          tick = ticks[i];
          tick.label = callback(tickOpts.callback, [tick.value, i, ticks], this);
        }
      }
    }, {
      key: "afterTickToLabelConversion",
      value: function afterTickToLabelConversion() {
        callback(this.options.afterTickToLabelConversion, [this]);
      }
    }, {
      key: "beforeCalculateLabelRotation",
      value: function beforeCalculateLabelRotation() {
        callback(this.options.beforeCalculateLabelRotation, [this]);
      }
    }, {
      key: "calculateLabelRotation",
      value: function calculateLabelRotation() {
        var options = this.options;
        var tickOpts = options.ticks;
        var numTicks = this.ticks.length;
        var minRotation = tickOpts.minRotation || 0;
        var maxRotation = tickOpts.maxRotation;
        var labelRotation = minRotation;
        var tickWidth, maxHeight, maxLabelDiagonal;

        if (!this._isVisible() || !tickOpts.display || minRotation >= maxRotation || numTicks <= 1 || !this.isHorizontal()) {
          this.labelRotation = minRotation;
          return;
        }

        var labelSizes = this._getLabelSizes();

        var maxLabelWidth = labelSizes.widest.width;
        var maxLabelHeight = labelSizes.highest.height;

        var maxWidth = _limitValue(this.chart.width - maxLabelWidth, 0, this.maxWidth);

        tickWidth = options.offset ? this.maxWidth / numTicks : maxWidth / (numTicks - 1);

        if (maxLabelWidth + 6 > tickWidth) {
          tickWidth = maxWidth / (numTicks - (options.offset ? 0.5 : 1));
          maxHeight = this.maxHeight - getTickMarkLength(options.grid) - tickOpts.padding - getTitleHeight(options.title, this.chart.options.font);
          maxLabelDiagonal = Math.sqrt(maxLabelWidth * maxLabelWidth + maxLabelHeight * maxLabelHeight);
          labelRotation = toDegrees(Math.min(Math.asin(_limitValue((labelSizes.highest.height + 6) / tickWidth, -1, 1)), Math.asin(_limitValue(maxHeight / maxLabelDiagonal, -1, 1)) - Math.asin(_limitValue(maxLabelHeight / maxLabelDiagonal, -1, 1))));
          labelRotation = Math.max(minRotation, Math.min(maxRotation, labelRotation));
        }

        this.labelRotation = labelRotation;
      }
    }, {
      key: "afterCalculateLabelRotation",
      value: function afterCalculateLabelRotation() {
        callback(this.options.afterCalculateLabelRotation, [this]);
      }
    }, {
      key: "afterAutoSkip",
      value: function afterAutoSkip() {}
    }, {
      key: "beforeFit",
      value: function beforeFit() {
        callback(this.options.beforeFit, [this]);
      }
    }, {
      key: "fit",
      value: function fit() {
        var minSize = {
          width: 0,
          height: 0
        };
        var chart = this.chart,
            _this$options4 = this.options,
            tickOpts = _this$options4.ticks,
            titleOpts = _this$options4.title,
            gridOpts = _this$options4.grid;

        var display = this._isVisible();

        var isHorizontal = this.isHorizontal();

        if (display) {
          var titleHeight = getTitleHeight(titleOpts, chart.options.font);

          if (isHorizontal) {
            minSize.width = this.maxWidth;
            minSize.height = getTickMarkLength(gridOpts) + titleHeight;
          } else {
            minSize.height = this.maxHeight;
            minSize.width = getTickMarkLength(gridOpts) + titleHeight;
          }

          if (tickOpts.display && this.ticks.length) {
            var _this$_getLabelSizes = this._getLabelSizes(),
                first = _this$_getLabelSizes.first,
                last = _this$_getLabelSizes.last,
                widest = _this$_getLabelSizes.widest,
                highest = _this$_getLabelSizes.highest;

            var tickPadding = tickOpts.padding * 2;
            var angleRadians = toRadians(this.labelRotation);
            var cos = Math.cos(angleRadians);
            var sin = Math.sin(angleRadians);

            if (isHorizontal) {
              var labelHeight = tickOpts.mirror ? 0 : sin * widest.width + cos * highest.height;
              minSize.height = Math.min(this.maxHeight, minSize.height + labelHeight + tickPadding);
            } else {
              var labelWidth = tickOpts.mirror ? 0 : cos * widest.width + sin * highest.height;
              minSize.width = Math.min(this.maxWidth, minSize.width + labelWidth + tickPadding);
            }

            this._calculatePadding(first, last, sin, cos);
          }
        }

        this._handleMargins();

        if (isHorizontal) {
          this.width = this._length = chart.width - this._margins.left - this._margins.right;
          this.height = minSize.height;
        } else {
          this.width = minSize.width;
          this.height = this._length = chart.height - this._margins.top - this._margins.bottom;
        }
      }
    }, {
      key: "_calculatePadding",
      value: function _calculatePadding(first, last, sin, cos) {
        var _this$options5 = this.options,
            _this$options5$ticks = _this$options5.ticks,
            align = _this$options5$ticks.align,
            padding = _this$options5$ticks.padding,
            position = _this$options5.position;
        var isRotated = this.labelRotation !== 0;
        var labelsBelowTicks = position !== 'top' && this.axis === 'x';

        if (this.isHorizontal()) {
          var offsetLeft = this.getPixelForTick(0) - this.left;
          var offsetRight = this.right - this.getPixelForTick(this.ticks.length - 1);
          var paddingLeft = 0;
          var paddingRight = 0;

          if (isRotated) {
            if (labelsBelowTicks) {
              paddingLeft = cos * first.width;
              paddingRight = sin * last.height;
            } else {
              paddingLeft = sin * first.height;
              paddingRight = cos * last.width;
            }
          } else if (align === 'start') {
            paddingRight = last.width;
          } else if (align === 'end') {
            paddingLeft = first.width;
          } else if (align !== 'inner') {
            paddingLeft = first.width / 2;
            paddingRight = last.width / 2;
          }

          this.paddingLeft = Math.max((paddingLeft - offsetLeft + padding) * this.width / (this.width - offsetLeft), 0);
          this.paddingRight = Math.max((paddingRight - offsetRight + padding) * this.width / (this.width - offsetRight), 0);
        } else {
          var paddingTop = last.height / 2;
          var paddingBottom = first.height / 2;

          if (align === 'start') {
            paddingTop = 0;
            paddingBottom = first.height;
          } else if (align === 'end') {
            paddingTop = last.height;
            paddingBottom = 0;
          }

          this.paddingTop = paddingTop + padding;
          this.paddingBottom = paddingBottom + padding;
        }
      }
    }, {
      key: "_handleMargins",
      value: function _handleMargins() {
        if (this._margins) {
          this._margins.left = Math.max(this.paddingLeft, this._margins.left);
          this._margins.top = Math.max(this.paddingTop, this._margins.top);
          this._margins.right = Math.max(this.paddingRight, this._margins.right);
          this._margins.bottom = Math.max(this.paddingBottom, this._margins.bottom);
        }
      }
    }, {
      key: "afterFit",
      value: function afterFit() {
        callback(this.options.afterFit, [this]);
      }
    }, {
      key: "isHorizontal",
      value: function isHorizontal() {
        var _this$options6 = this.options,
            axis = _this$options6.axis,
            position = _this$options6.position;
        return position === 'top' || position === 'bottom' || axis === 'x';
      }
    }, {
      key: "isFullSize",
      value: function isFullSize() {
        return this.options.fullSize;
      }
    }, {
      key: "_convertTicksToLabels",
      value: function _convertTicksToLabels(ticks) {
        this.beforeTickToLabelConversion();
        this.generateTickLabels(ticks);
        var i, ilen;

        for (i = 0, ilen = ticks.length; i < ilen; i++) {
          if (isNullOrUndef(ticks[i].label)) {
            ticks.splice(i, 1);
            ilen--;
            i--;
          }
        }

        this.afterTickToLabelConversion();
      }
    }, {
      key: "_getLabelSizes",
      value: function _getLabelSizes() {
        var labelSizes = this._labelSizes;

        if (!labelSizes) {
          var sampleSize = this.options.ticks.sampleSize;
          var ticks = this.ticks;

          if (sampleSize < ticks.length) {
            ticks = sample(ticks, sampleSize);
          }

          this._labelSizes = labelSizes = this._computeLabelSizes(ticks, ticks.length);
        }

        return labelSizes;
      }
    }, {
      key: "_computeLabelSizes",
      value: function _computeLabelSizes(ticks, length) {
        var ctx = this.ctx,
            caches = this._longestTextCache;
        var widths = [];
        var heights = [];
        var widestLabelSize = 0;
        var highestLabelSize = 0;
        var i, j, jlen, label, tickFont, fontString, cache, lineHeight, width, height, nestedLabel;

        for (i = 0; i < length; ++i) {
          label = ticks[i].label;
          tickFont = this._resolveTickFontOptions(i);
          ctx.font = fontString = tickFont.string;
          cache = caches[fontString] = caches[fontString] || {
            data: {},
            gc: []
          };
          lineHeight = tickFont.lineHeight;
          width = height = 0;

          if (!isNullOrUndef(label) && !isArray(label)) {
            width = _measureText(ctx, cache.data, cache.gc, width, label);
            height = lineHeight;
          } else if (isArray(label)) {
            for (j = 0, jlen = label.length; j < jlen; ++j) {
              nestedLabel = label[j];

              if (!isNullOrUndef(nestedLabel) && !isArray(nestedLabel)) {
                width = _measureText(ctx, cache.data, cache.gc, width, nestedLabel);
                height += lineHeight;
              }
            }
          }

          widths.push(width);
          heights.push(height);
          widestLabelSize = Math.max(width, widestLabelSize);
          highestLabelSize = Math.max(height, highestLabelSize);
        }

        garbageCollect(caches, length);
        var widest = widths.indexOf(widestLabelSize);
        var highest = heights.indexOf(highestLabelSize);

        var valueAt = function valueAt(idx) {
          return {
            width: widths[idx] || 0,
            height: heights[idx] || 0
          };
        };

        return {
          first: valueAt(0),
          last: valueAt(length - 1),
          widest: valueAt(widest),
          highest: valueAt(highest),
          widths: widths,
          heights: heights
        };
      }
    }, {
      key: "getLabelForValue",
      value: function getLabelForValue(value) {
        return value;
      }
    }, {
      key: "getPixelForValue",
      value: function getPixelForValue(value, index) {
        return NaN;
      }
    }, {
      key: "getValueForPixel",
      value: function getValueForPixel(pixel) {}
    }, {
      key: "getPixelForTick",
      value: function getPixelForTick(index) {
        var ticks = this.ticks;

        if (index < 0 || index > ticks.length - 1) {
          return null;
        }

        return this.getPixelForValue(ticks[index].value);
      }
    }, {
      key: "getPixelForDecimal",
      value: function getPixelForDecimal(decimal) {
        if (this._reversePixels) {
          decimal = 1 - decimal;
        }

        var pixel = this._startPixel + decimal * this._length;
        return _int16Range(this._alignToPixels ? _alignPixel(this.chart, pixel, 0) : pixel);
      }
    }, {
      key: "getDecimalForPixel",
      value: function getDecimalForPixel(pixel) {
        var decimal = (pixel - this._startPixel) / this._length;
        return this._reversePixels ? 1 - decimal : decimal;
      }
    }, {
      key: "getBasePixel",
      value: function getBasePixel() {
        return this.getPixelForValue(this.getBaseValue());
      }
    }, {
      key: "getBaseValue",
      value: function getBaseValue() {
        var min = this.min,
            max = this.max;
        return min < 0 && max < 0 ? max : min > 0 && max > 0 ? min : 0;
      }
    }, {
      key: "getContext",
      value: function getContext(index) {
        var ticks = this.ticks || [];

        if (index >= 0 && index < ticks.length) {
          var tick = ticks[index];
          return tick.$context || (tick.$context = createTickContext(this.getContext(), index, tick));
        }

        return this.$context || (this.$context = createScaleContext(this.chart.getContext(), this));
      }
    }, {
      key: "_tickSize",
      value: function _tickSize() {
        var optionTicks = this.options.ticks;
        var rot = toRadians(this.labelRotation);
        var cos = Math.abs(Math.cos(rot));
        var sin = Math.abs(Math.sin(rot));

        var labelSizes = this._getLabelSizes();

        var padding = optionTicks.autoSkipPadding || 0;
        var w = labelSizes ? labelSizes.widest.width + padding : 0;
        var h = labelSizes ? labelSizes.highest.height + padding : 0;
        return this.isHorizontal() ? h * cos > w * sin ? w / cos : h / sin : h * sin < w * cos ? h / cos : w / sin;
      }
    }, {
      key: "_isVisible",
      value: function _isVisible() {
        var display = this.options.display;

        if (display !== 'auto') {
          return !!display;
        }

        return this.getMatchingVisibleMetas().length > 0;
      }
    }, {
      key: "_computeGridLineItems",
      value: function _computeGridLineItems(chartArea) {
        var axis = this.axis;
        var chart = this.chart;
        var options = this.options;
        var grid = options.grid,
            position = options.position;
        var offset = grid.offset;
        var isHorizontal = this.isHorizontal();
        var ticks = this.ticks;
        var ticksLength = ticks.length + (offset ? 1 : 0);
        var tl = getTickMarkLength(grid);
        var items = [];
        var borderOpts = grid.setContext(this.getContext());
        var axisWidth = borderOpts.drawBorder ? borderOpts.borderWidth : 0;
        var axisHalfWidth = axisWidth / 2;

        var alignBorderValue = function alignBorderValue(pixel) {
          return _alignPixel(chart, pixel, axisWidth);
        };

        var borderValue, i, lineValue, alignedLineValue;
        var tx1, ty1, tx2, ty2, x1, y1, x2, y2;

        if (position === 'top') {
          borderValue = alignBorderValue(this.bottom);
          ty1 = this.bottom - tl;
          ty2 = borderValue - axisHalfWidth;
          y1 = alignBorderValue(chartArea.top) + axisHalfWidth;
          y2 = chartArea.bottom;
        } else if (position === 'bottom') {
          borderValue = alignBorderValue(this.top);
          y1 = chartArea.top;
          y2 = alignBorderValue(chartArea.bottom) - axisHalfWidth;
          ty1 = borderValue + axisHalfWidth;
          ty2 = this.top + tl;
        } else if (position === 'left') {
          borderValue = alignBorderValue(this.right);
          tx1 = this.right - tl;
          tx2 = borderValue - axisHalfWidth;
          x1 = alignBorderValue(chartArea.left) + axisHalfWidth;
          x2 = chartArea.right;
        } else if (position === 'right') {
          borderValue = alignBorderValue(this.left);
          x1 = chartArea.left;
          x2 = alignBorderValue(chartArea.right) - axisHalfWidth;
          tx1 = borderValue + axisHalfWidth;
          tx2 = this.left + tl;
        } else if (axis === 'x') {
          if (position === 'center') {
            borderValue = alignBorderValue((chartArea.top + chartArea.bottom) / 2 + 0.5);
          } else if (isObject(position)) {
            var positionAxisID = Object.keys(position)[0];
            var value = position[positionAxisID];
            borderValue = alignBorderValue(this.chart.scales[positionAxisID].getPixelForValue(value));
          }

          y1 = chartArea.top;
          y2 = chartArea.bottom;
          ty1 = borderValue + axisHalfWidth;
          ty2 = ty1 + tl;
        } else if (axis === 'y') {
          if (position === 'center') {
            borderValue = alignBorderValue((chartArea.left + chartArea.right) / 2);
          } else if (isObject(position)) {
            var _positionAxisID2 = Object.keys(position)[0];
            var _value2 = position[_positionAxisID2];
            borderValue = alignBorderValue(this.chart.scales[_positionAxisID2].getPixelForValue(_value2));
          }

          tx1 = borderValue - axisHalfWidth;
          tx2 = tx1 - tl;
          x1 = chartArea.left;
          x2 = chartArea.right;
        }

        var limit = valueOrDefault(options.ticks.maxTicksLimit, ticksLength);
        var step = Math.max(1, Math.ceil(ticksLength / limit));

        for (i = 0; i < ticksLength; i += step) {
          var optsAtIndex = grid.setContext(this.getContext(i));
          var lineWidth = optsAtIndex.lineWidth;
          var lineColor = optsAtIndex.color;
          var borderDash = optsAtIndex.borderDash || [];
          var borderDashOffset = optsAtIndex.borderDashOffset;
          var tickWidth = optsAtIndex.tickWidth;
          var tickColor = optsAtIndex.tickColor;
          var tickBorderDash = optsAtIndex.tickBorderDash || [];
          var tickBorderDashOffset = optsAtIndex.tickBorderDashOffset;
          lineValue = getPixelForGridLine(this, i, offset);

          if (lineValue === undefined) {
            continue;
          }

          alignedLineValue = _alignPixel(chart, lineValue, lineWidth);

          if (isHorizontal) {
            tx1 = tx2 = x1 = x2 = alignedLineValue;
          } else {
            ty1 = ty2 = y1 = y2 = alignedLineValue;
          }

          items.push({
            tx1: tx1,
            ty1: ty1,
            tx2: tx2,
            ty2: ty2,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            width: lineWidth,
            color: lineColor,
            borderDash: borderDash,
            borderDashOffset: borderDashOffset,
            tickWidth: tickWidth,
            tickColor: tickColor,
            tickBorderDash: tickBorderDash,
            tickBorderDashOffset: tickBorderDashOffset
          });
        }

        this._ticksLength = ticksLength;
        this._borderValue = borderValue;
        return items;
      }
    }, {
      key: "_computeLabelItems",
      value: function _computeLabelItems(chartArea) {
        var axis = this.axis;
        var options = this.options;
        var position = options.position,
            optionTicks = options.ticks;
        var isHorizontal = this.isHorizontal();
        var ticks = this.ticks;
        var align = optionTicks.align,
            crossAlign = optionTicks.crossAlign,
            padding = optionTicks.padding,
            mirror = optionTicks.mirror;
        var tl = getTickMarkLength(options.grid);
        var tickAndPadding = tl + padding;
        var hTickAndPadding = mirror ? -padding : tickAndPadding;
        var rotation = -toRadians(this.labelRotation);
        var items = [];
        var i, ilen, tick, label, x, y, textAlign, pixel, font, lineHeight, lineCount, textOffset;
        var textBaseline = 'middle';

        if (position === 'top') {
          y = this.bottom - hTickAndPadding;
          textAlign = this._getXAxisLabelAlignment();
        } else if (position === 'bottom') {
          y = this.top + hTickAndPadding;
          textAlign = this._getXAxisLabelAlignment();
        } else if (position === 'left') {
          var ret = this._getYAxisLabelAlignment(tl);

          textAlign = ret.textAlign;
          x = ret.x;
        } else if (position === 'right') {
          var _ret = this._getYAxisLabelAlignment(tl);

          textAlign = _ret.textAlign;
          x = _ret.x;
        } else if (axis === 'x') {
          if (position === 'center') {
            y = (chartArea.top + chartArea.bottom) / 2 + tickAndPadding;
          } else if (isObject(position)) {
            var positionAxisID = Object.keys(position)[0];
            var value = position[positionAxisID];
            y = this.chart.scales[positionAxisID].getPixelForValue(value) + tickAndPadding;
          }

          textAlign = this._getXAxisLabelAlignment();
        } else if (axis === 'y') {
          if (position === 'center') {
            x = (chartArea.left + chartArea.right) / 2 - tickAndPadding;
          } else if (isObject(position)) {
            var _positionAxisID3 = Object.keys(position)[0];
            var _value3 = position[_positionAxisID3];
            x = this.chart.scales[_positionAxisID3].getPixelForValue(_value3);
          }

          textAlign = this._getYAxisLabelAlignment(tl).textAlign;
        }

        if (axis === 'y') {
          if (align === 'start') {
            textBaseline = 'top';
          } else if (align === 'end') {
            textBaseline = 'bottom';
          }
        }

        var labelSizes = this._getLabelSizes();

        for (i = 0, ilen = ticks.length; i < ilen; ++i) {
          tick = ticks[i];
          label = tick.label;
          var optsAtIndex = optionTicks.setContext(this.getContext(i));
          pixel = this.getPixelForTick(i) + optionTicks.labelOffset;
          font = this._resolveTickFontOptions(i);
          lineHeight = font.lineHeight;
          lineCount = isArray(label) ? label.length : 1;
          var halfCount = lineCount / 2;
          var color = optsAtIndex.color;
          var strokeColor = optsAtIndex.textStrokeColor;
          var strokeWidth = optsAtIndex.textStrokeWidth;
          var tickTextAlign = textAlign;

          if (isHorizontal) {
            x = pixel;

            if (textAlign === 'inner') {
              if (i === ilen - 1) {
                tickTextAlign = !this.options.reverse ? 'right' : 'left';
              } else if (i === 0) {
                tickTextAlign = !this.options.reverse ? 'left' : 'right';
              } else {
                tickTextAlign = 'center';
              }
            }

            if (position === 'top') {
              if (crossAlign === 'near' || rotation !== 0) {
                textOffset = -lineCount * lineHeight + lineHeight / 2;
              } else if (crossAlign === 'center') {
                textOffset = -labelSizes.highest.height / 2 - halfCount * lineHeight + lineHeight;
              } else {
                textOffset = -labelSizes.highest.height + lineHeight / 2;
              }
            } else {
              if (crossAlign === 'near' || rotation !== 0) {
                textOffset = lineHeight / 2;
              } else if (crossAlign === 'center') {
                textOffset = labelSizes.highest.height / 2 - halfCount * lineHeight;
              } else {
                textOffset = labelSizes.highest.height - lineCount * lineHeight;
              }
            }

            if (mirror) {
              textOffset *= -1;
            }
          } else {
            y = pixel;
            textOffset = (1 - lineCount) * lineHeight / 2;
          }

          var backdrop = void 0;

          if (optsAtIndex.showLabelBackdrop) {
            var labelPadding = toPadding(optsAtIndex.backdropPadding);
            var height = labelSizes.heights[i];
            var width = labelSizes.widths[i];
            var top = y + textOffset - labelPadding.top;
            var left = x - labelPadding.left;

            switch (textBaseline) {
              case 'middle':
                top -= height / 2;
                break;

              case 'bottom':
                top -= height;
                break;
            }

            switch (textAlign) {
              case 'center':
                left -= width / 2;
                break;

              case 'right':
                left -= width;
                break;
            }

            backdrop = {
              left: left,
              top: top,
              width: width + labelPadding.width,
              height: height + labelPadding.height,
              color: optsAtIndex.backdropColor
            };
          }

          items.push({
            rotation: rotation,
            label: label,
            font: font,
            color: color,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            textOffset: textOffset,
            textAlign: tickTextAlign,
            textBaseline: textBaseline,
            translation: [x, y],
            backdrop: backdrop
          });
        }

        return items;
      }
    }, {
      key: "_getXAxisLabelAlignment",
      value: function _getXAxisLabelAlignment() {
        var _this$options7 = this.options,
            position = _this$options7.position,
            ticks = _this$options7.ticks;
        var rotation = -toRadians(this.labelRotation);

        if (rotation) {
          return position === 'top' ? 'left' : 'right';
        }

        var align = 'center';

        if (ticks.align === 'start') {
          align = 'left';
        } else if (ticks.align === 'end') {
          align = 'right';
        } else if (ticks.align === 'inner') {
          align = 'inner';
        }

        return align;
      }
    }, {
      key: "_getYAxisLabelAlignment",
      value: function _getYAxisLabelAlignment(tl) {
        var _this$options8 = this.options,
            position = _this$options8.position,
            _this$options8$ticks = _this$options8.ticks,
            crossAlign = _this$options8$ticks.crossAlign,
            mirror = _this$options8$ticks.mirror,
            padding = _this$options8$ticks.padding;

        var labelSizes = this._getLabelSizes();

        var tickAndPadding = tl + padding;
        var widest = labelSizes.widest.width;
        var textAlign;
        var x;

        if (position === 'left') {
          if (mirror) {
            x = this.right + padding;

            if (crossAlign === 'near') {
              textAlign = 'left';
            } else if (crossAlign === 'center') {
              textAlign = 'center';
              x += widest / 2;
            } else {
              textAlign = 'right';
              x += widest;
            }
          } else {
            x = this.right - tickAndPadding;

            if (crossAlign === 'near') {
              textAlign = 'right';
            } else if (crossAlign === 'center') {
              textAlign = 'center';
              x -= widest / 2;
            } else {
              textAlign = 'left';
              x = this.left;
            }
          }
        } else if (position === 'right') {
          if (mirror) {
            x = this.left + padding;

            if (crossAlign === 'near') {
              textAlign = 'right';
            } else if (crossAlign === 'center') {
              textAlign = 'center';
              x -= widest / 2;
            } else {
              textAlign = 'left';
              x -= widest;
            }
          } else {
            x = this.left + tickAndPadding;

            if (crossAlign === 'near') {
              textAlign = 'left';
            } else if (crossAlign === 'center') {
              textAlign = 'center';
              x += widest / 2;
            } else {
              textAlign = 'right';
              x = this.right;
            }
          }
        } else {
          textAlign = 'right';
        }

        return {
          textAlign: textAlign,
          x: x
        };
      }
    }, {
      key: "_computeLabelArea",
      value: function _computeLabelArea() {
        if (this.options.ticks.mirror) {
          return;
        }

        var chart = this.chart;
        var position = this.options.position;

        if (position === 'left' || position === 'right') {
          return {
            top: 0,
            left: this.left,
            bottom: chart.height,
            right: this.right
          };
        }

        if (position === 'top' || position === 'bottom') {
          return {
            top: this.top,
            left: 0,
            bottom: this.bottom,
            right: chart.width
          };
        }
      }
    }, {
      key: "drawBackground",
      value: function drawBackground() {
        var ctx = this.ctx,
            backgroundColor = this.options.backgroundColor,
            left = this.left,
            top = this.top,
            width = this.width,
            height = this.height;

        if (backgroundColor) {
          ctx.save();
          ctx.fillStyle = backgroundColor;
          ctx.fillRect(left, top, width, height);
          ctx.restore();
        }
      }
    }, {
      key: "getLineWidthForValue",
      value: function getLineWidthForValue(value) {
        var grid = this.options.grid;

        if (!this._isVisible() || !grid.display) {
          return 0;
        }

        var ticks = this.ticks;
        var index = ticks.findIndex(function (t) {
          return t.value === value;
        });

        if (index >= 0) {
          var opts = grid.setContext(this.getContext(index));
          return opts.lineWidth;
        }

        return 0;
      }
    }, {
      key: "drawGrid",
      value: function drawGrid(chartArea) {
        var grid = this.options.grid;
        var ctx = this.ctx;

        var items = this._gridLineItems || (this._gridLineItems = this._computeGridLineItems(chartArea));

        var i, ilen;

        var drawLine = function drawLine(p1, p2, style) {
          if (!style.width || !style.color) {
            return;
          }

          ctx.save();
          ctx.lineWidth = style.width;
          ctx.strokeStyle = style.color;
          ctx.setLineDash(style.borderDash || []);
          ctx.lineDashOffset = style.borderDashOffset;
          ctx.beginPath();
          ctx.moveTo(p1.x, p1.y);
          ctx.lineTo(p2.x, p2.y);
          ctx.stroke();
          ctx.restore();
        };

        if (grid.display) {
          for (i = 0, ilen = items.length; i < ilen; ++i) {
            var item = items[i];

            if (grid.drawOnChartArea) {
              drawLine({
                x: item.x1,
                y: item.y1
              }, {
                x: item.x2,
                y: item.y2
              }, item);
            }

            if (grid.drawTicks) {
              drawLine({
                x: item.tx1,
                y: item.ty1
              }, {
                x: item.tx2,
                y: item.ty2
              }, {
                color: item.tickColor,
                width: item.tickWidth,
                borderDash: item.tickBorderDash,
                borderDashOffset: item.tickBorderDashOffset
              });
            }
          }
        }
      }
    }, {
      key: "drawBorder",
      value: function drawBorder() {
        var chart = this.chart,
            ctx = this.ctx,
            grid = this.options.grid;
        var borderOpts = grid.setContext(this.getContext());
        var axisWidth = grid.drawBorder ? borderOpts.borderWidth : 0;

        if (!axisWidth) {
          return;
        }

        var lastLineWidth = grid.setContext(this.getContext(0)).lineWidth;
        var borderValue = this._borderValue;
        var x1, x2, y1, y2;

        if (this.isHorizontal()) {
          x1 = _alignPixel(chart, this.left, axisWidth) - axisWidth / 2;
          x2 = _alignPixel(chart, this.right, lastLineWidth) + lastLineWidth / 2;
          y1 = y2 = borderValue;
        } else {
          y1 = _alignPixel(chart, this.top, axisWidth) - axisWidth / 2;
          y2 = _alignPixel(chart, this.bottom, lastLineWidth) + lastLineWidth / 2;
          x1 = x2 = borderValue;
        }

        ctx.save();
        ctx.lineWidth = borderOpts.borderWidth;
        ctx.strokeStyle = borderOpts.borderColor;
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
        ctx.restore();
      }
    }, {
      key: "drawLabels",
      value: function drawLabels(chartArea) {
        var optionTicks = this.options.ticks;

        if (!optionTicks.display) {
          return;
        }

        var ctx = this.ctx;

        var area = this._computeLabelArea();

        if (area) {
          clipArea(ctx, area);
        }

        var items = this._labelItems || (this._labelItems = this._computeLabelItems(chartArea));

        var i, ilen;

        for (i = 0, ilen = items.length; i < ilen; ++i) {
          var item = items[i];
          var tickFont = item.font;
          var label = item.label;

          if (item.backdrop) {
            ctx.fillStyle = item.backdrop.color;
            ctx.fillRect(item.backdrop.left, item.backdrop.top, item.backdrop.width, item.backdrop.height);
          }

          var y = item.textOffset;
          renderText(ctx, label, 0, y, tickFont, item);
        }

        if (area) {
          unclipArea(ctx);
        }
      }
    }, {
      key: "drawTitle",
      value: function drawTitle() {
        var ctx = this.ctx,
            _this$options9 = this.options,
            position = _this$options9.position,
            title = _this$options9.title,
            reverse = _this$options9.reverse;

        if (!title.display) {
          return;
        }

        var font = toFont(title.font);
        var padding = toPadding(title.padding);
        var align = title.align;
        var offset = font.lineHeight / 2;

        if (position === 'bottom' || position === 'center' || isObject(position)) {
          offset += padding.bottom;

          if (isArray(title.text)) {
            offset += font.lineHeight * (title.text.length - 1);
          }
        } else {
          offset += padding.top;
        }

        var _titleArgs = titleArgs(this, offset, position, align),
            titleX = _titleArgs.titleX,
            titleY = _titleArgs.titleY,
            maxWidth = _titleArgs.maxWidth,
            rotation = _titleArgs.rotation;

        renderText(ctx, title.text, 0, 0, font, {
          color: title.color,
          maxWidth: maxWidth,
          rotation: rotation,
          textAlign: titleAlign(align, position, reverse),
          textBaseline: 'middle',
          translation: [titleX, titleY]
        });
      }
    }, {
      key: "draw",
      value: function draw(chartArea) {
        if (!this._isVisible()) {
          return;
        }

        this.drawBackground();
        this.drawGrid(chartArea);
        this.drawBorder();
        this.drawTitle();
        this.drawLabels(chartArea);
      }
    }, {
      key: "_layers",
      value: function _layers() {
        var _this10 = this;

        var opts = this.options;
        var tz = opts.ticks && opts.ticks.z || 0;
        var gz = valueOrDefault(opts.grid && opts.grid.z, -1);

        if (!this._isVisible() || this.draw !== Scale.prototype.draw) {
          return [{
            z: tz,
            draw: function draw(chartArea) {
              _this10.draw(chartArea);
            }
          }];
        }

        return [{
          z: gz,
          draw: function draw(chartArea) {
            _this10.drawBackground();

            _this10.drawGrid(chartArea);

            _this10.drawTitle();
          }
        }, {
          z: gz + 1,
          draw: function draw() {
            _this10.drawBorder();
          }
        }, {
          z: tz,
          draw: function draw(chartArea) {
            _this10.drawLabels(chartArea);
          }
        }];
      }
    }, {
      key: "getMatchingVisibleMetas",
      value: function getMatchingVisibleMetas(type) {
        var metas = this.chart.getSortedVisibleDatasetMetas();
        var axisID = this.axis + 'AxisID';
        var result = [];
        var i, ilen;

        for (i = 0, ilen = metas.length; i < ilen; ++i) {
          var meta = metas[i];

          if (meta[axisID] === this.id && (!type || meta.type === type)) {
            result.push(meta);
          }
        }

        return result;
      }
    }, {
      key: "_resolveTickFontOptions",
      value: function _resolveTickFontOptions(index) {
        var opts = this.options.ticks.setContext(this.getContext(index));
        return toFont(opts.font);
      }
    }, {
      key: "_maxDigits",
      value: function _maxDigits() {
        var fontSize = this._resolveTickFontOptions(0).lineHeight;

        return (this.isHorizontal() ? this.width : this.height) / fontSize;
      }
    }]);

    return Scale;
  }(Element);

  var TypedRegistry = /*#__PURE__*/function () {
    function TypedRegistry(type, scope, override) {
      _classCallCheck(this, TypedRegistry);

      this.type = type;
      this.scope = scope;
      this.override = override;
      this.items = Object.create(null);
    }

    _createClass(TypedRegistry, [{
      key: "isForType",
      value: function isForType(type) {
        return Object.prototype.isPrototypeOf.call(this.type.prototype, type.prototype);
      }
    }, {
      key: "register",
      value: function register(item) {
        var proto = Object.getPrototypeOf(item);
        var parentScope;

        if (isIChartComponent(proto)) {
          parentScope = this.register(proto);
        }

        var items = this.items;
        var id = item.id;
        var scope = this.scope + '.' + id;

        if (!id) {
          throw new Error('class does not have id: ' + item);
        }

        if (id in items) {
          return scope;
        }

        items[id] = item;
        registerDefaults(item, scope, parentScope);

        if (this.override) {
          defaults.override(item.id, item.overrides);
        }

        return scope;
      }
    }, {
      key: "get",
      value: function get(id) {
        return this.items[id];
      }
    }, {
      key: "unregister",
      value: function unregister(item) {
        var items = this.items;
        var id = item.id;
        var scope = this.scope;

        if (id in items) {
          delete items[id];
        }

        if (scope && id in defaults[scope]) {
          delete defaults[scope][id];

          if (this.override) {
            delete overrides[id];
          }
        }
      }
    }]);

    return TypedRegistry;
  }();

  function registerDefaults(item, scope, parentScope) {
    var itemDefaults = merge(Object.create(null), [parentScope ? defaults.get(parentScope) : {}, defaults.get(scope), item.defaults]);
    defaults.set(scope, itemDefaults);

    if (item.defaultRoutes) {
      routeDefaults(scope, item.defaultRoutes);
    }

    if (item.descriptors) {
      defaults.describe(scope, item.descriptors);
    }
  }

  function routeDefaults(scope, routes) {
    Object.keys(routes).forEach(function (property) {
      var propertyParts = property.split('.');
      var sourceName = propertyParts.pop();
      var sourceScope = [scope].concat(propertyParts).join('.');
      var parts = routes[property].split('.');
      var targetName = parts.pop();
      var targetScope = parts.join('.');
      defaults.route(sourceScope, sourceName, targetScope, targetName);
    });
  }

  function isIChartComponent(proto) {
    return 'id' in proto && 'defaults' in proto;
  }

  var Registry = /*#__PURE__*/function () {
    function Registry() {
      _classCallCheck(this, Registry);

      this.controllers = new TypedRegistry(DatasetController, 'datasets', true);
      this.elements = new TypedRegistry(Element, 'elements');
      this.plugins = new TypedRegistry(Object, 'plugins');
      this.scales = new TypedRegistry(Scale, 'scales');
      this._typedRegistries = [this.controllers, this.scales, this.elements];
    }

    _createClass(Registry, [{
      key: "add",
      value: function add() {
        for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
          args[_key] = arguments[_key];
        }

        this._each('register', args);
      }
    }, {
      key: "remove",
      value: function remove() {
        for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
          args[_key2] = arguments[_key2];
        }

        this._each('unregister', args);
      }
    }, {
      key: "addControllers",
      value: function addControllers() {
        for (var _len3 = arguments.length, args = new Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
          args[_key3] = arguments[_key3];
        }

        this._each('register', args, this.controllers);
      }
    }, {
      key: "addElements",
      value: function addElements() {
        for (var _len4 = arguments.length, args = new Array(_len4), _key4 = 0; _key4 < _len4; _key4++) {
          args[_key4] = arguments[_key4];
        }

        this._each('register', args, this.elements);
      }
    }, {
      key: "addPlugins",
      value: function addPlugins() {
        for (var _len5 = arguments.length, args = new Array(_len5), _key5 = 0; _key5 < _len5; _key5++) {
          args[_key5] = arguments[_key5];
        }

        this._each('register', args, this.plugins);
      }
    }, {
      key: "addScales",
      value: function addScales() {
        for (var _len6 = arguments.length, args = new Array(_len6), _key6 = 0; _key6 < _len6; _key6++) {
          args[_key6] = arguments[_key6];
        }

        this._each('register', args, this.scales);
      }
    }, {
      key: "getController",
      value: function getController(id) {
        return this._get(id, this.controllers, 'controller');
      }
    }, {
      key: "getElement",
      value: function getElement(id) {
        return this._get(id, this.elements, 'element');
      }
    }, {
      key: "getPlugin",
      value: function getPlugin(id) {
        return this._get(id, this.plugins, 'plugin');
      }
    }, {
      key: "getScale",
      value: function getScale(id) {
        return this._get(id, this.scales, 'scale');
      }
    }, {
      key: "removeControllers",
      value: function removeControllers() {
        for (var _len7 = arguments.length, args = new Array(_len7), _key7 = 0; _key7 < _len7; _key7++) {
          args[_key7] = arguments[_key7];
        }

        this._each('unregister', args, this.controllers);
      }
    }, {
      key: "removeElements",
      value: function removeElements() {
        for (var _len8 = arguments.length, args = new Array(_len8), _key8 = 0; _key8 < _len8; _key8++) {
          args[_key8] = arguments[_key8];
        }

        this._each('unregister', args, this.elements);
      }
    }, {
      key: "removePlugins",
      value: function removePlugins() {
        for (var _len9 = arguments.length, args = new Array(_len9), _key9 = 0; _key9 < _len9; _key9++) {
          args[_key9] = arguments[_key9];
        }

        this._each('unregister', args, this.plugins);
      }
    }, {
      key: "removeScales",
      value: function removeScales() {
        for (var _len10 = arguments.length, args = new Array(_len10), _key10 = 0; _key10 < _len10; _key10++) {
          args[_key10] = arguments[_key10];
        }

        this._each('unregister', args, this.scales);
      }
    }, {
      key: "_each",
      value: function _each(method, args, typedRegistry) {
        var _this11 = this;

        _toConsumableArray(args).forEach(function (arg) {
          var reg = typedRegistry || _this11._getRegistryForType(arg);

          if (typedRegistry || reg.isForType(arg) || reg === _this11.plugins && arg.id) {
            _this11._exec(method, reg, arg);
          } else {
            each(arg, function (item) {
              var itemReg = typedRegistry || _this11._getRegistryForType(item);

              _this11._exec(method, itemReg, item);
            });
          }
        });
      }
    }, {
      key: "_exec",
      value: function _exec(method, registry, component) {
        var camelMethod = _capitalize(method);

        callback(component['before' + camelMethod], [], component);
        registry[method](component);
        callback(component['after' + camelMethod], [], component);
      }
    }, {
      key: "_getRegistryForType",
      value: function _getRegistryForType(type) {
        for (var i = 0; i < this._typedRegistries.length; i++) {
          var reg = this._typedRegistries[i];

          if (reg.isForType(type)) {
            return reg;
          }
        }

        return this.plugins;
      }
    }, {
      key: "_get",
      value: function _get(id, typedRegistry, type) {
        var item = typedRegistry.get(id);

        if (item === undefined) {
          throw new Error('"' + id + '" is not a registered ' + type + '.');
        }

        return item;
      }
    }]);

    return Registry;
  }();

  var registry = new Registry();

  var ScatterController = /*#__PURE__*/function (_DatasetController7) {
    _inherits(ScatterController, _DatasetController7);

    var _super9 = _createSuper(ScatterController);

    function ScatterController() {
      _classCallCheck(this, ScatterController);

      return _super9.apply(this, arguments);
    }

    _createClass(ScatterController, [{
      key: "update",
      value: function update(mode) {
        var meta = this._cachedMeta;
        var _meta$data2 = meta.data,
            points = _meta$data2 === void 0 ? [] : _meta$data2;
        var animationsDisabled = this.chart._animationsDisabled;

        var _getStartAndCountOfVi2 = _getStartAndCountOfVisiblePoints(meta, points, animationsDisabled),
            start = _getStartAndCountOfVi2.start,
            count = _getStartAndCountOfVi2.count;

        this._drawStart = start;
        this._drawCount = count;

        if (_scaleRangesChanged(meta)) {
          start = 0;
          count = points.length;
        }

        if (this.options.showLine) {
          var line = meta.dataset,
              _dataset = meta._dataset;
          line._chart = this.chart;
          line._datasetIndex = this.index;
          line._decimated = !!_dataset._decimated;
          line.points = points;
          var options = this.resolveDatasetElementOptions(mode);
          options.segment = this.options.segment;
          this.updateElement(line, undefined, {
            animated: !animationsDisabled,
            options: options
          }, mode);
        }

        this.updateElements(points, start, count, mode);
      }
    }, {
      key: "addElements",
      value: function addElements() {
        var showLine = this.options.showLine;

        if (!this.datasetElementType && showLine) {
          this.datasetElementType = registry.getElement('line');
        }

        _get(_getPrototypeOf(ScatterController.prototype), "addElements", this).call(this);
      }
    }, {
      key: "updateElements",
      value: function updateElements(points, start, count, mode) {
        var reset = mode === 'reset';
        var _this$_cachedMeta4 = this._cachedMeta,
            iScale = _this$_cachedMeta4.iScale,
            vScale = _this$_cachedMeta4.vScale,
            _stacked = _this$_cachedMeta4._stacked,
            _dataset = _this$_cachedMeta4._dataset;
        var firstOpts = this.resolveDataElementOptions(start, mode);
        var sharedOptions = this.getSharedOptions(firstOpts);
        var includeOptions = this.includeOptions(mode, sharedOptions);
        var iAxis = iScale.axis;
        var vAxis = vScale.axis;
        var _this$options10 = this.options,
            spanGaps = _this$options10.spanGaps,
            segment = _this$options10.segment;
        var maxGapLength = isNumber(spanGaps) ? spanGaps : Number.POSITIVE_INFINITY;
        var directUpdate = this.chart._animationsDisabled || reset || mode === 'none';
        var prevParsed = start > 0 && this.getParsed(start - 1);

        for (var i = start; i < start + count; ++i) {
          var point = points[i];
          var parsed = this.getParsed(i);
          var properties = directUpdate ? point : {};
          var nullData = isNullOrUndef(parsed[vAxis]);
          var iPixel = properties[iAxis] = iScale.getPixelForValue(parsed[iAxis], i);
          var vPixel = properties[vAxis] = reset || nullData ? vScale.getBasePixel() : vScale.getPixelForValue(_stacked ? this.applyStack(vScale, parsed, _stacked) : parsed[vAxis], i);
          properties.skip = isNaN(iPixel) || isNaN(vPixel) || nullData;
          properties.stop = i > 0 && Math.abs(parsed[iAxis] - prevParsed[iAxis]) > maxGapLength;

          if (segment) {
            properties.parsed = parsed;
            properties.raw = _dataset.data[i];
          }

          if (includeOptions) {
            properties.options = sharedOptions || this.resolveDataElementOptions(i, point.active ? 'active' : mode);
          }

          if (!directUpdate) {
            this.updateElement(point, i, properties, mode);
          }

          prevParsed = parsed;
        }

        this.updateSharedOptions(sharedOptions, mode, firstOpts);
      }
    }, {
      key: "getMaxOverflow",
      value: function getMaxOverflow() {
        var meta = this._cachedMeta;
        var data = meta.data || [];

        if (!this.options.showLine) {
          var max = 0;

          for (var i = data.length - 1; i >= 0; --i) {
            max = Math.max(max, data[i].size(this.resolveDataElementOptions(i)) / 2);
          }

          return max > 0 && max;
        }

        var dataset = meta.dataset;
        var border = dataset.options && dataset.options.borderWidth || 0;

        if (!data.length) {
          return border;
        }

        var firstPoint = data[0].size(this.resolveDataElementOptions(0));
        var lastPoint = data[data.length - 1].size(this.resolveDataElementOptions(data.length - 1));
        return Math.max(border, firstPoint, lastPoint) / 2;
      }
    }]);

    return ScatterController;
  }(DatasetController);

  ScatterController.id = 'scatter';
  ScatterController.defaults = {
    datasetElementType: false,
    dataElementType: 'point',
    showLine: false,
    fill: false
  };
  ScatterController.overrides = {
    interaction: {
      mode: 'point'
    },
    plugins: {
      tooltip: {
        callbacks: {
          title: function title() {
            return '';
          },
          label: function label(item) {
            return '(' + item.label + ', ' + item.formattedValue + ')';
          }
        }
      }
    },
    scales: {
      x: {
        type: 'linear'
      },
      y: {
        type: 'linear'
      }
    }
  };
  var controllers = /*#__PURE__*/Object.freeze({
    __proto__: null,
    BarController: BarController,
    BubbleController: BubbleController,
    DoughnutController: DoughnutController,
    LineController: LineController,
    PolarAreaController: PolarAreaController,
    PieController: PieController,
    RadarController: RadarController,
    ScatterController: ScatterController
  });

  function abstract() {
    throw new Error('This method is not implemented: Check that a complete date adapter is provided.');
  }

  var DateAdapter = /*#__PURE__*/function () {
    function DateAdapter(options) {
      _classCallCheck(this, DateAdapter);

      this.options = options || {};
    }

    _createClass(DateAdapter, [{
      key: "init",
      value: function init(chartOptions) {}
    }, {
      key: "formats",
      value: function formats() {
        return abstract();
      }
    }, {
      key: "parse",
      value: function parse(value, format) {
        return abstract();
      }
    }, {
      key: "format",
      value: function format(timestamp, _format) {
        return abstract();
      }
    }, {
      key: "add",
      value: function add(timestamp, amount, unit) {
        return abstract();
      }
    }, {
      key: "diff",
      value: function diff(a, b, unit) {
        return abstract();
      }
    }, {
      key: "startOf",
      value: function startOf(timestamp, unit, weekday) {
        return abstract();
      }
    }, {
      key: "endOf",
      value: function endOf(timestamp, unit) {
        return abstract();
      }
    }]);

    return DateAdapter;
  }();

  DateAdapter.override = function (members) {
    Object.assign(DateAdapter.prototype, members);
  };

  var adapters = {
    _date: DateAdapter
  };

  function binarySearch(metaset, axis, value, intersect) {
    var controller = metaset.controller,
        data = metaset.data,
        _sorted = metaset._sorted;
    var iScale = controller._cachedMeta.iScale;

    if (iScale && axis === iScale.axis && axis !== 'r' && _sorted && data.length) {
      var lookupMethod = iScale._reversePixels ? _rlookupByKey : _lookupByKey;

      if (!intersect) {
        return lookupMethod(data, axis, value);
      } else if (controller._sharedOptions) {
        var el = data[0];
        var range = typeof el.getRange === 'function' && el.getRange(axis);

        if (range) {
          var start = lookupMethod(data, axis, value - range);
          var end = lookupMethod(data, axis, value + range);
          return {
            lo: start.lo,
            hi: end.hi
          };
        }
      }
    }

    return {
      lo: 0,
      hi: data.length - 1
    };
  }

  function evaluateInteractionItems(chart, axis, position, handler, intersect) {
    var metasets = chart.getSortedVisibleDatasetMetas();
    var value = position[axis];

    for (var i = 0, ilen = metasets.length; i < ilen; ++i) {
      var _metasets$i = metasets[i],
          _index2 = _metasets$i.index,
          data = _metasets$i.data;

      var _binarySearch = binarySearch(metasets[i], axis, value, intersect),
          lo = _binarySearch.lo,
          hi = _binarySearch.hi;

      for (var j = lo; j <= hi; ++j) {
        var element = data[j];

        if (!element.skip) {
          handler(element, _index2, j);
        }
      }
    }
  }

  function getDistanceMetricForAxis(axis) {
    var useX = axis.indexOf('x') !== -1;
    var useY = axis.indexOf('y') !== -1;
    return function (pt1, pt2) {
      var deltaX = useX ? Math.abs(pt1.x - pt2.x) : 0;
      var deltaY = useY ? Math.abs(pt1.y - pt2.y) : 0;
      return Math.sqrt(Math.pow(deltaX, 2) + Math.pow(deltaY, 2));
    };
  }

  function getIntersectItems(chart, position, axis, useFinalPosition, includeInvisible) {
    var items = [];

    if (!includeInvisible && !chart.isPointInArea(position)) {
      return items;
    }

    var evaluationFunc = function evaluationFunc(element, datasetIndex, index) {
      if (!includeInvisible && !_isPointInArea(element, chart.chartArea, 0)) {
        return;
      }

      if (element.inRange(position.x, position.y, useFinalPosition)) {
        items.push({
          element: element,
          datasetIndex: datasetIndex,
          index: index
        });
      }
    };

    evaluateInteractionItems(chart, axis, position, evaluationFunc, true);
    return items;
  }

  function getNearestRadialItems(chart, position, axis, useFinalPosition) {
    var items = [];

    function evaluationFunc(element, datasetIndex, index) {
      var _element$getProps = element.getProps(['startAngle', 'endAngle'], useFinalPosition),
          startAngle = _element$getProps.startAngle,
          endAngle = _element$getProps.endAngle;

      var _getAngleFromPoint = getAngleFromPoint(element, {
        x: position.x,
        y: position.y
      }),
          angle = _getAngleFromPoint.angle;

      if (_angleBetween(angle, startAngle, endAngle)) {
        items.push({
          element: element,
          datasetIndex: datasetIndex,
          index: index
        });
      }
    }

    evaluateInteractionItems(chart, axis, position, evaluationFunc);
    return items;
  }

  function getNearestCartesianItems(chart, position, axis, intersect, useFinalPosition, includeInvisible) {
    var items = [];
    var distanceMetric = getDistanceMetricForAxis(axis);
    var minDistance = Number.POSITIVE_INFINITY;

    function evaluationFunc(element, datasetIndex, index) {
      var inRange = element.inRange(position.x, position.y, useFinalPosition);

      if (intersect && !inRange) {
        return;
      }

      var center = element.getCenterPoint(useFinalPosition);
      var pointInArea = !!includeInvisible || chart.isPointInArea(center);

      if (!pointInArea && !inRange) {
        return;
      }

      var distance = distanceMetric(position, center);

      if (distance < minDistance) {
        items = [{
          element: element,
          datasetIndex: datasetIndex,
          index: index
        }];
        minDistance = distance;
      } else if (distance === minDistance) {
        items.push({
          element: element,
          datasetIndex: datasetIndex,
          index: index
        });
      }
    }

    evaluateInteractionItems(chart, axis, position, evaluationFunc);
    return items;
  }

  function getNearestItems(chart, position, axis, intersect, useFinalPosition, includeInvisible) {
    if (!includeInvisible && !chart.isPointInArea(position)) {
      return [];
    }

    return axis === 'r' && !intersect ? getNearestRadialItems(chart, position, axis, useFinalPosition) : getNearestCartesianItems(chart, position, axis, intersect, useFinalPosition, includeInvisible);
  }

  function getAxisItems(chart, position, axis, intersect, useFinalPosition) {
    var items = [];
    var rangeMethod = axis === 'x' ? 'inXRange' : 'inYRange';
    var intersectsItem = false;
    evaluateInteractionItems(chart, axis, position, function (element, datasetIndex, index) {
      if (element[rangeMethod](position[axis], useFinalPosition)) {
        items.push({
          element: element,
          datasetIndex: datasetIndex,
          index: index
        });
        intersectsItem = intersectsItem || element.inRange(position.x, position.y, useFinalPosition);
      }
    });

    if (intersect && !intersectsItem) {
      return [];
    }

    return items;
  }

  var Interaction = {
    evaluateInteractionItems: evaluateInteractionItems,
    modes: {
      index: function index(chart, e, options, useFinalPosition) {
        var position = getRelativePosition(e, chart);
        var axis = options.axis || 'x';
        var includeInvisible = options.includeInvisible || false;
        var items = options.intersect ? getIntersectItems(chart, position, axis, useFinalPosition, includeInvisible) : getNearestItems(chart, position, axis, false, useFinalPosition, includeInvisible);
        var elements = [];

        if (!items.length) {
          return [];
        }

        chart.getSortedVisibleDatasetMetas().forEach(function (meta) {
          var index = items[0].index;
          var element = meta.data[index];

          if (element && !element.skip) {
            elements.push({
              element: element,
              datasetIndex: meta.index,
              index: index
            });
          }
        });
        return elements;
      },
      dataset: function dataset(chart, e, options, useFinalPosition) {
        var position = getRelativePosition(e, chart);
        var axis = options.axis || 'xy';
        var includeInvisible = options.includeInvisible || false;
        var items = options.intersect ? getIntersectItems(chart, position, axis, useFinalPosition, includeInvisible) : getNearestItems(chart, position, axis, false, useFinalPosition, includeInvisible);

        if (items.length > 0) {
          var datasetIndex = items[0].datasetIndex;
          var data = chart.getDatasetMeta(datasetIndex).data;
          items = [];

          for (var i = 0; i < data.length; ++i) {
            items.push({
              element: data[i],
              datasetIndex: datasetIndex,
              index: i
            });
          }
        }

        return items;
      },
      point: function point(chart, e, options, useFinalPosition) {
        var position = getRelativePosition(e, chart);
        var axis = options.axis || 'xy';
        var includeInvisible = options.includeInvisible || false;
        return getIntersectItems(chart, position, axis, useFinalPosition, includeInvisible);
      },
      nearest: function nearest(chart, e, options, useFinalPosition) {
        var position = getRelativePosition(e, chart);
        var axis = options.axis || 'xy';
        var includeInvisible = options.includeInvisible || false;
        return getNearestItems(chart, position, axis, options.intersect, useFinalPosition, includeInvisible);
      },
      x: function x(chart, e, options, useFinalPosition) {
        var position = getRelativePosition(e, chart);
        return getAxisItems(chart, position, 'x', options.intersect, useFinalPosition);
      },
      y: function y(chart, e, options, useFinalPosition) {
        var position = getRelativePosition(e, chart);
        return getAxisItems(chart, position, 'y', options.intersect, useFinalPosition);
      }
    }
  };
  var STATIC_POSITIONS = ['left', 'top', 'right', 'bottom'];

  function filterByPosition(array, position) {
    return array.filter(function (v) {
      return v.pos === position;
    });
  }

  function filterDynamicPositionByAxis(array, axis) {
    return array.filter(function (v) {
      return STATIC_POSITIONS.indexOf(v.pos) === -1 && v.box.axis === axis;
    });
  }

  function sortByWeight(array, reverse) {
    return array.sort(function (a, b) {
      var v0 = reverse ? b : a;
      var v1 = reverse ? a : b;
      return v0.weight === v1.weight ? v0.index - v1.index : v0.weight - v1.weight;
    });
  }

  function wrapBoxes(boxes) {
    var layoutBoxes = [];
    var i, ilen, box, pos, stack, stackWeight;

    for (i = 0, ilen = (boxes || []).length; i < ilen; ++i) {
      box = boxes[i];
      var _box = box;
      pos = _box.position;
      var _box$options = _box.options;
      stack = _box$options.stack;
      var _box$options$stackWei = _box$options.stackWeight;
      stackWeight = _box$options$stackWei === void 0 ? 1 : _box$options$stackWei;
      layoutBoxes.push({
        index: i,
        box: box,
        pos: pos,
        horizontal: box.isHorizontal(),
        weight: box.weight,
        stack: stack && pos + stack,
        stackWeight: stackWeight
      });
    }

    return layoutBoxes;
  }

  function buildStacks(layouts) {
    var stacks = {};

    var _iterator6 = _createForOfIteratorHelper(layouts),
        _step6;

    try {
      for (_iterator6.s(); !(_step6 = _iterator6.n()).done;) {
        var wrap = _step6.value;
        var stack = wrap.stack,
            pos = wrap.pos,
            stackWeight = wrap.stackWeight;

        if (!stack || !STATIC_POSITIONS.includes(pos)) {
          continue;
        }

        var _stack = stacks[stack] || (stacks[stack] = {
          count: 0,
          placed: 0,
          weight: 0,
          size: 0
        });

        _stack.count++;
        _stack.weight += stackWeight;
      }
    } catch (err) {
      _iterator6.e(err);
    } finally {
      _iterator6.f();
    }

    return stacks;
  }

  function setLayoutDims(layouts, params) {
    var stacks = buildStacks(layouts);
    var vBoxMaxWidth = params.vBoxMaxWidth,
        hBoxMaxHeight = params.hBoxMaxHeight;
    var i, ilen, layout;

    for (i = 0, ilen = layouts.length; i < ilen; ++i) {
      layout = layouts[i];
      var fullSize = layout.box.fullSize;
      var stack = stacks[layout.stack];
      var factor = stack && layout.stackWeight / stack.weight;

      if (layout.horizontal) {
        layout.width = factor ? factor * vBoxMaxWidth : fullSize && params.availableWidth;
        layout.height = hBoxMaxHeight;
      } else {
        layout.width = vBoxMaxWidth;
        layout.height = factor ? factor * hBoxMaxHeight : fullSize && params.availableHeight;
      }
    }

    return stacks;
  }

  function buildLayoutBoxes(boxes) {
    var layoutBoxes = wrapBoxes(boxes);
    var fullSize = sortByWeight(layoutBoxes.filter(function (wrap) {
      return wrap.box.fullSize;
    }), true);
    var left = sortByWeight(filterByPosition(layoutBoxes, 'left'), true);
    var right = sortByWeight(filterByPosition(layoutBoxes, 'right'));
    var top = sortByWeight(filterByPosition(layoutBoxes, 'top'), true);
    var bottom = sortByWeight(filterByPosition(layoutBoxes, 'bottom'));
    var centerHorizontal = filterDynamicPositionByAxis(layoutBoxes, 'x');
    var centerVertical = filterDynamicPositionByAxis(layoutBoxes, 'y');
    return {
      fullSize: fullSize,
      leftAndTop: left.concat(top),
      rightAndBottom: right.concat(centerVertical).concat(bottom).concat(centerHorizontal),
      chartArea: filterByPosition(layoutBoxes, 'chartArea'),
      vertical: left.concat(right).concat(centerVertical),
      horizontal: top.concat(bottom).concat(centerHorizontal)
    };
  }

  function getCombinedMax(maxPadding, chartArea, a, b) {
    return Math.max(maxPadding[a], chartArea[a]) + Math.max(maxPadding[b], chartArea[b]);
  }

  function updateMaxPadding(maxPadding, boxPadding) {
    maxPadding.top = Math.max(maxPadding.top, boxPadding.top);
    maxPadding.left = Math.max(maxPadding.left, boxPadding.left);
    maxPadding.bottom = Math.max(maxPadding.bottom, boxPadding.bottom);
    maxPadding.right = Math.max(maxPadding.right, boxPadding.right);
  }

  function updateDims(chartArea, params, layout, stacks) {
    var pos = layout.pos,
        box = layout.box;
    var maxPadding = chartArea.maxPadding;

    if (!isObject(pos)) {
      if (layout.size) {
        chartArea[pos] -= layout.size;
      }

      var stack = stacks[layout.stack] || {
        size: 0,
        count: 1
      };
      stack.size = Math.max(stack.size, layout.horizontal ? box.height : box.width);
      layout.size = stack.size / stack.count;
      chartArea[pos] += layout.size;
    }

    if (box.getPadding) {
      updateMaxPadding(maxPadding, box.getPadding());
    }

    var newWidth = Math.max(0, params.outerWidth - getCombinedMax(maxPadding, chartArea, 'left', 'right'));
    var newHeight = Math.max(0, params.outerHeight - getCombinedMax(maxPadding, chartArea, 'top', 'bottom'));
    var widthChanged = newWidth !== chartArea.w;
    var heightChanged = newHeight !== chartArea.h;
    chartArea.w = newWidth;
    chartArea.h = newHeight;
    return layout.horizontal ? {
      same: widthChanged,
      other: heightChanged
    } : {
      same: heightChanged,
      other: widthChanged
    };
  }

  function handleMaxPadding(chartArea) {
    var maxPadding = chartArea.maxPadding;

    function updatePos(pos) {
      var change = Math.max(maxPadding[pos] - chartArea[pos], 0);
      chartArea[pos] += change;
      return change;
    }

    chartArea.y += updatePos('top');
    chartArea.x += updatePos('left');
    updatePos('right');
    updatePos('bottom');
  }

  function getMargins(horizontal, chartArea) {
    var maxPadding = chartArea.maxPadding;

    function marginForPositions(positions) {
      var margin = {
        left: 0,
        top: 0,
        right: 0,
        bottom: 0
      };
      positions.forEach(function (pos) {
        margin[pos] = Math.max(chartArea[pos], maxPadding[pos]);
      });
      return margin;
    }

    return horizontal ? marginForPositions(['left', 'right']) : marginForPositions(['top', 'bottom']);
  }

  function fitBoxes(boxes, chartArea, params, stacks) {
    var refitBoxes = [];
    var i, ilen, layout, box, refit, changed;

    for (i = 0, ilen = boxes.length, refit = 0; i < ilen; ++i) {
      layout = boxes[i];
      box = layout.box;
      box.update(layout.width || chartArea.w, layout.height || chartArea.h, getMargins(layout.horizontal, chartArea));

      var _updateDims = updateDims(chartArea, params, layout, stacks),
          same = _updateDims.same,
          other = _updateDims.other;

      refit |= same && refitBoxes.length;
      changed = changed || other;

      if (!box.fullSize) {
        refitBoxes.push(layout);
      }
    }

    return refit && fitBoxes(refitBoxes, chartArea, params, stacks) || changed;
  }

  function setBoxDims(box, left, top, width, height) {
    box.top = top;
    box.left = left;
    box.right = left + width;
    box.bottom = top + height;
    box.width = width;
    box.height = height;
  }

  function placeBoxes(boxes, chartArea, params, stacks) {
    var userPadding = params.padding;
    var x = chartArea.x,
        y = chartArea.y;

    var _iterator7 = _createForOfIteratorHelper(boxes),
        _step7;

    try {
      for (_iterator7.s(); !(_step7 = _iterator7.n()).done;) {
        var layout = _step7.value;
        var box = layout.box;
        var stack = stacks[layout.stack] || {
          count: 1,
          placed: 0,
          weight: 1
        };
        var weight = layout.stackWeight / stack.weight || 1;

        if (layout.horizontal) {
          var width = chartArea.w * weight;
          var height = stack.size || box.height;

          if (defined(stack.start)) {
            y = stack.start;
          }

          if (box.fullSize) {
            setBoxDims(box, userPadding.left, y, params.outerWidth - userPadding.right - userPadding.left, height);
          } else {
            setBoxDims(box, chartArea.left + stack.placed, y, width, height);
          }

          stack.start = y;
          stack.placed += width;
          y = box.bottom;
        } else {
          var _height = chartArea.h * weight;

          var _width = stack.size || box.width;

          if (defined(stack.start)) {
            x = stack.start;
          }

          if (box.fullSize) {
            setBoxDims(box, x, userPadding.top, _width, params.outerHeight - userPadding.bottom - userPadding.top);
          } else {
            setBoxDims(box, x, chartArea.top + stack.placed, _width, _height);
          }

          stack.start = x;
          stack.placed += _height;
          x = box.right;
        }
      }
    } catch (err) {
      _iterator7.e(err);
    } finally {
      _iterator7.f();
    }

    chartArea.x = x;
    chartArea.y = y;
  }

  defaults.set('layout', {
    autoPadding: true,
    padding: {
      top: 0,
      right: 0,
      bottom: 0,
      left: 0
    }
  });
  var layouts = {
    addBox: function addBox(chart, item) {
      if (!chart.boxes) {
        chart.boxes = [];
      }

      item.fullSize = item.fullSize || false;
      item.position = item.position || 'top';
      item.weight = item.weight || 0;

      item._layers = item._layers || function () {
        return [{
          z: 0,
          draw: function draw(chartArea) {
            item.draw(chartArea);
          }
        }];
      };

      chart.boxes.push(item);
    },
    removeBox: function removeBox(chart, layoutItem) {
      var index = chart.boxes ? chart.boxes.indexOf(layoutItem) : -1;

      if (index !== -1) {
        chart.boxes.splice(index, 1);
      }
    },
    configure: function configure(chart, item, options) {
      item.fullSize = options.fullSize;
      item.position = options.position;
      item.weight = options.weight;
    },
    update: function update(chart, width, height, minPadding) {
      if (!chart) {
        return;
      }

      var padding = toPadding(chart.options.layout.padding);
      var availableWidth = Math.max(width - padding.width, 0);
      var availableHeight = Math.max(height - padding.height, 0);
      var boxes = buildLayoutBoxes(chart.boxes);
      var verticalBoxes = boxes.vertical;
      var horizontalBoxes = boxes.horizontal;
      each(chart.boxes, function (box) {
        if (typeof box.beforeLayout === 'function') {
          box.beforeLayout();
        }
      });
      var visibleVerticalBoxCount = verticalBoxes.reduce(function (total, wrap) {
        return wrap.box.options && wrap.box.options.display === false ? total : total + 1;
      }, 0) || 1;
      var params = Object.freeze({
        outerWidth: width,
        outerHeight: height,
        padding: padding,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        vBoxMaxWidth: availableWidth / 2 / visibleVerticalBoxCount,
        hBoxMaxHeight: availableHeight / 2
      });
      var maxPadding = Object.assign({}, padding);
      updateMaxPadding(maxPadding, toPadding(minPadding));
      var chartArea = Object.assign({
        maxPadding: maxPadding,
        w: availableWidth,
        h: availableHeight,
        x: padding.left,
        y: padding.top
      }, padding);
      var stacks = setLayoutDims(verticalBoxes.concat(horizontalBoxes), params);
      fitBoxes(boxes.fullSize, chartArea, params, stacks);
      fitBoxes(verticalBoxes, chartArea, params, stacks);

      if (fitBoxes(horizontalBoxes, chartArea, params, stacks)) {
        fitBoxes(verticalBoxes, chartArea, params, stacks);
      }

      handleMaxPadding(chartArea);
      placeBoxes(boxes.leftAndTop, chartArea, params, stacks);
      chartArea.x += chartArea.w;
      chartArea.y += chartArea.h;
      placeBoxes(boxes.rightAndBottom, chartArea, params, stacks);
      chart.chartArea = {
        left: chartArea.left,
        top: chartArea.top,
        right: chartArea.left + chartArea.w,
        bottom: chartArea.top + chartArea.h,
        height: chartArea.h,
        width: chartArea.w
      };
      each(boxes.chartArea, function (layout) {
        var box = layout.box;
        Object.assign(box, chart.chartArea);
        box.update(chartArea.w, chartArea.h, {
          left: 0,
          top: 0,
          right: 0,
          bottom: 0
        });
      });
    }
  };

  var BasePlatform = /*#__PURE__*/function () {
    function BasePlatform() {
      _classCallCheck(this, BasePlatform);
    }

    _createClass(BasePlatform, [{
      key: "acquireContext",
      value: function acquireContext(canvas, aspectRatio) {}
    }, {
      key: "releaseContext",
      value: function releaseContext(context) {
        return false;
      }
    }, {
      key: "addEventListener",
      value: function addEventListener(chart, type, listener) {}
    }, {
      key: "removeEventListener",
      value: function removeEventListener(chart, type, listener) {}
    }, {
      key: "getDevicePixelRatio",
      value: function getDevicePixelRatio() {
        return 1;
      }
    }, {
      key: "getMaximumSize",
      value: function getMaximumSize(element, width, height, aspectRatio) {
        width = Math.max(0, width || element.width);
        height = height || element.height;
        return {
          width: width,
          height: Math.max(0, aspectRatio ? Math.floor(width / aspectRatio) : height)
        };
      }
    }, {
      key: "isAttached",
      value: function isAttached(canvas) {
        return true;
      }
    }, {
      key: "updateConfig",
      value: function updateConfig(config) {}
    }]);

    return BasePlatform;
  }();

  var BasicPlatform = /*#__PURE__*/function (_BasePlatform) {
    _inherits(BasicPlatform, _BasePlatform);

    var _super10 = _createSuper(BasicPlatform);

    function BasicPlatform() {
      _classCallCheck(this, BasicPlatform);

      return _super10.apply(this, arguments);
    }

    _createClass(BasicPlatform, [{
      key: "acquireContext",
      value: function acquireContext(item) {
        return item && item.getContext && item.getContext('2d') || null;
      }
    }, {
      key: "updateConfig",
      value: function updateConfig(config) {
        config.options.animation = false;
      }
    }]);

    return BasicPlatform;
  }(BasePlatform);

  var EXPANDO_KEY = '$chartjs';
  var EVENT_TYPES = {
    touchstart: 'mousedown',
    touchmove: 'mousemove',
    touchend: 'mouseup',
    pointerenter: 'mouseenter',
    pointerdown: 'mousedown',
    pointermove: 'mousemove',
    pointerup: 'mouseup',
    pointerleave: 'mouseout',
    pointerout: 'mouseout'
  };

  var isNullOrEmpty = function isNullOrEmpty(value) {
    return value === null || value === '';
  };

  function initCanvas(canvas, aspectRatio) {
    var style = canvas.style;
    var renderHeight = canvas.getAttribute('height');
    var renderWidth = canvas.getAttribute('width');
    canvas[EXPANDO_KEY] = {
      initial: {
        height: renderHeight,
        width: renderWidth,
        style: {
          display: style.display,
          height: style.height,
          width: style.width
        }
      }
    };
    style.display = style.display || 'block';
    style.boxSizing = style.boxSizing || 'border-box';

    if (isNullOrEmpty(renderWidth)) {
      var displayWidth = readUsedSize(canvas, 'width');

      if (displayWidth !== undefined) {
        canvas.width = displayWidth;
      }
    }

    if (isNullOrEmpty(renderHeight)) {
      if (canvas.style.height === '') {
        canvas.height = canvas.width / (aspectRatio || 2);
      } else {
        var displayHeight = readUsedSize(canvas, 'height');

        if (displayHeight !== undefined) {
          canvas.height = displayHeight;
        }
      }
    }

    return canvas;
  }

  var eventListenerOptions = supportsEventListenerOptions ? {
    passive: true
  } : false;

  function addListener(node, type, listener) {
    node.addEventListener(type, listener, eventListenerOptions);
  }

  function removeListener(chart, type, listener) {
    chart.canvas.removeEventListener(type, listener, eventListenerOptions);
  }

  function fromNativeEvent(event, chart) {
    var type = EVENT_TYPES[event.type] || event.type;

    var _getRelativePosition = getRelativePosition(event, chart),
        x = _getRelativePosition.x,
        y = _getRelativePosition.y;

    return {
      type: type,
      chart: chart,
      native: event,
      x: x !== undefined ? x : null,
      y: y !== undefined ? y : null
    };
  }

  function nodeListContains(nodeList, canvas) {
    var _iterator8 = _createForOfIteratorHelper(nodeList),
        _step8;

    try {
      for (_iterator8.s(); !(_step8 = _iterator8.n()).done;) {
        var node = _step8.value;

        if (node === canvas || node.contains(canvas)) {
          return true;
        }
      }
    } catch (err) {
      _iterator8.e(err);
    } finally {
      _iterator8.f();
    }
  }

  function createAttachObserver(chart, type, listener) {
    var canvas = chart.canvas;
    var observer = new MutationObserver(function (entries) {
      var trigger = false;

      var _iterator9 = _createForOfIteratorHelper(entries),
          _step9;

      try {
        for (_iterator9.s(); !(_step9 = _iterator9.n()).done;) {
          var entry = _step9.value;
          trigger = trigger || nodeListContains(entry.addedNodes, canvas);
          trigger = trigger && !nodeListContains(entry.removedNodes, canvas);
        }
      } catch (err) {
        _iterator9.e(err);
      } finally {
        _iterator9.f();
      }

      if (trigger) {
        listener();
      }
    });
    observer.observe(document, {
      childList: true,
      subtree: true
    });
    return observer;
  }

  function createDetachObserver(chart, type, listener) {
    var canvas = chart.canvas;
    var observer = new MutationObserver(function (entries) {
      var trigger = false;

      var _iterator10 = _createForOfIteratorHelper(entries),
          _step10;

      try {
        for (_iterator10.s(); !(_step10 = _iterator10.n()).done;) {
          var entry = _step10.value;
          trigger = trigger || nodeListContains(entry.removedNodes, canvas);
          trigger = trigger && !nodeListContains(entry.addedNodes, canvas);
        }
      } catch (err) {
        _iterator10.e(err);
      } finally {
        _iterator10.f();
      }

      if (trigger) {
        listener();
      }
    });
    observer.observe(document, {
      childList: true,
      subtree: true
    });
    return observer;
  }

  var drpListeningCharts = new Map();
  var oldDevicePixelRatio = 0;

  function onWindowResize() {
    var dpr = window.devicePixelRatio;

    if (dpr === oldDevicePixelRatio) {
      return;
    }

    oldDevicePixelRatio = dpr;
    drpListeningCharts.forEach(function (resize, chart) {
      if (chart.currentDevicePixelRatio !== dpr) {
        resize();
      }
    });
  }

  function listenDevicePixelRatioChanges(chart, resize) {
    if (!drpListeningCharts.size) {
      window.addEventListener('resize', onWindowResize);
    }

    drpListeningCharts.set(chart, resize);
  }

  function unlistenDevicePixelRatioChanges(chart) {
    drpListeningCharts.delete(chart);

    if (!drpListeningCharts.size) {
      window.removeEventListener('resize', onWindowResize);
    }
  }

  function createResizeObserver(chart, type, listener) {
    var canvas = chart.canvas;

    var container = canvas && _getParentNode(canvas);

    if (!container) {
      return;
    }

    var resize = throttled(function (width, height) {
      var w = container.clientWidth;
      listener(width, height);

      if (w < container.clientWidth) {
        listener();
      }
    }, window);
    var observer = new ResizeObserver(function (entries) {
      var entry = entries[0];
      var width = entry.contentRect.width;
      var height = entry.contentRect.height;

      if (width === 0 && height === 0) {
        return;
      }

      resize(width, height);
    });
    observer.observe(container);
    listenDevicePixelRatioChanges(chart, resize);
    return observer;
  }

  function releaseObserver(chart, type, observer) {
    if (observer) {
      observer.disconnect();
    }

    if (type === 'resize') {
      unlistenDevicePixelRatioChanges(chart);
    }
  }

  function createProxyAndListen(chart, type, listener) {
    var canvas = chart.canvas;
    var proxy = throttled(function (event) {
      if (chart.ctx !== null) {
        listener(fromNativeEvent(event, chart));
      }
    }, chart, function (args) {
      var event = args[0];
      return [event, event.offsetX, event.offsetY];
    });
    addListener(canvas, type, proxy);
    return proxy;
  }

  var DomPlatform = /*#__PURE__*/function (_BasePlatform2) {
    _inherits(DomPlatform, _BasePlatform2);

    var _super11 = _createSuper(DomPlatform);

    function DomPlatform() {
      _classCallCheck(this, DomPlatform);

      return _super11.apply(this, arguments);
    }

    _createClass(DomPlatform, [{
      key: "acquireContext",
      value: function acquireContext(canvas, aspectRatio) {
        var context = canvas && canvas.getContext && canvas.getContext('2d');

        if (context && context.canvas === canvas) {
          initCanvas(canvas, aspectRatio);
          return context;
        }

        return null;
      }
    }, {
      key: "releaseContext",
      value: function releaseContext(context) {
        var canvas = context.canvas;

        if (!canvas[EXPANDO_KEY]) {
          return false;
        }

        var initial = canvas[EXPANDO_KEY].initial;
        ['height', 'width'].forEach(function (prop) {
          var value = initial[prop];

          if (isNullOrUndef(value)) {
            canvas.removeAttribute(prop);
          } else {
            canvas.setAttribute(prop, value);
          }
        });
        var style = initial.style || {};
        Object.keys(style).forEach(function (key) {
          canvas.style[key] = style[key];
        });
        canvas.width = canvas.width;
        delete canvas[EXPANDO_KEY];
        return true;
      }
    }, {
      key: "addEventListener",
      value: function addEventListener(chart, type, listener) {
        this.removeEventListener(chart, type);
        var proxies = chart.$proxies || (chart.$proxies = {});
        var handlers = {
          attach: createAttachObserver,
          detach: createDetachObserver,
          resize: createResizeObserver
        };
        var handler = handlers[type] || createProxyAndListen;
        proxies[type] = handler(chart, type, listener);
      }
    }, {
      key: "removeEventListener",
      value: function removeEventListener(chart, type) {
        var proxies = chart.$proxies || (chart.$proxies = {});
        var proxy = proxies[type];

        if (!proxy) {
          return;
        }

        var handlers = {
          attach: releaseObserver,
          detach: releaseObserver,
          resize: releaseObserver
        };
        var handler = handlers[type] || removeListener;
        handler(chart, type, proxy);
        proxies[type] = undefined;
      }
    }, {
      key: "getDevicePixelRatio",
      value: function getDevicePixelRatio() {
        return window.devicePixelRatio;
      }
    }, {
      key: "getMaximumSize",
      value: function getMaximumSize$1(canvas, width, height, aspectRatio) {
        return getMaximumSize(canvas, width, height, aspectRatio);
      }
    }, {
      key: "isAttached",
      value: function isAttached(canvas) {
        var container = _getParentNode(canvas);

        return !!(container && container.isConnected);
      }
    }]);

    return DomPlatform;
  }(BasePlatform);

  function _detectPlatform(canvas) {
    if (!_isDomSupported() || typeof OffscreenCanvas !== 'undefined' && canvas instanceof OffscreenCanvas) {
      return BasicPlatform;
    }

    return DomPlatform;
  }

  var PluginService = /*#__PURE__*/function () {
    function PluginService() {
      _classCallCheck(this, PluginService);

      this._init = [];
    }

    _createClass(PluginService, [{
      key: "notify",
      value: function notify(chart, hook, args, filter) {
        if (hook === 'beforeInit') {
          this._init = this._createDescriptors(chart, true);

          this._notify(this._init, chart, 'install');
        }

        var descriptors = filter ? this._descriptors(chart).filter(filter) : this._descriptors(chart);

        var result = this._notify(descriptors, chart, hook, args);

        if (hook === 'afterDestroy') {
          this._notify(descriptors, chart, 'stop');

          this._notify(this._init, chart, 'uninstall');
        }

        return result;
      }
    }, {
      key: "_notify",
      value: function _notify(descriptors, chart, hook, args) {
        args = args || {};

        var _iterator11 = _createForOfIteratorHelper(descriptors),
            _step11;

        try {
          for (_iterator11.s(); !(_step11 = _iterator11.n()).done;) {
            var descriptor = _step11.value;
            var plugin = descriptor.plugin;
            var method = plugin[hook];
            var params = [chart, args, descriptor.options];

            if (callback(method, params, plugin) === false && args.cancelable) {
              return false;
            }
          }
        } catch (err) {
          _iterator11.e(err);
        } finally {
          _iterator11.f();
        }

        return true;
      }
    }, {
      key: "invalidate",
      value: function invalidate() {
        if (!isNullOrUndef(this._cache)) {
          this._oldCache = this._cache;
          this._cache = undefined;
        }
      }
    }, {
      key: "_descriptors",
      value: function _descriptors(chart) {
        if (this._cache) {
          return this._cache;
        }

        var descriptors = this._cache = this._createDescriptors(chart);

        this._notifyStateChanges(chart);

        return descriptors;
      }
    }, {
      key: "_createDescriptors",
      value: function _createDescriptors(chart, all) {
        var config = chart && chart.config;
        var options = valueOrDefault(config.options && config.options.plugins, {});
        var plugins = allPlugins(config);
        return options === false && !all ? [] : createDescriptors(chart, plugins, options, all);
      }
    }, {
      key: "_notifyStateChanges",
      value: function _notifyStateChanges(chart) {
        var previousDescriptors = this._oldCache || [];
        var descriptors = this._cache;

        var diff = function diff(a, b) {
          return a.filter(function (x) {
            return !b.some(function (y) {
              return x.plugin.id === y.plugin.id;
            });
          });
        };

        this._notify(diff(previousDescriptors, descriptors), chart, 'stop');

        this._notify(diff(descriptors, previousDescriptors), chart, 'start');
      }
    }]);

    return PluginService;
  }();

  function allPlugins(config) {
    var localIds = {};
    var plugins = [];
    var keys = Object.keys(registry.plugins.items);

    for (var i = 0; i < keys.length; i++) {
      plugins.push(registry.getPlugin(keys[i]));
    }

    var local = config.plugins || [];

    for (var _i = 0; _i < local.length; _i++) {
      var plugin = local[_i];

      if (plugins.indexOf(plugin) === -1) {
        plugins.push(plugin);
        localIds[plugin.id] = true;
      }
    }

    return {
      plugins: plugins,
      localIds: localIds
    };
  }

  function getOpts(options, all) {
    if (!all && options === false) {
      return null;
    }

    if (options === true) {
      return {};
    }

    return options;
  }

  function createDescriptors(chart, _ref2, options, all) {
    var plugins = _ref2.plugins,
        localIds = _ref2.localIds;
    var result = [];
    var context = chart.getContext();

    var _iterator12 = _createForOfIteratorHelper(plugins),
        _step12;

    try {
      for (_iterator12.s(); !(_step12 = _iterator12.n()).done;) {
        var plugin = _step12.value;
        var id = plugin.id;
        var opts = getOpts(options[id], all);

        if (opts === null) {
          continue;
        }

        result.push({
          plugin: plugin,
          options: pluginOpts(chart.config, {
            plugin: plugin,
            local: localIds[id]
          }, opts, context)
        });
      }
    } catch (err) {
      _iterator12.e(err);
    } finally {
      _iterator12.f();
    }

    return result;
  }

  function pluginOpts(config, _ref3, opts, context) {
    var plugin = _ref3.plugin,
        local = _ref3.local;
    var keys = config.pluginScopeKeys(plugin);
    var scopes = config.getOptionScopes(opts, keys);

    if (local && plugin.defaults) {
      scopes.push(plugin.defaults);
    }

    return config.createResolver(scopes, context, [''], {
      scriptable: false,
      indexable: false,
      allKeys: true
    });
  }

  function getIndexAxis(type, options) {
    var datasetDefaults = defaults.datasets[type] || {};
    var datasetOptions = (options.datasets || {})[type] || {};
    return datasetOptions.indexAxis || options.indexAxis || datasetDefaults.indexAxis || 'x';
  }

  function getAxisFromDefaultScaleID(id, indexAxis) {
    var axis = id;

    if (id === '_index_') {
      axis = indexAxis;
    } else if (id === '_value_') {
      axis = indexAxis === 'x' ? 'y' : 'x';
    }

    return axis;
  }

  function getDefaultScaleIDFromAxis(axis, indexAxis) {
    return axis === indexAxis ? '_index_' : '_value_';
  }

  function axisFromPosition(position) {
    if (position === 'top' || position === 'bottom') {
      return 'x';
    }

    if (position === 'left' || position === 'right') {
      return 'y';
    }
  }

  function determineAxis(id, scaleOptions) {
    if (id === 'x' || id === 'y') {
      return id;
    }

    return scaleOptions.axis || axisFromPosition(scaleOptions.position) || id.charAt(0).toLowerCase();
  }

  function mergeScaleConfig(config, options) {
    var chartDefaults = overrides[config.type] || {
      scales: {}
    };
    var configScales = options.scales || {};
    var chartIndexAxis = getIndexAxis(config.type, options);
    var firstIDs = Object.create(null);
    var scales = Object.create(null);
    Object.keys(configScales).forEach(function (id) {
      var scaleConf = configScales[id];

      if (!isObject(scaleConf)) {
        return console.error("Invalid scale configuration for scale: ".concat(id));
      }

      if (scaleConf._proxy) {
        return console.warn("Ignoring resolver passed as options for scale: ".concat(id));
      }

      var axis = determineAxis(id, scaleConf);
      var defaultId = getDefaultScaleIDFromAxis(axis, chartIndexAxis);
      var defaultScaleOptions = chartDefaults.scales || {};
      firstIDs[axis] = firstIDs[axis] || id;
      scales[id] = mergeIf(Object.create(null), [{
        axis: axis
      }, scaleConf, defaultScaleOptions[axis], defaultScaleOptions[defaultId]]);
    });
    config.data.datasets.forEach(function (dataset) {
      var type = dataset.type || config.type;
      var indexAxis = dataset.indexAxis || getIndexAxis(type, options);
      var datasetDefaults = overrides[type] || {};
      var defaultScaleOptions = datasetDefaults.scales || {};
      Object.keys(defaultScaleOptions).forEach(function (defaultID) {
        var axis = getAxisFromDefaultScaleID(defaultID, indexAxis);
        var id = dataset[axis + 'AxisID'] || firstIDs[axis] || axis;
        scales[id] = scales[id] || Object.create(null);
        mergeIf(scales[id], [{
          axis: axis
        }, configScales[id], defaultScaleOptions[defaultID]]);
      });
    });
    Object.keys(scales).forEach(function (key) {
      var scale = scales[key];
      mergeIf(scale, [defaults.scales[scale.type], defaults.scale]);
    });
    return scales;
  }

  function initOptions(config) {
    var options = config.options || (config.options = {});
    options.plugins = valueOrDefault(options.plugins, {});
    options.scales = mergeScaleConfig(config, options);
  }

  function initData(data) {
    data = data || {};
    data.datasets = data.datasets || [];
    data.labels = data.labels || [];
    return data;
  }

  function initConfig(config) {
    config = config || {};
    config.data = initData(config.data);
    initOptions(config);
    return config;
  }

  var keyCache = new Map();
  var keysCached = new Set();

  function cachedKeys(cacheKey, generate) {
    var keys = keyCache.get(cacheKey);

    if (!keys) {
      keys = generate();
      keyCache.set(cacheKey, keys);
      keysCached.add(keys);
    }

    return keys;
  }

  var addIfFound = function addIfFound(set, obj, key) {
    var opts = resolveObjectKey(obj, key);

    if (opts !== undefined) {
      set.add(opts);
    }
  };

  var Config = /*#__PURE__*/function () {
    function Config(config) {
      _classCallCheck(this, Config);

      this._config = initConfig(config);
      this._scopeCache = new Map();
      this._resolverCache = new Map();
    }

    _createClass(Config, [{
      key: "platform",
      get: function get() {
        return this._config.platform;
      }
    }, {
      key: "type",
      get: function get() {
        return this._config.type;
      },
      set: function set(type) {
        this._config.type = type;
      }
    }, {
      key: "data",
      get: function get() {
        return this._config.data;
      },
      set: function set(data) {
        this._config.data = initData(data);
      }
    }, {
      key: "options",
      get: function get() {
        return this._config.options;
      },
      set: function set(options) {
        this._config.options = options;
      }
    }, {
      key: "plugins",
      get: function get() {
        return this._config.plugins;
      }
    }, {
      key: "update",
      value: function update() {
        var config = this._config;
        this.clearCache();
        initOptions(config);
      }
    }, {
      key: "clearCache",
      value: function clearCache() {
        this._scopeCache.clear();

        this._resolverCache.clear();
      }
    }, {
      key: "datasetScopeKeys",
      value: function datasetScopeKeys(datasetType) {
        return cachedKeys(datasetType, function () {
          return [["datasets.".concat(datasetType), '']];
        });
      }
    }, {
      key: "datasetAnimationScopeKeys",
      value: function datasetAnimationScopeKeys(datasetType, transition) {
        return cachedKeys("".concat(datasetType, ".transition.").concat(transition), function () {
          return [["datasets.".concat(datasetType, ".transitions.").concat(transition), "transitions.".concat(transition)], ["datasets.".concat(datasetType), '']];
        });
      }
    }, {
      key: "datasetElementScopeKeys",
      value: function datasetElementScopeKeys(datasetType, elementType) {
        return cachedKeys("".concat(datasetType, "-").concat(elementType), function () {
          return [["datasets.".concat(datasetType, ".elements.").concat(elementType), "datasets.".concat(datasetType), "elements.".concat(elementType), '']];
        });
      }
    }, {
      key: "pluginScopeKeys",
      value: function pluginScopeKeys(plugin) {
        var id = plugin.id;
        var type = this.type;
        return cachedKeys("".concat(type, "-plugin-").concat(id), function () {
          return [["plugins.".concat(id)].concat(_toConsumableArray(plugin.additionalOptionScopes || []))];
        });
      }
    }, {
      key: "_cachedScopes",
      value: function _cachedScopes(mainScope, resetCache) {
        var _scopeCache = this._scopeCache;

        var cache = _scopeCache.get(mainScope);

        if (!cache || resetCache) {
          cache = new Map();

          _scopeCache.set(mainScope, cache);
        }

        return cache;
      }
    }, {
      key: "getOptionScopes",
      value: function getOptionScopes(mainScope, keyLists, resetCache) {
        var options = this.options,
            type = this.type;

        var cache = this._cachedScopes(mainScope, resetCache);

        var cached = cache.get(keyLists);

        if (cached) {
          return cached;
        }

        var scopes = new Set();
        keyLists.forEach(function (keys) {
          if (mainScope) {
            scopes.add(mainScope);
            keys.forEach(function (key) {
              return addIfFound(scopes, mainScope, key);
            });
          }

          keys.forEach(function (key) {
            return addIfFound(scopes, options, key);
          });
          keys.forEach(function (key) {
            return addIfFound(scopes, overrides[type] || {}, key);
          });
          keys.forEach(function (key) {
            return addIfFound(scopes, defaults, key);
          });
          keys.forEach(function (key) {
            return addIfFound(scopes, descriptors, key);
          });
        });
        var array = Array.from(scopes);

        if (array.length === 0) {
          array.push(Object.create(null));
        }

        if (keysCached.has(keyLists)) {
          cache.set(keyLists, array);
        }

        return array;
      }
    }, {
      key: "chartOptionScopes",
      value: function chartOptionScopes() {
        var options = this.options,
            type = this.type;
        return [options, overrides[type] || {}, defaults.datasets[type] || {}, {
          type: type
        }, defaults, descriptors];
      }
    }, {
      key: "resolveNamedOptions",
      value: function resolveNamedOptions(scopes, names, context) {
        var prefixes = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : [''];
        var result = {
          $shared: true
        };

        var _getResolver = getResolver(this._resolverCache, scopes, prefixes),
            resolver = _getResolver.resolver,
            subPrefixes = _getResolver.subPrefixes;

        var options = resolver;

        if (needContext(resolver, names)) {
          result.$shared = false;
          context = isFunction(context) ? context() : context;
          var subResolver = this.createResolver(scopes, context, subPrefixes);
          options = _attachContext(resolver, context, subResolver);
        }

        var _iterator13 = _createForOfIteratorHelper(names),
            _step13;

        try {
          for (_iterator13.s(); !(_step13 = _iterator13.n()).done;) {
            var prop = _step13.value;
            result[prop] = options[prop];
          }
        } catch (err) {
          _iterator13.e(err);
        } finally {
          _iterator13.f();
        }

        return result;
      }
    }, {
      key: "createResolver",
      value: function createResolver(scopes, context) {
        var prefixes = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : [''];
        var descriptorDefaults = arguments.length > 3 ? arguments[3] : undefined;

        var _getResolver2 = getResolver(this._resolverCache, scopes, prefixes),
            resolver = _getResolver2.resolver;

        return isObject(context) ? _attachContext(resolver, context, undefined, descriptorDefaults) : resolver;
      }
    }]);

    return Config;
  }();

  function getResolver(resolverCache, scopes, prefixes) {
    var cache = resolverCache.get(scopes);

    if (!cache) {
      cache = new Map();
      resolverCache.set(scopes, cache);
    }

    var cacheKey = prefixes.join();
    var cached = cache.get(cacheKey);

    if (!cached) {
      var resolver = _createResolver(scopes, prefixes);

      cached = {
        resolver: resolver,
        subPrefixes: prefixes.filter(function (p) {
          return !p.toLowerCase().includes('hover');
        })
      };
      cache.set(cacheKey, cached);
    }

    return cached;
  }

  var hasFunction = function hasFunction(value) {
    return isObject(value) && Object.getOwnPropertyNames(value).reduce(function (acc, key) {
      return acc || isFunction(value[key]);
    }, false);
  };

  function needContext(proxy, names) {
    var _descriptors2 = _descriptors(proxy),
        isScriptable = _descriptors2.isScriptable,
        isIndexable = _descriptors2.isIndexable;

    var _iterator14 = _createForOfIteratorHelper(names),
        _step14;

    try {
      for (_iterator14.s(); !(_step14 = _iterator14.n()).done;) {
        var prop = _step14.value;
        var scriptable = isScriptable(prop);
        var indexable = isIndexable(prop);
        var value = (indexable || scriptable) && proxy[prop];

        if (scriptable && (isFunction(value) || hasFunction(value)) || indexable && isArray(value)) {
          return true;
        }
      }
    } catch (err) {
      _iterator14.e(err);
    } finally {
      _iterator14.f();
    }

    return false;
  }

  var version = "3.9.0";
  var KNOWN_POSITIONS = ['top', 'bottom', 'left', 'right', 'chartArea'];

  function positionIsHorizontal(position, axis) {
    return position === 'top' || position === 'bottom' || KNOWN_POSITIONS.indexOf(position) === -1 && axis === 'x';
  }

  function compare2Level(l1, l2) {
    return function (a, b) {
      return a[l1] === b[l1] ? a[l2] - b[l2] : a[l1] - b[l1];
    };
  }

  function onAnimationsComplete(context) {
    var chart = context.chart;
    var animationOptions = chart.options.animation;
    chart.notifyPlugins('afterRender');
    callback(animationOptions && animationOptions.onComplete, [context], chart);
  }

  function onAnimationProgress(context) {
    var chart = context.chart;
    var animationOptions = chart.options.animation;
    callback(animationOptions && animationOptions.onProgress, [context], chart);
  }

  function getCanvas(item) {
    if (_isDomSupported() && typeof item === 'string') {
      item = document.getElementById(item);
    } else if (item && item.length) {
      item = item[0];
    }

    if (item && item.canvas) {
      item = item.canvas;
    }

    return item;
  }

  var instances = {};

  var getChart = function getChart(key) {
    var canvas = getCanvas(key);
    return Object.values(instances).filter(function (c) {
      return c.canvas === canvas;
    }).pop();
  };

  function moveNumericKeys(obj, start, move) {
    var keys = Object.keys(obj);

    for (var _i2 = 0, _keys = keys; _i2 < _keys.length; _i2++) {
      var key = _keys[_i2];
      var intKey = +key;

      if (intKey >= start) {
        var value = obj[key];
        delete obj[key];

        if (move > 0 || intKey > start) {
          obj[intKey + move] = value;
        }
      }
    }
  }

  function determineLastEvent(e, lastEvent, inChartArea, isClick) {
    if (!inChartArea || e.type === 'mouseout') {
      return null;
    }

    if (isClick) {
      return lastEvent;
    }

    return e;
  }

  var Chart = /*#__PURE__*/function () {
    function Chart(item, userConfig) {
      var _this12 = this;

      _classCallCheck(this, Chart);

      var config = this.config = new Config(userConfig);
      var initialCanvas = getCanvas(item);
      var existingChart = getChart(initialCanvas);

      if (existingChart) {
        throw new Error('Canvas is already in use. Chart with ID \'' + existingChart.id + '\'' + ' must be destroyed before the canvas with ID \'' + existingChart.canvas.id + '\' can be reused.');
      }

      var options = config.createResolver(config.chartOptionScopes(), this.getContext());
      this.platform = new (config.platform || _detectPlatform(initialCanvas))();
      this.platform.updateConfig(config);
      var context = this.platform.acquireContext(initialCanvas, options.aspectRatio);
      var canvas = context && context.canvas;
      var height = canvas && canvas.height;
      var width = canvas && canvas.width;
      this.id = uid();
      this.ctx = context;
      this.canvas = canvas;
      this.width = width;
      this.height = height;
      this._options = options;
      this._aspectRatio = this.aspectRatio;
      this._layers = [];
      this._metasets = [];
      this._stacks = undefined;
      this.boxes = [];
      this.currentDevicePixelRatio = undefined;
      this.chartArea = undefined;
      this._active = [];
      this._lastEvent = undefined;
      this._listeners = {};
      this._responsiveListeners = undefined;
      this._sortedMetasets = [];
      this.scales = {};
      this._plugins = new PluginService();
      this.$proxies = {};
      this._hiddenIndices = {};
      this.attached = false;
      this._animationsDisabled = undefined;
      this.$context = undefined;
      this._doResize = debounce(function (mode) {
        return _this12.update(mode);
      }, options.resizeDelay || 0);
      this._dataChanges = [];
      instances[this.id] = this;

      if (!context || !canvas) {
        console.error("Failed to create chart: can't acquire context from the given item");
        return;
      }

      animator.listen(this, 'complete', onAnimationsComplete);
      animator.listen(this, 'progress', onAnimationProgress);

      this._initialize();

      if (this.attached) {
        this.update();
      }
    }

    _createClass(Chart, [{
      key: "aspectRatio",
      get: function get() {
        var _this$options11 = this.options,
            aspectRatio = _this$options11.aspectRatio,
            maintainAspectRatio = _this$options11.maintainAspectRatio,
            width = this.width,
            height = this.height,
            _aspectRatio = this._aspectRatio;

        if (!isNullOrUndef(aspectRatio)) {
          return aspectRatio;
        }

        if (maintainAspectRatio && _aspectRatio) {
          return _aspectRatio;
        }

        return height ? width / height : null;
      }
    }, {
      key: "data",
      get: function get() {
        return this.config.data;
      },
      set: function set(data) {
        this.config.data = data;
      }
    }, {
      key: "options",
      get: function get() {
        return this._options;
      },
      set: function set(options) {
        this.config.options = options;
      }
    }, {
      key: "_initialize",
      value: function _initialize() {
        this.notifyPlugins('beforeInit');

        if (this.options.responsive) {
          this.resize();
        } else {
          retinaScale(this, this.options.devicePixelRatio);
        }

        this.bindEvents();
        this.notifyPlugins('afterInit');
        return this;
      }
    }, {
      key: "clear",
      value: function clear() {
        clearCanvas(this.canvas, this.ctx);
        return this;
      }
    }, {
      key: "stop",
      value: function stop() {
        animator.stop(this);
        return this;
      }
    }, {
      key: "resize",
      value: function resize(width, height) {
        if (!animator.running(this)) {
          this._resize(width, height);
        } else {
          this._resizeBeforeDraw = {
            width: width,
            height: height
          };
        }
      }
    }, {
      key: "_resize",
      value: function _resize(width, height) {
        var options = this.options;
        var canvas = this.canvas;
        var aspectRatio = options.maintainAspectRatio && this.aspectRatio;
        var newSize = this.platform.getMaximumSize(canvas, width, height, aspectRatio);
        var newRatio = options.devicePixelRatio || this.platform.getDevicePixelRatio();
        var mode = this.width ? 'resize' : 'attach';
        this.width = newSize.width;
        this.height = newSize.height;
        this._aspectRatio = this.aspectRatio;

        if (!retinaScale(this, newRatio, true)) {
          return;
        }

        this.notifyPlugins('resize', {
          size: newSize
        });
        callback(options.onResize, [this, newSize], this);

        if (this.attached) {
          if (this._doResize(mode)) {
            this.render();
          }
        }
      }
    }, {
      key: "ensureScalesHaveIDs",
      value: function ensureScalesHaveIDs() {
        var options = this.options;
        var scalesOptions = options.scales || {};
        each(scalesOptions, function (axisOptions, axisID) {
          axisOptions.id = axisID;
        });
      }
    }, {
      key: "buildOrUpdateScales",
      value: function buildOrUpdateScales() {
        var _this13 = this;

        var options = this.options;
        var scaleOpts = options.scales;
        var scales = this.scales;
        var updated = Object.keys(scales).reduce(function (obj, id) {
          obj[id] = false;
          return obj;
        }, {});
        var items = [];

        if (scaleOpts) {
          items = items.concat(Object.keys(scaleOpts).map(function (id) {
            var scaleOptions = scaleOpts[id];
            var axis = determineAxis(id, scaleOptions);
            var isRadial = axis === 'r';
            var isHorizontal = axis === 'x';
            return {
              options: scaleOptions,
              dposition: isRadial ? 'chartArea' : isHorizontal ? 'bottom' : 'left',
              dtype: isRadial ? 'radialLinear' : isHorizontal ? 'category' : 'linear'
            };
          }));
        }

        each(items, function (item) {
          var scaleOptions = item.options;
          var id = scaleOptions.id;
          var axis = determineAxis(id, scaleOptions);
          var scaleType = valueOrDefault(scaleOptions.type, item.dtype);

          if (scaleOptions.position === undefined || positionIsHorizontal(scaleOptions.position, axis) !== positionIsHorizontal(item.dposition)) {
            scaleOptions.position = item.dposition;
          }

          updated[id] = true;
          var scale = null;

          if (id in scales && scales[id].type === scaleType) {
            scale = scales[id];
          } else {
            var scaleClass = registry.getScale(scaleType);
            scale = new scaleClass({
              id: id,
              type: scaleType,
              ctx: _this13.ctx,
              chart: _this13
            });
            scales[scale.id] = scale;
          }

          scale.init(scaleOptions, options);
        });
        each(updated, function (hasUpdated, id) {
          if (!hasUpdated) {
            delete scales[id];
          }
        });
        each(scales, function (scale) {
          layouts.configure(_this13, scale, scale.options);
          layouts.addBox(_this13, scale);
        });
      }
    }, {
      key: "_updateMetasets",
      value: function _updateMetasets() {
        var metasets = this._metasets;
        var numData = this.data.datasets.length;
        var numMeta = metasets.length;
        metasets.sort(function (a, b) {
          return a.index - b.index;
        });

        if (numMeta > numData) {
          for (var i = numData; i < numMeta; ++i) {
            this._destroyDatasetMeta(i);
          }

          metasets.splice(numData, numMeta - numData);
        }

        this._sortedMetasets = metasets.slice(0).sort(compare2Level('order', 'index'));
      }
    }, {
      key: "_removeUnreferencedMetasets",
      value: function _removeUnreferencedMetasets() {
        var _this14 = this;

        var metasets = this._metasets,
            datasets = this.data.datasets;

        if (metasets.length > datasets.length) {
          delete this._stacks;
        }

        metasets.forEach(function (meta, index) {
          if (datasets.filter(function (x) {
            return x === meta._dataset;
          }).length === 0) {
            _this14._destroyDatasetMeta(index);
          }
        });
      }
    }, {
      key: "buildOrUpdateControllers",
      value: function buildOrUpdateControllers() {
        var newControllers = [];
        var datasets = this.data.datasets;
        var i, ilen;

        this._removeUnreferencedMetasets();

        for (i = 0, ilen = datasets.length; i < ilen; i++) {
          var dataset = datasets[i];
          var meta = this.getDatasetMeta(i);
          var type = dataset.type || this.config.type;

          if (meta.type && meta.type !== type) {
            this._destroyDatasetMeta(i);

            meta = this.getDatasetMeta(i);
          }

          meta.type = type;
          meta.indexAxis = dataset.indexAxis || getIndexAxis(type, this.options);
          meta.order = dataset.order || 0;
          meta.index = i;
          meta.label = '' + dataset.label;
          meta.visible = this.isDatasetVisible(i);

          if (meta.controller) {
            meta.controller.updateIndex(i);
            meta.controller.linkScales();
          } else {
            var ControllerClass = registry.getController(type);
            var _defaults$datasets$ty = defaults.datasets[type],
                datasetElementType = _defaults$datasets$ty.datasetElementType,
                dataElementType = _defaults$datasets$ty.dataElementType;
            Object.assign(ControllerClass.prototype, {
              dataElementType: registry.getElement(dataElementType),
              datasetElementType: datasetElementType && registry.getElement(datasetElementType)
            });
            meta.controller = new ControllerClass(this, i);
            newControllers.push(meta.controller);
          }
        }

        this._updateMetasets();

        return newControllers;
      }
    }, {
      key: "_resetElements",
      value: function _resetElements() {
        var _this15 = this;

        each(this.data.datasets, function (dataset, datasetIndex) {
          _this15.getDatasetMeta(datasetIndex).controller.reset();
        }, this);
      }
    }, {
      key: "reset",
      value: function reset() {
        this._resetElements();

        this.notifyPlugins('reset');
      }
    }, {
      key: "update",
      value: function update(mode) {
        var config = this.config;
        config.update();
        var options = this._options = config.createResolver(config.chartOptionScopes(), this.getContext());
        var animsDisabled = this._animationsDisabled = !options.animation;

        this._updateScales();

        this._checkEventBindings();

        this._updateHiddenIndices();

        this._plugins.invalidate();

        if (this.notifyPlugins('beforeUpdate', {
          mode: mode,
          cancelable: true
        }) === false) {
          return;
        }

        var newControllers = this.buildOrUpdateControllers();
        this.notifyPlugins('beforeElementsUpdate');
        var minPadding = 0;

        for (var i = 0, ilen = this.data.datasets.length; i < ilen; i++) {
          var _this$getDatasetMeta = this.getDatasetMeta(i),
              controller = _this$getDatasetMeta.controller;

          var reset = !animsDisabled && newControllers.indexOf(controller) === -1;
          controller.buildOrUpdateElements(reset);
          minPadding = Math.max(+controller.getMaxOverflow(), minPadding);
        }

        minPadding = this._minPadding = options.layout.autoPadding ? minPadding : 0;

        this._updateLayout(minPadding);

        if (!animsDisabled) {
          each(newControllers, function (controller) {
            controller.reset();
          });
        }

        this._updateDatasets(mode);

        this.notifyPlugins('afterUpdate', {
          mode: mode
        });

        this._layers.sort(compare2Level('z', '_idx'));

        var _active = this._active,
            _lastEvent = this._lastEvent;

        if (_lastEvent) {
          this._eventHandler(_lastEvent, true);
        } else if (_active.length) {
          this._updateHoverStyles(_active, _active, true);
        }

        this.render();
      }
    }, {
      key: "_updateScales",
      value: function _updateScales() {
        var _this16 = this;

        each(this.scales, function (scale) {
          layouts.removeBox(_this16, scale);
        });
        this.ensureScalesHaveIDs();
        this.buildOrUpdateScales();
      }
    }, {
      key: "_checkEventBindings",
      value: function _checkEventBindings() {
        var options = this.options;
        var existingEvents = new Set(Object.keys(this._listeners));
        var newEvents = new Set(options.events);

        if (!setsEqual(existingEvents, newEvents) || !!this._responsiveListeners !== options.responsive) {
          this.unbindEvents();
          this.bindEvents();
        }
      }
    }, {
      key: "_updateHiddenIndices",
      value: function _updateHiddenIndices() {
        var _hiddenIndices = this._hiddenIndices;
        var changes = this._getUniformDataChanges() || [];

        var _iterator15 = _createForOfIteratorHelper(changes),
            _step15;

        try {
          for (_iterator15.s(); !(_step15 = _iterator15.n()).done;) {
            var _step15$value = _step15.value,
                method = _step15$value.method,
                start = _step15$value.start,
                count = _step15$value.count;
            var move = method === '_removeElements' ? -count : count;
            moveNumericKeys(_hiddenIndices, start, move);
          }
        } catch (err) {
          _iterator15.e(err);
        } finally {
          _iterator15.f();
        }
      }
    }, {
      key: "_getUniformDataChanges",
      value: function _getUniformDataChanges() {
        var _dataChanges = this._dataChanges;

        if (!_dataChanges || !_dataChanges.length) {
          return;
        }

        this._dataChanges = [];
        var datasetCount = this.data.datasets.length;

        var makeSet = function makeSet(idx) {
          return new Set(_dataChanges.filter(function (c) {
            return c[0] === idx;
          }).map(function (c, i) {
            return i + ',' + c.splice(1).join(',');
          }));
        };

        var changeSet = makeSet(0);

        for (var i = 1; i < datasetCount; i++) {
          if (!setsEqual(changeSet, makeSet(i))) {
            return;
          }
        }

        return Array.from(changeSet).map(function (c) {
          return c.split(',');
        }).map(function (a) {
          return {
            method: a[1],
            start: +a[2],
            count: +a[3]
          };
        });
      }
    }, {
      key: "_updateLayout",
      value: function _updateLayout(minPadding) {
        var _this17 = this;

        if (this.notifyPlugins('beforeLayout', {
          cancelable: true
        }) === false) {
          return;
        }

        layouts.update(this, this.width, this.height, minPadding);
        var area = this.chartArea;
        var noArea = area.width <= 0 || area.height <= 0;
        this._layers = [];
        each(this.boxes, function (box) {
          var _this17$_layers;

          if (noArea && box.position === 'chartArea') {
            return;
          }

          if (box.configure) {
            box.configure();
          }

          (_this17$_layers = _this17._layers).push.apply(_this17$_layers, _toConsumableArray(box._layers()));
        }, this);

        this._layers.forEach(function (item, index) {
          item._idx = index;
        });

        this.notifyPlugins('afterLayout');
      }
    }, {
      key: "_updateDatasets",
      value: function _updateDatasets(mode) {
        if (this.notifyPlugins('beforeDatasetsUpdate', {
          mode: mode,
          cancelable: true
        }) === false) {
          return;
        }

        for (var i = 0, ilen = this.data.datasets.length; i < ilen; ++i) {
          this.getDatasetMeta(i).controller.configure();
        }

        for (var _i3 = 0, _ilen = this.data.datasets.length; _i3 < _ilen; ++_i3) {
          this._updateDataset(_i3, isFunction(mode) ? mode({
            datasetIndex: _i3
          }) : mode);
        }

        this.notifyPlugins('afterDatasetsUpdate', {
          mode: mode
        });
      }
    }, {
      key: "_updateDataset",
      value: function _updateDataset(index, mode) {
        var meta = this.getDatasetMeta(index);
        var args = {
          meta: meta,
          index: index,
          mode: mode,
          cancelable: true
        };

        if (this.notifyPlugins('beforeDatasetUpdate', args) === false) {
          return;
        }

        meta.controller._update(mode);

        args.cancelable = false;
        this.notifyPlugins('afterDatasetUpdate', args);
      }
    }, {
      key: "render",
      value: function render() {
        if (this.notifyPlugins('beforeRender', {
          cancelable: true
        }) === false) {
          return;
        }

        if (animator.has(this)) {
          if (this.attached && !animator.running(this)) {
            animator.start(this);
          }
        } else {
          this.draw();
          onAnimationsComplete({
            chart: this
          });
        }
      }
    }, {
      key: "draw",
      value: function draw() {
        var i;

        if (this._resizeBeforeDraw) {
          var _this$_resizeBeforeDr = this._resizeBeforeDraw,
              width = _this$_resizeBeforeDr.width,
              height = _this$_resizeBeforeDr.height;

          this._resize(width, height);

          this._resizeBeforeDraw = null;
        }

        this.clear();

        if (this.width <= 0 || this.height <= 0) {
          return;
        }

        if (this.notifyPlugins('beforeDraw', {
          cancelable: true
        }) === false) {
          return;
        }

        var layers = this._layers;

        for (i = 0; i < layers.length && layers[i].z <= 0; ++i) {
          layers[i].draw(this.chartArea);
        }

        this._drawDatasets();

        for (; i < layers.length; ++i) {
          layers[i].draw(this.chartArea);
        }

        this.notifyPlugins('afterDraw');
      }
    }, {
      key: "_getSortedDatasetMetas",
      value: function _getSortedDatasetMetas(filterVisible) {
        var metasets = this._sortedMetasets;
        var result = [];
        var i, ilen;

        for (i = 0, ilen = metasets.length; i < ilen; ++i) {
          var meta = metasets[i];

          if (!filterVisible || meta.visible) {
            result.push(meta);
          }
        }

        return result;
      }
    }, {
      key: "getSortedVisibleDatasetMetas",
      value: function getSortedVisibleDatasetMetas() {
        return this._getSortedDatasetMetas(true);
      }
    }, {
      key: "_drawDatasets",
      value: function _drawDatasets() {
        if (this.notifyPlugins('beforeDatasetsDraw', {
          cancelable: true
        }) === false) {
          return;
        }

        var metasets = this.getSortedVisibleDatasetMetas();

        for (var i = metasets.length - 1; i >= 0; --i) {
          this._drawDataset(metasets[i]);
        }

        this.notifyPlugins('afterDatasetsDraw');
      }
    }, {
      key: "_drawDataset",
      value: function _drawDataset(meta) {
        var ctx = this.ctx;
        var clip = meta._clip;
        var useClip = !clip.disabled;
        var area = this.chartArea;
        var args = {
          meta: meta,
          index: meta.index,
          cancelable: true
        };

        if (this.notifyPlugins('beforeDatasetDraw', args) === false) {
          return;
        }

        if (useClip) {
          clipArea(ctx, {
            left: clip.left === false ? 0 : area.left - clip.left,
            right: clip.right === false ? this.width : area.right + clip.right,
            top: clip.top === false ? 0 : area.top - clip.top,
            bottom: clip.bottom === false ? this.height : area.bottom + clip.bottom
          });
        }

        meta.controller.draw();

        if (useClip) {
          unclipArea(ctx);
        }

        args.cancelable = false;
        this.notifyPlugins('afterDatasetDraw', args);
      }
    }, {
      key: "isPointInArea",
      value: function isPointInArea(point) {
        return _isPointInArea(point, this.chartArea, this._minPadding);
      }
    }, {
      key: "getElementsAtEventForMode",
      value: function getElementsAtEventForMode(e, mode, options, useFinalPosition) {
        var method = Interaction.modes[mode];

        if (typeof method === 'function') {
          return method(this, e, options, useFinalPosition);
        }

        return [];
      }
    }, {
      key: "getDatasetMeta",
      value: function getDatasetMeta(datasetIndex) {
        var dataset = this.data.datasets[datasetIndex];
        var metasets = this._metasets;
        var meta = metasets.filter(function (x) {
          return x && x._dataset === dataset;
        }).pop();

        if (!meta) {
          meta = {
            type: null,
            data: [],
            dataset: null,
            controller: null,
            hidden: null,
            xAxisID: null,
            yAxisID: null,
            order: dataset && dataset.order || 0,
            index: datasetIndex,
            _dataset: dataset,
            _parsed: [],
            _sorted: false
          };
          metasets.push(meta);
        }

        return meta;
      }
    }, {
      key: "getContext",
      value: function getContext() {
        return this.$context || (this.$context = createContext(null, {
          chart: this,
          type: 'chart'
        }));
      }
    }, {
      key: "getVisibleDatasetCount",
      value: function getVisibleDatasetCount() {
        return this.getSortedVisibleDatasetMetas().length;
      }
    }, {
      key: "isDatasetVisible",
      value: function isDatasetVisible(datasetIndex) {
        var dataset = this.data.datasets[datasetIndex];

        if (!dataset) {
          return false;
        }

        var meta = this.getDatasetMeta(datasetIndex);
        return typeof meta.hidden === 'boolean' ? !meta.hidden : !dataset.hidden;
      }
    }, {
      key: "setDatasetVisibility",
      value: function setDatasetVisibility(datasetIndex, visible) {
        var meta = this.getDatasetMeta(datasetIndex);
        meta.hidden = !visible;
      }
    }, {
      key: "toggleDataVisibility",
      value: function toggleDataVisibility(index) {
        this._hiddenIndices[index] = !this._hiddenIndices[index];
      }
    }, {
      key: "getDataVisibility",
      value: function getDataVisibility(index) {
        return !this._hiddenIndices[index];
      }
    }, {
      key: "_updateVisibility",
      value: function _updateVisibility(datasetIndex, dataIndex, visible) {
        var mode = visible ? 'show' : 'hide';
        var meta = this.getDatasetMeta(datasetIndex);

        var anims = meta.controller._resolveAnimations(undefined, mode);

        if (defined(dataIndex)) {
          meta.data[dataIndex].hidden = !visible;
          this.update();
        } else {
          this.setDatasetVisibility(datasetIndex, visible);
          anims.update(meta, {
            visible: visible
          });
          this.update(function (ctx) {
            return ctx.datasetIndex === datasetIndex ? mode : undefined;
          });
        }
      }
    }, {
      key: "hide",
      value: function hide(datasetIndex, dataIndex) {
        this._updateVisibility(datasetIndex, dataIndex, false);
      }
    }, {
      key: "show",
      value: function show(datasetIndex, dataIndex) {
        this._updateVisibility(datasetIndex, dataIndex, true);
      }
    }, {
      key: "_destroyDatasetMeta",
      value: function _destroyDatasetMeta(datasetIndex) {
        var meta = this._metasets[datasetIndex];

        if (meta && meta.controller) {
          meta.controller._destroy();
        }

        delete this._metasets[datasetIndex];
      }
    }, {
      key: "_stop",
      value: function _stop() {
        var i, ilen;
        this.stop();
        animator.remove(this);

        for (i = 0, ilen = this.data.datasets.length; i < ilen; ++i) {
          this._destroyDatasetMeta(i);
        }
      }
    }, {
      key: "destroy",
      value: function destroy() {
        this.notifyPlugins('beforeDestroy');
        var canvas = this.canvas,
            ctx = this.ctx;

        this._stop();

        this.config.clearCache();

        if (canvas) {
          this.unbindEvents();
          clearCanvas(canvas, ctx);
          this.platform.releaseContext(ctx);
          this.canvas = null;
          this.ctx = null;
        }

        this.notifyPlugins('destroy');
        delete instances[this.id];
        this.notifyPlugins('afterDestroy');
      }
    }, {
      key: "toBase64Image",
      value: function toBase64Image() {
        var _this$canvas;

        return (_this$canvas = this.canvas).toDataURL.apply(_this$canvas, arguments);
      }
    }, {
      key: "bindEvents",
      value: function bindEvents() {
        this.bindUserEvents();

        if (this.options.responsive) {
          this.bindResponsiveEvents();
        } else {
          this.attached = true;
        }
      }
    }, {
      key: "bindUserEvents",
      value: function bindUserEvents() {
        var _this18 = this;

        var listeners = this._listeners;
        var platform = this.platform;

        var _add = function _add(type, listener) {
          platform.addEventListener(_this18, type, listener);
          listeners[type] = listener;
        };

        var listener = function listener(e, x, y) {
          e.offsetX = x;
          e.offsetY = y;

          _this18._eventHandler(e);
        };

        each(this.options.events, function (type) {
          return _add(type, listener);
        });
      }
    }, {
      key: "bindResponsiveEvents",
      value: function bindResponsiveEvents() {
        var _this19 = this;

        if (!this._responsiveListeners) {
          this._responsiveListeners = {};
        }

        var listeners = this._responsiveListeners;
        var platform = this.platform;

        var _add = function _add(type, listener) {
          platform.addEventListener(_this19, type, listener);
          listeners[type] = listener;
        };

        var _remove = function _remove(type, listener) {
          if (listeners[type]) {
            platform.removeEventListener(_this19, type, listener);
            delete listeners[type];
          }
        };

        var listener = function listener(width, height) {
          if (_this19.canvas) {
            _this19.resize(width, height);
          }
        };

        var detached;

        var attached = function attached() {
          _remove('attach', attached);

          _this19.attached = true;

          _this19.resize();

          _add('resize', listener);

          _add('detach', detached);
        };

        detached = function detached() {
          _this19.attached = false;

          _remove('resize', listener);

          _this19._stop();

          _this19._resize(0, 0);

          _add('attach', attached);
        };

        if (platform.isAttached(this.canvas)) {
          attached();
        } else {
          detached();
        }
      }
    }, {
      key: "unbindEvents",
      value: function unbindEvents() {
        var _this20 = this;

        each(this._listeners, function (listener, type) {
          _this20.platform.removeEventListener(_this20, type, listener);
        });
        this._listeners = {};
        each(this._responsiveListeners, function (listener, type) {
          _this20.platform.removeEventListener(_this20, type, listener);
        });
        this._responsiveListeners = undefined;
      }
    }, {
      key: "updateHoverStyle",
      value: function updateHoverStyle(items, mode, enabled) {
        var prefix = enabled ? 'set' : 'remove';
        var meta, item, i, ilen;

        if (mode === 'dataset') {
          meta = this.getDatasetMeta(items[0].datasetIndex);
          meta.controller['_' + prefix + 'DatasetHoverStyle']();
        }

        for (i = 0, ilen = items.length; i < ilen; ++i) {
          item = items[i];
          var controller = item && this.getDatasetMeta(item.datasetIndex).controller;

          if (controller) {
            controller[prefix + 'HoverStyle'](item.element, item.datasetIndex, item.index);
          }
        }
      }
    }, {
      key: "getActiveElements",
      value: function getActiveElements() {
        return this._active || [];
      }
    }, {
      key: "setActiveElements",
      value: function setActiveElements(activeElements) {
        var _this21 = this;

        var lastActive = this._active || [];
        var active = activeElements.map(function (_ref4) {
          var datasetIndex = _ref4.datasetIndex,
              index = _ref4.index;

          var meta = _this21.getDatasetMeta(datasetIndex);

          if (!meta) {
            throw new Error('No dataset found at index ' + datasetIndex);
          }

          return {
            datasetIndex: datasetIndex,
            element: meta.data[index],
            index: index
          };
        });
        var changed = !_elementsEqual(active, lastActive);

        if (changed) {
          this._active = active;
          this._lastEvent = null;

          this._updateHoverStyles(active, lastActive);
        }
      }
    }, {
      key: "notifyPlugins",
      value: function notifyPlugins(hook, args, filter) {
        return this._plugins.notify(this, hook, args, filter);
      }
    }, {
      key: "_updateHoverStyles",
      value: function _updateHoverStyles(active, lastActive, replay) {
        var hoverOptions = this.options.hover;

        var diff = function diff(a, b) {
          return a.filter(function (x) {
            return !b.some(function (y) {
              return x.datasetIndex === y.datasetIndex && x.index === y.index;
            });
          });
        };

        var deactivated = diff(lastActive, active);
        var activated = replay ? active : diff(active, lastActive);

        if (deactivated.length) {
          this.updateHoverStyle(deactivated, hoverOptions.mode, false);
        }

        if (activated.length && hoverOptions.mode) {
          this.updateHoverStyle(activated, hoverOptions.mode, true);
        }
      }
    }, {
      key: "_eventHandler",
      value: function _eventHandler(e, replay) {
        var _this22 = this;

        var args = {
          event: e,
          replay: replay,
          cancelable: true,
          inChartArea: this.isPointInArea(e)
        };

        var eventFilter = function eventFilter(plugin) {
          return (plugin.options.events || _this22.options.events).includes(e.native.type);
        };

        if (this.notifyPlugins('beforeEvent', args, eventFilter) === false) {
          return;
        }

        var changed = this._handleEvent(e, replay, args.inChartArea);

        args.cancelable = false;
        this.notifyPlugins('afterEvent', args, eventFilter);

        if (changed || args.changed) {
          this.render();
        }

        return this;
      }
    }, {
      key: "_handleEvent",
      value: function _handleEvent(e, replay, inChartArea) {
        var _this$_active = this._active,
            lastActive = _this$_active === void 0 ? [] : _this$_active,
            options = this.options;
        var useFinalPosition = replay;

        var active = this._getActiveElements(e, lastActive, inChartArea, useFinalPosition);

        var isClick = _isClickEvent(e);

        var lastEvent = determineLastEvent(e, this._lastEvent, inChartArea, isClick);

        if (inChartArea) {
          this._lastEvent = null;
          callback(options.onHover, [e, active, this], this);

          if (isClick) {
            callback(options.onClick, [e, active, this], this);
          }
        }

        var changed = !_elementsEqual(active, lastActive);

        if (changed || replay) {
          this._active = active;

          this._updateHoverStyles(active, lastActive, replay);
        }

        this._lastEvent = lastEvent;
        return changed;
      }
    }, {
      key: "_getActiveElements",
      value: function _getActiveElements(e, lastActive, inChartArea, useFinalPosition) {
        if (e.type === 'mouseout') {
          return [];
        }

        if (!inChartArea) {
          return lastActive;
        }

        var hoverOptions = this.options.hover;
        return this.getElementsAtEventForMode(e, hoverOptions.mode, hoverOptions, useFinalPosition);
      }
    }]);

    return Chart;
  }();

  var invalidatePlugins = function invalidatePlugins() {
    return each(Chart.instances, function (chart) {
      return chart._plugins.invalidate();
    });
  };

  var enumerable = true;
  Object.defineProperties(Chart, {
    defaults: {
      enumerable: enumerable,
      value: defaults
    },
    instances: {
      enumerable: enumerable,
      value: instances
    },
    overrides: {
      enumerable: enumerable,
      value: overrides
    },
    registry: {
      enumerable: enumerable,
      value: registry
    },
    version: {
      enumerable: enumerable,
      value: version
    },
    getChart: {
      enumerable: enumerable,
      value: getChart
    },
    register: {
      enumerable: enumerable,
      value: function value() {
        registry.add.apply(registry, arguments);
        invalidatePlugins();
      }
    },
    unregister: {
      enumerable: enumerable,
      value: function value() {
        registry.remove.apply(registry, arguments);
        invalidatePlugins();
      }
    }
  });

  function clipArc(ctx, element, endAngle) {
    var startAngle = element.startAngle,
        pixelMargin = element.pixelMargin,
        x = element.x,
        y = element.y,
        outerRadius = element.outerRadius,
        innerRadius = element.innerRadius;
    var angleMargin = pixelMargin / outerRadius;
    ctx.beginPath();
    ctx.arc(x, y, outerRadius, startAngle - angleMargin, endAngle + angleMargin);

    if (innerRadius > pixelMargin) {
      angleMargin = pixelMargin / innerRadius;
      ctx.arc(x, y, innerRadius, endAngle + angleMargin, startAngle - angleMargin, true);
    } else {
      ctx.arc(x, y, pixelMargin, endAngle + HALF_PI, startAngle - HALF_PI);
    }

    ctx.closePath();
    ctx.clip();
  }

  function toRadiusCorners(value) {
    return _readValueToProps(value, ['outerStart', 'outerEnd', 'innerStart', 'innerEnd']);
  }

  function parseBorderRadius$1(arc, innerRadius, outerRadius, angleDelta) {
    var o = toRadiusCorners(arc.options.borderRadius);
    var halfThickness = (outerRadius - innerRadius) / 2;
    var innerLimit = Math.min(halfThickness, angleDelta * innerRadius / 2);

    var computeOuterLimit = function computeOuterLimit(val) {
      var outerArcLimit = (outerRadius - Math.min(halfThickness, val)) * angleDelta / 2;
      return _limitValue(val, 0, Math.min(halfThickness, outerArcLimit));
    };

    return {
      outerStart: computeOuterLimit(o.outerStart),
      outerEnd: computeOuterLimit(o.outerEnd),
      innerStart: _limitValue(o.innerStart, 0, innerLimit),
      innerEnd: _limitValue(o.innerEnd, 0, innerLimit)
    };
  }

  function rThetaToXY(r, theta, x, y) {
    return {
      x: x + r * Math.cos(theta),
      y: y + r * Math.sin(theta)
    };
  }

  function pathArc(ctx, element, offset, spacing, end, circular) {
    var x = element.x,
        y = element.y,
        start = element.startAngle,
        pixelMargin = element.pixelMargin,
        innerR = element.innerRadius;
    var outerRadius = Math.max(element.outerRadius + spacing + offset - pixelMargin, 0);
    var innerRadius = innerR > 0 ? innerR + spacing + offset + pixelMargin : 0;
    var spacingOffset = 0;
    var alpha = end - start;

    if (spacing) {
      var noSpacingInnerRadius = innerR > 0 ? innerR - spacing : 0;
      var noSpacingOuterRadius = outerRadius > 0 ? outerRadius - spacing : 0;
      var avNogSpacingRadius = (noSpacingInnerRadius + noSpacingOuterRadius) / 2;
      var adjustedAngle = avNogSpacingRadius !== 0 ? alpha * avNogSpacingRadius / (avNogSpacingRadius + spacing) : alpha;
      spacingOffset = (alpha - adjustedAngle) / 2;
    }

    var beta = Math.max(0.001, alpha * outerRadius - offset / PI) / outerRadius;
    var angleOffset = (alpha - beta) / 2;
    var startAngle = start + angleOffset + spacingOffset;
    var endAngle = end - angleOffset - spacingOffset;

    var _parseBorderRadius$ = parseBorderRadius$1(element, innerRadius, outerRadius, endAngle - startAngle),
        outerStart = _parseBorderRadius$.outerStart,
        outerEnd = _parseBorderRadius$.outerEnd,
        innerStart = _parseBorderRadius$.innerStart,
        innerEnd = _parseBorderRadius$.innerEnd;

    var outerStartAdjustedRadius = outerRadius - outerStart;
    var outerEndAdjustedRadius = outerRadius - outerEnd;
    var outerStartAdjustedAngle = startAngle + outerStart / outerStartAdjustedRadius;
    var outerEndAdjustedAngle = endAngle - outerEnd / outerEndAdjustedRadius;
    var innerStartAdjustedRadius = innerRadius + innerStart;
    var innerEndAdjustedRadius = innerRadius + innerEnd;
    var innerStartAdjustedAngle = startAngle + innerStart / innerStartAdjustedRadius;
    var innerEndAdjustedAngle = endAngle - innerEnd / innerEndAdjustedRadius;
    ctx.beginPath();

    if (circular) {
      ctx.arc(x, y, outerRadius, outerStartAdjustedAngle, outerEndAdjustedAngle);

      if (outerEnd > 0) {
        var pCenter = rThetaToXY(outerEndAdjustedRadius, outerEndAdjustedAngle, x, y);
        ctx.arc(pCenter.x, pCenter.y, outerEnd, outerEndAdjustedAngle, endAngle + HALF_PI);
      }

      var p4 = rThetaToXY(innerEndAdjustedRadius, endAngle, x, y);
      ctx.lineTo(p4.x, p4.y);

      if (innerEnd > 0) {
        var _pCenter = rThetaToXY(innerEndAdjustedRadius, innerEndAdjustedAngle, x, y);

        ctx.arc(_pCenter.x, _pCenter.y, innerEnd, endAngle + HALF_PI, innerEndAdjustedAngle + Math.PI);
      }

      ctx.arc(x, y, innerRadius, endAngle - innerEnd / innerRadius, startAngle + innerStart / innerRadius, true);

      if (innerStart > 0) {
        var _pCenter2 = rThetaToXY(innerStartAdjustedRadius, innerStartAdjustedAngle, x, y);

        ctx.arc(_pCenter2.x, _pCenter2.y, innerStart, innerStartAdjustedAngle + Math.PI, startAngle - HALF_PI);
      }

      var p8 = rThetaToXY(outerStartAdjustedRadius, startAngle, x, y);
      ctx.lineTo(p8.x, p8.y);

      if (outerStart > 0) {
        var _pCenter3 = rThetaToXY(outerStartAdjustedRadius, outerStartAdjustedAngle, x, y);

        ctx.arc(_pCenter3.x, _pCenter3.y, outerStart, startAngle - HALF_PI, outerStartAdjustedAngle);
      }
    } else {
      ctx.moveTo(x, y);
      var outerStartX = Math.cos(outerStartAdjustedAngle) * outerRadius + x;
      var outerStartY = Math.sin(outerStartAdjustedAngle) * outerRadius + y;
      ctx.lineTo(outerStartX, outerStartY);
      var outerEndX = Math.cos(outerEndAdjustedAngle) * outerRadius + x;
      var outerEndY = Math.sin(outerEndAdjustedAngle) * outerRadius + y;
      ctx.lineTo(outerEndX, outerEndY);
    }

    ctx.closePath();
  }

  function drawArc(ctx, element, offset, spacing, circular) {
    var fullCircles = element.fullCircles,
        startAngle = element.startAngle,
        circumference = element.circumference;
    var endAngle = element.endAngle;

    if (fullCircles) {
      pathArc(ctx, element, offset, spacing, startAngle + TAU, circular);

      for (var i = 0; i < fullCircles; ++i) {
        ctx.fill();
      }

      if (!isNaN(circumference)) {
        endAngle = startAngle + circumference % TAU;

        if (circumference % TAU === 0) {
          endAngle += TAU;
        }
      }
    }

    pathArc(ctx, element, offset, spacing, endAngle, circular);
    ctx.fill();
    return endAngle;
  }

  function drawFullCircleBorders(ctx, element, inner) {
    var x = element.x,
        y = element.y,
        startAngle = element.startAngle,
        pixelMargin = element.pixelMargin,
        fullCircles = element.fullCircles;
    var outerRadius = Math.max(element.outerRadius - pixelMargin, 0);
    var innerRadius = element.innerRadius + pixelMargin;
    var i;

    if (inner) {
      clipArc(ctx, element, startAngle + TAU);
    }

    ctx.beginPath();
    ctx.arc(x, y, innerRadius, startAngle + TAU, startAngle, true);

    for (i = 0; i < fullCircles; ++i) {
      ctx.stroke();
    }

    ctx.beginPath();
    ctx.arc(x, y, outerRadius, startAngle, startAngle + TAU);

    for (i = 0; i < fullCircles; ++i) {
      ctx.stroke();
    }
  }

  function drawBorder(ctx, element, offset, spacing, endAngle, circular) {
    var options = element.options;
    var borderWidth = options.borderWidth,
        borderJoinStyle = options.borderJoinStyle;
    var inner = options.borderAlign === 'inner';

    if (!borderWidth) {
      return;
    }

    if (inner) {
      ctx.lineWidth = borderWidth * 2;
      ctx.lineJoin = borderJoinStyle || 'round';
    } else {
      ctx.lineWidth = borderWidth;
      ctx.lineJoin = borderJoinStyle || 'bevel';
    }

    if (element.fullCircles) {
      drawFullCircleBorders(ctx, element, inner);
    }

    if (inner) {
      clipArc(ctx, element, endAngle);
    }

    pathArc(ctx, element, offset, spacing, endAngle, circular);
    ctx.stroke();
  }

  var ArcElement = /*#__PURE__*/function (_Element2) {
    _inherits(ArcElement, _Element2);

    var _super12 = _createSuper(ArcElement);

    function ArcElement(cfg) {
      var _this23;

      _classCallCheck(this, ArcElement);

      _this23 = _super12.call(this);
      _this23.options = undefined;
      _this23.circumference = undefined;
      _this23.startAngle = undefined;
      _this23.endAngle = undefined;
      _this23.innerRadius = undefined;
      _this23.outerRadius = undefined;
      _this23.pixelMargin = 0;
      _this23.fullCircles = 0;

      if (cfg) {
        Object.assign(_assertThisInitialized(_this23), cfg);
      }

      return _this23;
    }

    _createClass(ArcElement, [{
      key: "inRange",
      value: function inRange(chartX, chartY, useFinalPosition) {
        var point = this.getProps(['x', 'y'], useFinalPosition);

        var _getAngleFromPoint2 = getAngleFromPoint(point, {
          x: chartX,
          y: chartY
        }),
            angle = _getAngleFromPoint2.angle,
            distance = _getAngleFromPoint2.distance;

        var _this$getProps2 = this.getProps(['startAngle', 'endAngle', 'innerRadius', 'outerRadius', 'circumference'], useFinalPosition),
            startAngle = _this$getProps2.startAngle,
            endAngle = _this$getProps2.endAngle,
            innerRadius = _this$getProps2.innerRadius,
            outerRadius = _this$getProps2.outerRadius,
            circumference = _this$getProps2.circumference;

        var rAdjust = this.options.spacing / 2;

        var _circumference = valueOrDefault(circumference, endAngle - startAngle);

        var betweenAngles = _circumference >= TAU || _angleBetween(angle, startAngle, endAngle);

        var withinRadius = _isBetween(distance, innerRadius + rAdjust, outerRadius + rAdjust);

        return betweenAngles && withinRadius;
      }
    }, {
      key: "getCenterPoint",
      value: function getCenterPoint(useFinalPosition) {
        var _this$getProps3 = this.getProps(['x', 'y', 'startAngle', 'endAngle', 'innerRadius', 'outerRadius', 'circumference'], useFinalPosition),
            x = _this$getProps3.x,
            y = _this$getProps3.y,
            startAngle = _this$getProps3.startAngle,
            endAngle = _this$getProps3.endAngle,
            innerRadius = _this$getProps3.innerRadius,
            outerRadius = _this$getProps3.outerRadius;

        var _this$options12 = this.options,
            offset = _this$options12.offset,
            spacing = _this$options12.spacing;
        var halfAngle = (startAngle + endAngle) / 2;
        var halfRadius = (innerRadius + outerRadius + spacing + offset) / 2;
        return {
          x: x + Math.cos(halfAngle) * halfRadius,
          y: y + Math.sin(halfAngle) * halfRadius
        };
      }
    }, {
      key: "tooltipPosition",
      value: function tooltipPosition(useFinalPosition) {
        return this.getCenterPoint(useFinalPosition);
      }
    }, {
      key: "draw",
      value: function draw(ctx) {
        var options = this.options,
            circumference = this.circumference;
        var offset = (options.offset || 0) / 2;
        var spacing = (options.spacing || 0) / 2;
        var circular = options.circular;
        this.pixelMargin = options.borderAlign === 'inner' ? 0.33 : 0;
        this.fullCircles = circumference > TAU ? Math.floor(circumference / TAU) : 0;

        if (circumference === 0 || this.innerRadius < 0 || this.outerRadius < 0) {
          return;
        }

        ctx.save();
        var radiusOffset = 0;

        if (offset) {
          radiusOffset = offset / 2;
          var halfAngle = (this.startAngle + this.endAngle) / 2;
          ctx.translate(Math.cos(halfAngle) * radiusOffset, Math.sin(halfAngle) * radiusOffset);

          if (this.circumference >= PI) {
            radiusOffset = offset;
          }
        }

        ctx.fillStyle = options.backgroundColor;
        ctx.strokeStyle = options.borderColor;
        var endAngle = drawArc(ctx, this, radiusOffset, spacing, circular);
        drawBorder(ctx, this, radiusOffset, spacing, endAngle, circular);
        ctx.restore();
      }
    }]);

    return ArcElement;
  }(Element);

  ArcElement.id = 'arc';
  ArcElement.defaults = {
    borderAlign: 'center',
    borderColor: '#fff',
    borderJoinStyle: undefined,
    borderRadius: 0,
    borderWidth: 2,
    offset: 0,
    spacing: 0,
    angle: undefined,
    circular: true
  };
  ArcElement.defaultRoutes = {
    backgroundColor: 'backgroundColor'
  };

  function setStyle(ctx, options) {
    var style = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : options;
    ctx.lineCap = valueOrDefault(style.borderCapStyle, options.borderCapStyle);
    ctx.setLineDash(valueOrDefault(style.borderDash, options.borderDash));
    ctx.lineDashOffset = valueOrDefault(style.borderDashOffset, options.borderDashOffset);
    ctx.lineJoin = valueOrDefault(style.borderJoinStyle, options.borderJoinStyle);
    ctx.lineWidth = valueOrDefault(style.borderWidth, options.borderWidth);
    ctx.strokeStyle = valueOrDefault(style.borderColor, options.borderColor);
  }

  function lineTo(ctx, previous, target) {
    ctx.lineTo(target.x, target.y);
  }

  function getLineMethod(options) {
    if (options.stepped) {
      return _steppedLineTo;
    }

    if (options.tension || options.cubicInterpolationMode === 'monotone') {
      return _bezierCurveTo;
    }

    return lineTo;
  }

  function pathVars(points, segment) {
    var params = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
    var count = points.length;
    var _params$start = params.start,
        paramsStart = _params$start === void 0 ? 0 : _params$start,
        _params$end = params.end,
        paramsEnd = _params$end === void 0 ? count - 1 : _params$end;
    var segmentStart = segment.start,
        segmentEnd = segment.end;
    var start = Math.max(paramsStart, segmentStart);
    var end = Math.min(paramsEnd, segmentEnd);
    var outside = paramsStart < segmentStart && paramsEnd < segmentStart || paramsStart > segmentEnd && paramsEnd > segmentEnd;
    return {
      count: count,
      start: start,
      loop: segment.loop,
      ilen: end < start && !outside ? count + end - start : end - start
    };
  }

  function pathSegment(ctx, line, segment, params) {
    var points = line.points,
        options = line.options;

    var _pathVars = pathVars(points, segment, params),
        count = _pathVars.count,
        start = _pathVars.start,
        loop = _pathVars.loop,
        ilen = _pathVars.ilen;

    var lineMethod = getLineMethod(options);

    var _ref5 = params || {},
        _ref5$move = _ref5.move,
        move = _ref5$move === void 0 ? true : _ref5$move,
        reverse = _ref5.reverse;

    var i, point, prev;

    for (i = 0; i <= ilen; ++i) {
      point = points[(start + (reverse ? ilen - i : i)) % count];

      if (point.skip) {
        continue;
      } else if (move) {
        ctx.moveTo(point.x, point.y);
        move = false;
      } else {
        lineMethod(ctx, prev, point, reverse, options.stepped);
      }

      prev = point;
    }

    if (loop) {
      point = points[(start + (reverse ? ilen : 0)) % count];
      lineMethod(ctx, prev, point, reverse, options.stepped);
    }

    return !!loop;
  }

  function fastPathSegment(ctx, line, segment, params) {
    var points = line.points;

    var _pathVars2 = pathVars(points, segment, params),
        count = _pathVars2.count,
        start = _pathVars2.start,
        ilen = _pathVars2.ilen;

    var _ref6 = params || {},
        _ref6$move = _ref6.move,
        move = _ref6$move === void 0 ? true : _ref6$move,
        reverse = _ref6.reverse;

    var avgX = 0;
    var countX = 0;
    var i, point, prevX, minY, maxY, lastY;

    var pointIndex = function pointIndex(index) {
      return (start + (reverse ? ilen - index : index)) % count;
    };

    var drawX = function drawX() {
      if (minY !== maxY) {
        ctx.lineTo(avgX, maxY);
        ctx.lineTo(avgX, minY);
        ctx.lineTo(avgX, lastY);
      }
    };

    if (move) {
      point = points[pointIndex(0)];
      ctx.moveTo(point.x, point.y);
    }

    for (i = 0; i <= ilen; ++i) {
      point = points[pointIndex(i)];

      if (point.skip) {
        continue;
      }

      var x = point.x;
      var y = point.y;
      var truncX = x | 0;

      if (truncX === prevX) {
        if (y < minY) {
          minY = y;
        } else if (y > maxY) {
          maxY = y;
        }

        avgX = (countX * avgX + x) / ++countX;
      } else {
        drawX();
        ctx.lineTo(x, y);
        prevX = truncX;
        countX = 0;
        minY = maxY = y;
      }

      lastY = y;
    }

    drawX();
  }

  function _getSegmentMethod(line) {
    var opts = line.options;
    var borderDash = opts.borderDash && opts.borderDash.length;
    var useFastPath = !line._decimated && !line._loop && !opts.tension && opts.cubicInterpolationMode !== 'monotone' && !opts.stepped && !borderDash;
    return useFastPath ? fastPathSegment : pathSegment;
  }

  function _getInterpolationMethod(options) {
    if (options.stepped) {
      return _steppedInterpolation;
    }

    if (options.tension || options.cubicInterpolationMode === 'monotone') {
      return _bezierInterpolation;
    }

    return _pointInLine;
  }

  function strokePathWithCache(ctx, line, start, count) {
    var path = line._path;

    if (!path) {
      path = line._path = new Path2D();

      if (line.path(path, start, count)) {
        path.closePath();
      }
    }

    setStyle(ctx, line.options);
    ctx.stroke(path);
  }

  function strokePathDirect(ctx, line, start, count) {
    var segments = line.segments,
        options = line.options;

    var segmentMethod = _getSegmentMethod(line);

    var _iterator16 = _createForOfIteratorHelper(segments),
        _step16;

    try {
      for (_iterator16.s(); !(_step16 = _iterator16.n()).done;) {
        var segment = _step16.value;
        setStyle(ctx, options, segment.style);
        ctx.beginPath();

        if (segmentMethod(ctx, line, segment, {
          start: start,
          end: start + count - 1
        })) {
          ctx.closePath();
        }

        ctx.stroke();
      }
    } catch (err) {
      _iterator16.e(err);
    } finally {
      _iterator16.f();
    }
  }

  var usePath2D = typeof Path2D === 'function';

  function _draw(ctx, line, start, count) {
    if (usePath2D && !line.options.segment) {
      strokePathWithCache(ctx, line, start, count);
    } else {
      strokePathDirect(ctx, line, start, count);
    }
  }

  var LineElement = /*#__PURE__*/function (_Element3) {
    _inherits(LineElement, _Element3);

    var _super13 = _createSuper(LineElement);

    function LineElement(cfg) {
      var _this24;

      _classCallCheck(this, LineElement);

      _this24 = _super13.call(this);
      _this24.animated = true;
      _this24.options = undefined;
      _this24._chart = undefined;
      _this24._loop = undefined;
      _this24._fullLoop = undefined;
      _this24._path = undefined;
      _this24._points = undefined;
      _this24._segments = undefined;
      _this24._decimated = false;
      _this24._pointsUpdated = false;
      _this24._datasetIndex = undefined;

      if (cfg) {
        Object.assign(_assertThisInitialized(_this24), cfg);
      }

      return _this24;
    }

    _createClass(LineElement, [{
      key: "updateControlPoints",
      value: function updateControlPoints(chartArea, indexAxis) {
        var options = this.options;

        if ((options.tension || options.cubicInterpolationMode === 'monotone') && !options.stepped && !this._pointsUpdated) {
          var loop = options.spanGaps ? this._loop : this._fullLoop;

          _updateBezierControlPoints(this._points, options, chartArea, loop, indexAxis);

          this._pointsUpdated = true;
        }
      }
    }, {
      key: "points",
      get: function get() {
        return this._points;
      },
      set: function set(points) {
        this._points = points;
        delete this._segments;
        delete this._path;
        this._pointsUpdated = false;
      }
    }, {
      key: "segments",
      get: function get() {
        return this._segments || (this._segments = _computeSegments(this, this.options.segment));
      }
    }, {
      key: "first",
      value: function first() {
        var segments = this.segments;
        var points = this.points;
        return segments.length && points[segments[0].start];
      }
    }, {
      key: "last",
      value: function last() {
        var segments = this.segments;
        var points = this.points;
        var count = segments.length;
        return count && points[segments[count - 1].end];
      }
    }, {
      key: "interpolate",
      value: function interpolate(point, property) {
        var options = this.options;
        var value = point[property];
        var points = this.points;

        var segments = _boundSegments(this, {
          property: property,
          start: value,
          end: value
        });

        if (!segments.length) {
          return;
        }

        var result = [];

        var _interpolate = _getInterpolationMethod(options);

        var i, ilen;

        for (i = 0, ilen = segments.length; i < ilen; ++i) {
          var _segments$i = segments[i],
              start = _segments$i.start,
              end = _segments$i.end;
          var p1 = points[start];
          var p2 = points[end];

          if (p1 === p2) {
            result.push(p1);
            continue;
          }

          var t = Math.abs((value - p1[property]) / (p2[property] - p1[property]));

          var interpolated = _interpolate(p1, p2, t, options.stepped);

          interpolated[property] = point[property];
          result.push(interpolated);
        }

        return result.length === 1 ? result[0] : result;
      }
    }, {
      key: "pathSegment",
      value: function pathSegment(ctx, segment, params) {
        var segmentMethod = _getSegmentMethod(this);

        return segmentMethod(ctx, this, segment, params);
      }
    }, {
      key: "path",
      value: function path(ctx, start, count) {
        var segments = this.segments;

        var segmentMethod = _getSegmentMethod(this);

        var loop = this._loop;
        start = start || 0;
        count = count || this.points.length - start;

        var _iterator17 = _createForOfIteratorHelper(segments),
            _step17;

        try {
          for (_iterator17.s(); !(_step17 = _iterator17.n()).done;) {
            var segment = _step17.value;
            loop &= segmentMethod(ctx, this, segment, {
              start: start,
              end: start + count - 1
            });
          }
        } catch (err) {
          _iterator17.e(err);
        } finally {
          _iterator17.f();
        }

        return !!loop;
      }
    }, {
      key: "draw",
      value: function draw(ctx, chartArea, start, count) {
        var options = this.options || {};
        var points = this.points || [];

        if (points.length && options.borderWidth) {
          ctx.save();

          _draw(ctx, this, start, count);

          ctx.restore();
        }

        if (this.animated) {
          this._pointsUpdated = false;
          this._path = undefined;
        }
      }
    }]);

    return LineElement;
  }(Element);

  LineElement.id = 'line';
  LineElement.defaults = {
    borderCapStyle: 'butt',
    borderDash: [],
    borderDashOffset: 0,
    borderJoinStyle: 'miter',
    borderWidth: 3,
    capBezierPoints: true,
    cubicInterpolationMode: 'default',
    fill: false,
    spanGaps: false,
    stepped: false,
    tension: 0
  };
  LineElement.defaultRoutes = {
    backgroundColor: 'backgroundColor',
    borderColor: 'borderColor'
  };
  LineElement.descriptors = {
    _scriptable: true,
    _indexable: function _indexable(name) {
      return name !== 'borderDash' && name !== 'fill';
    }
  };

  function inRange$1(el, pos, axis, useFinalPosition) {
    var options = el.options;

    var _el$getProps = el.getProps([axis], useFinalPosition),
        value = _el$getProps[axis];

    return Math.abs(pos - value) < options.radius + options.hitRadius;
  }

  var PointElement = /*#__PURE__*/function (_Element4) {
    _inherits(PointElement, _Element4);

    var _super14 = _createSuper(PointElement);

    function PointElement(cfg) {
      var _this25;

      _classCallCheck(this, PointElement);

      _this25 = _super14.call(this);
      _this25.options = undefined;
      _this25.parsed = undefined;
      _this25.skip = undefined;
      _this25.stop = undefined;

      if (cfg) {
        Object.assign(_assertThisInitialized(_this25), cfg);
      }

      return _this25;
    }

    _createClass(PointElement, [{
      key: "inRange",
      value: function inRange(mouseX, mouseY, useFinalPosition) {
        var options = this.options;

        var _this$getProps4 = this.getProps(['x', 'y'], useFinalPosition),
            x = _this$getProps4.x,
            y = _this$getProps4.y;

        return Math.pow(mouseX - x, 2) + Math.pow(mouseY - y, 2) < Math.pow(options.hitRadius + options.radius, 2);
      }
    }, {
      key: "inXRange",
      value: function inXRange(mouseX, useFinalPosition) {
        return inRange$1(this, mouseX, 'x', useFinalPosition);
      }
    }, {
      key: "inYRange",
      value: function inYRange(mouseY, useFinalPosition) {
        return inRange$1(this, mouseY, 'y', useFinalPosition);
      }
    }, {
      key: "getCenterPoint",
      value: function getCenterPoint(useFinalPosition) {
        var _this$getProps5 = this.getProps(['x', 'y'], useFinalPosition),
            x = _this$getProps5.x,
            y = _this$getProps5.y;

        return {
          x: x,
          y: y
        };
      }
    }, {
      key: "size",
      value: function size(options) {
        options = options || this.options || {};
        var radius = options.radius || 0;
        radius = Math.max(radius, radius && options.hoverRadius || 0);
        var borderWidth = radius && options.borderWidth || 0;
        return (radius + borderWidth) * 2;
      }
    }, {
      key: "draw",
      value: function draw(ctx, area) {
        var options = this.options;

        if (this.skip || options.radius < 0.1 || !_isPointInArea(this, area, this.size(options) / 2)) {
          return;
        }

        ctx.strokeStyle = options.borderColor;
        ctx.lineWidth = options.borderWidth;
        ctx.fillStyle = options.backgroundColor;
        drawPoint(ctx, options, this.x, this.y);
      }
    }, {
      key: "getRange",
      value: function getRange() {
        var options = this.options || {};
        return options.radius + options.hitRadius;
      }
    }]);

    return PointElement;
  }(Element);

  PointElement.id = 'point';
  PointElement.defaults = {
    borderWidth: 1,
    hitRadius: 1,
    hoverBorderWidth: 1,
    hoverRadius: 4,
    pointStyle: 'circle',
    radius: 3,
    rotation: 0
  };
  PointElement.defaultRoutes = {
    backgroundColor: 'backgroundColor',
    borderColor: 'borderColor'
  };

  function getBarBounds(bar, useFinalPosition) {
    var _bar$getProps = bar.getProps(['x', 'y', 'base', 'width', 'height'], useFinalPosition),
        x = _bar$getProps.x,
        y = _bar$getProps.y,
        base = _bar$getProps.base,
        width = _bar$getProps.width,
        height = _bar$getProps.height;

    var left, right, top, bottom, half;

    if (bar.horizontal) {
      half = height / 2;
      left = Math.min(x, base);
      right = Math.max(x, base);
      top = y - half;
      bottom = y + half;
    } else {
      half = width / 2;
      left = x - half;
      right = x + half;
      top = Math.min(y, base);
      bottom = Math.max(y, base);
    }

    return {
      left: left,
      top: top,
      right: right,
      bottom: bottom
    };
  }

  function skipOrLimit(skip, value, min, max) {
    return skip ? 0 : _limitValue(value, min, max);
  }

  function parseBorderWidth(bar, maxW, maxH) {
    var value = bar.options.borderWidth;
    var skip = bar.borderSkipped;
    var o = toTRBL(value);
    return {
      t: skipOrLimit(skip.top, o.top, 0, maxH),
      r: skipOrLimit(skip.right, o.right, 0, maxW),
      b: skipOrLimit(skip.bottom, o.bottom, 0, maxH),
      l: skipOrLimit(skip.left, o.left, 0, maxW)
    };
  }

  function parseBorderRadius(bar, maxW, maxH) {
    var _bar$getProps2 = bar.getProps(['enableBorderRadius']),
        enableBorderRadius = _bar$getProps2.enableBorderRadius;

    var value = bar.options.borderRadius;
    var o = toTRBLCorners(value);
    var maxR = Math.min(maxW, maxH);
    var skip = bar.borderSkipped;
    var enableBorder = enableBorderRadius || isObject(value);
    return {
      topLeft: skipOrLimit(!enableBorder || skip.top || skip.left, o.topLeft, 0, maxR),
      topRight: skipOrLimit(!enableBorder || skip.top || skip.right, o.topRight, 0, maxR),
      bottomLeft: skipOrLimit(!enableBorder || skip.bottom || skip.left, o.bottomLeft, 0, maxR),
      bottomRight: skipOrLimit(!enableBorder || skip.bottom || skip.right, o.bottomRight, 0, maxR)
    };
  }

  function boundingRects(bar) {
    var bounds = getBarBounds(bar);
    var width = bounds.right - bounds.left;
    var height = bounds.bottom - bounds.top;
    var border = parseBorderWidth(bar, width / 2, height / 2);
    var radius = parseBorderRadius(bar, width / 2, height / 2);
    return {
      outer: {
        x: bounds.left,
        y: bounds.top,
        w: width,
        h: height,
        radius: radius
      },
      inner: {
        x: bounds.left + border.l,
        y: bounds.top + border.t,
        w: width - border.l - border.r,
        h: height - border.t - border.b,
        radius: {
          topLeft: Math.max(0, radius.topLeft - Math.max(border.t, border.l)),
          topRight: Math.max(0, radius.topRight - Math.max(border.t, border.r)),
          bottomLeft: Math.max(0, radius.bottomLeft - Math.max(border.b, border.l)),
          bottomRight: Math.max(0, radius.bottomRight - Math.max(border.b, border.r))
        }
      }
    };
  }

  function _inRange(bar, x, y, useFinalPosition) {
    var skipX = x === null;
    var skipY = y === null;
    var skipBoth = skipX && skipY;
    var bounds = bar && !skipBoth && getBarBounds(bar, useFinalPosition);
    return bounds && (skipX || _isBetween(x, bounds.left, bounds.right)) && (skipY || _isBetween(y, bounds.top, bounds.bottom));
  }

  function hasRadius(radius) {
    return radius.topLeft || radius.topRight || radius.bottomLeft || radius.bottomRight;
  }

  function addNormalRectPath(ctx, rect) {
    ctx.rect(rect.x, rect.y, rect.w, rect.h);
  }

  function inflateRect(rect, amount) {
    var refRect = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
    var x = rect.x !== refRect.x ? -amount : 0;
    var y = rect.y !== refRect.y ? -amount : 0;
    var w = (rect.x + rect.w !== refRect.x + refRect.w ? amount : 0) - x;
    var h = (rect.y + rect.h !== refRect.y + refRect.h ? amount : 0) - y;
    return {
      x: rect.x + x,
      y: rect.y + y,
      w: rect.w + w,
      h: rect.h + h,
      radius: rect.radius
    };
  }

  var BarElement = /*#__PURE__*/function (_Element5) {
    _inherits(BarElement, _Element5);

    var _super15 = _createSuper(BarElement);

    function BarElement(cfg) {
      var _this26;

      _classCallCheck(this, BarElement);

      _this26 = _super15.call(this);
      _this26.options = undefined;
      _this26.horizontal = undefined;
      _this26.base = undefined;
      _this26.width = undefined;
      _this26.height = undefined;
      _this26.inflateAmount = undefined;

      if (cfg) {
        Object.assign(_assertThisInitialized(_this26), cfg);
      }

      return _this26;
    }

    _createClass(BarElement, [{
      key: "draw",
      value: function draw(ctx) {
        var inflateAmount = this.inflateAmount,
            _this$options13 = this.options,
            borderColor = _this$options13.borderColor,
            backgroundColor = _this$options13.backgroundColor;

        var _boundingRects = boundingRects(this),
            inner = _boundingRects.inner,
            outer = _boundingRects.outer;

        var addRectPath = hasRadius(outer.radius) ? addRoundedRectPath : addNormalRectPath;
        ctx.save();

        if (outer.w !== inner.w || outer.h !== inner.h) {
          ctx.beginPath();
          addRectPath(ctx, inflateRect(outer, inflateAmount, inner));
          ctx.clip();
          addRectPath(ctx, inflateRect(inner, -inflateAmount, outer));
          ctx.fillStyle = borderColor;
          ctx.fill('evenodd');
        }

        ctx.beginPath();
        addRectPath(ctx, inflateRect(inner, inflateAmount));
        ctx.fillStyle = backgroundColor;
        ctx.fill();
        ctx.restore();
      }
    }, {
      key: "inRange",
      value: function inRange(mouseX, mouseY, useFinalPosition) {
        return _inRange(this, mouseX, mouseY, useFinalPosition);
      }
    }, {
      key: "inXRange",
      value: function inXRange(mouseX, useFinalPosition) {
        return _inRange(this, mouseX, null, useFinalPosition);
      }
    }, {
      key: "inYRange",
      value: function inYRange(mouseY, useFinalPosition) {
        return _inRange(this, null, mouseY, useFinalPosition);
      }
    }, {
      key: "getCenterPoint",
      value: function getCenterPoint(useFinalPosition) {
        var _this$getProps6 = this.getProps(['x', 'y', 'base', 'horizontal'], useFinalPosition),
            x = _this$getProps6.x,
            y = _this$getProps6.y,
            base = _this$getProps6.base,
            horizontal = _this$getProps6.horizontal;

        return {
          x: horizontal ? (x + base) / 2 : x,
          y: horizontal ? y : (y + base) / 2
        };
      }
    }, {
      key: "getRange",
      value: function getRange(axis) {
        return axis === 'x' ? this.width / 2 : this.height / 2;
      }
    }]);

    return BarElement;
  }(Element);

  BarElement.id = 'bar';
  BarElement.defaults = {
    borderSkipped: 'start',
    borderWidth: 0,
    borderRadius: 0,
    inflateAmount: 'auto',
    pointStyle: undefined
  };
  BarElement.defaultRoutes = {
    backgroundColor: 'backgroundColor',
    borderColor: 'borderColor'
  };
  var elements = /*#__PURE__*/Object.freeze({
    __proto__: null,
    ArcElement: ArcElement,
    LineElement: LineElement,
    PointElement: PointElement,
    BarElement: BarElement
  });

  function lttbDecimation(data, start, count, availableWidth, options) {
    var samples = options.samples || availableWidth;

    if (samples >= count) {
      return data.slice(start, start + count);
    }

    var decimated = [];
    var bucketWidth = (count - 2) / (samples - 2);
    var sampledIndex = 0;
    var endIndex = start + count - 1;
    var a = start;
    var i, maxAreaPoint, maxArea, area, nextA;
    decimated[sampledIndex++] = data[a];

    for (i = 0; i < samples - 2; i++) {
      var avgX = 0;
      var avgY = 0;
      var j = void 0;
      var avgRangeStart = Math.floor((i + 1) * bucketWidth) + 1 + start;
      var avgRangeEnd = Math.min(Math.floor((i + 2) * bucketWidth) + 1, count) + start;
      var avgRangeLength = avgRangeEnd - avgRangeStart;

      for (j = avgRangeStart; j < avgRangeEnd; j++) {
        avgX += data[j].x;
        avgY += data[j].y;
      }

      avgX /= avgRangeLength;
      avgY /= avgRangeLength;
      var rangeOffs = Math.floor(i * bucketWidth) + 1 + start;
      var rangeTo = Math.min(Math.floor((i + 1) * bucketWidth) + 1, count) + start;
      var _data$a = data[a],
          pointAx = _data$a.x,
          pointAy = _data$a.y;
      maxArea = area = -1;

      for (j = rangeOffs; j < rangeTo; j++) {
        area = 0.5 * Math.abs((pointAx - avgX) * (data[j].y - pointAy) - (pointAx - data[j].x) * (avgY - pointAy));

        if (area > maxArea) {
          maxArea = area;
          maxAreaPoint = data[j];
          nextA = j;
        }
      }

      decimated[sampledIndex++] = maxAreaPoint;
      a = nextA;
    }

    decimated[sampledIndex++] = data[endIndex];
    return decimated;
  }

  function minMaxDecimation(data, start, count, availableWidth) {
    var avgX = 0;
    var countX = 0;
    var i, point, x, y, prevX, minIndex, maxIndex, startIndex, minY, maxY;
    var decimated = [];
    var endIndex = start + count - 1;
    var xMin = data[start].x;
    var xMax = data[endIndex].x;
    var dx = xMax - xMin;

    for (i = start; i < start + count; ++i) {
      point = data[i];
      x = (point.x - xMin) / dx * availableWidth;
      y = point.y;
      var truncX = x | 0;

      if (truncX === prevX) {
        if (y < minY) {
          minY = y;
          minIndex = i;
        } else if (y > maxY) {
          maxY = y;
          maxIndex = i;
        }

        avgX = (countX * avgX + point.x) / ++countX;
      } else {
        var lastIndex = i - 1;

        if (!isNullOrUndef(minIndex) && !isNullOrUndef(maxIndex)) {
          var intermediateIndex1 = Math.min(minIndex, maxIndex);
          var intermediateIndex2 = Math.max(minIndex, maxIndex);

          if (intermediateIndex1 !== startIndex && intermediateIndex1 !== lastIndex) {
            decimated.push(_objectSpread2(_objectSpread2({}, data[intermediateIndex1]), {}, {
              x: avgX
            }));
          }

          if (intermediateIndex2 !== startIndex && intermediateIndex2 !== lastIndex) {
            decimated.push(_objectSpread2(_objectSpread2({}, data[intermediateIndex2]), {}, {
              x: avgX
            }));
          }
        }

        if (i > 0 && lastIndex !== startIndex) {
          decimated.push(data[lastIndex]);
        }

        decimated.push(point);
        prevX = truncX;
        countX = 0;
        minY = maxY = y;
        minIndex = maxIndex = startIndex = i;
      }
    }

    return decimated;
  }

  function cleanDecimatedDataset(dataset) {
    if (dataset._decimated) {
      var data = dataset._data;
      delete dataset._decimated;
      delete dataset._data;
      Object.defineProperty(dataset, 'data', {
        value: data
      });
    }
  }

  function cleanDecimatedData(chart) {
    chart.data.datasets.forEach(function (dataset) {
      cleanDecimatedDataset(dataset);
    });
  }

  function getStartAndCountOfVisiblePointsSimplified(meta, points) {
    var pointCount = points.length;
    var start = 0;
    var count;
    var iScale = meta.iScale;

    var _iScale$getUserBounds = iScale.getUserBounds(),
        min = _iScale$getUserBounds.min,
        max = _iScale$getUserBounds.max,
        minDefined = _iScale$getUserBounds.minDefined,
        maxDefined = _iScale$getUserBounds.maxDefined;

    if (minDefined) {
      start = _limitValue(_lookupByKey(points, iScale.axis, min).lo, 0, pointCount - 1);
    }

    if (maxDefined) {
      count = _limitValue(_lookupByKey(points, iScale.axis, max).hi + 1, start, pointCount) - start;
    } else {
      count = pointCount - start;
    }

    return {
      start: start,
      count: count
    };
  }

  var plugin_decimation = {
    id: 'decimation',
    defaults: {
      algorithm: 'min-max',
      enabled: false
    },
    beforeElementsUpdate: function beforeElementsUpdate(chart, args, options) {
      if (!options.enabled) {
        cleanDecimatedData(chart);
        return;
      }

      var availableWidth = chart.width;
      chart.data.datasets.forEach(function (dataset, datasetIndex) {
        var _data = dataset._data,
            indexAxis = dataset.indexAxis;
        var meta = chart.getDatasetMeta(datasetIndex);
        var data = _data || dataset.data;

        if (resolve([indexAxis, chart.options.indexAxis]) === 'y') {
          return;
        }

        if (!meta.controller.supportsDecimation) {
          return;
        }

        var xAxis = chart.scales[meta.xAxisID];

        if (xAxis.type !== 'linear' && xAxis.type !== 'time') {
          return;
        }

        if (chart.options.parsing) {
          return;
        }

        var _getStartAndCountOfVi3 = getStartAndCountOfVisiblePointsSimplified(meta, data),
            start = _getStartAndCountOfVi3.start,
            count = _getStartAndCountOfVi3.count;

        var threshold = options.threshold || 4 * availableWidth;

        if (count <= threshold) {
          cleanDecimatedDataset(dataset);
          return;
        }

        if (isNullOrUndef(_data)) {
          dataset._data = data;
          delete dataset.data;
          Object.defineProperty(dataset, 'data', {
            configurable: true,
            enumerable: true,
            get: function get() {
              return this._decimated;
            },
            set: function set(d) {
              this._data = d;
            }
          });
        }

        var decimated;

        switch (options.algorithm) {
          case 'lttb':
            decimated = lttbDecimation(data, start, count, availableWidth, options);
            break;

          case 'min-max':
            decimated = minMaxDecimation(data, start, count, availableWidth);
            break;

          default:
            throw new Error("Unsupported decimation algorithm '".concat(options.algorithm, "'"));
        }

        dataset._decimated = decimated;
      });
    },
    destroy: function destroy(chart) {
      cleanDecimatedData(chart);
    }
  };

  function _segments(line, target, property) {
    var segments = line.segments;
    var points = line.points;
    var tpoints = target.points;
    var parts = [];

    var _iterator18 = _createForOfIteratorHelper(segments),
        _step18;

    try {
      for (_iterator18.s(); !(_step18 = _iterator18.n()).done;) {
        var segment = _step18.value;
        var start = segment.start,
            end = segment.end;
        end = _findSegmentEnd(start, end, points);

        var bounds = _getBounds(property, points[start], points[end], segment.loop);

        if (!target.segments) {
          parts.push({
            source: segment,
            target: bounds,
            start: points[start],
            end: points[end]
          });
          continue;
        }

        var targetSegments = _boundSegments(target, bounds);

        var _iterator19 = _createForOfIteratorHelper(targetSegments),
            _step19;

        try {
          for (_iterator19.s(); !(_step19 = _iterator19.n()).done;) {
            var tgt = _step19.value;

            var subBounds = _getBounds(property, tpoints[tgt.start], tpoints[tgt.end], tgt.loop);

            var fillSources = _boundSegment(segment, points, subBounds);

            var _iterator20 = _createForOfIteratorHelper(fillSources),
                _step20;

            try {
              for (_iterator20.s(); !(_step20 = _iterator20.n()).done;) {
                var fillSource = _step20.value;
                parts.push({
                  source: fillSource,
                  target: tgt,
                  start: _defineProperty$x({}, property, _getEdge(bounds, subBounds, 'start', Math.max)),
                  end: _defineProperty$x({}, property, _getEdge(bounds, subBounds, 'end', Math.min))
                });
              }
            } catch (err) {
              _iterator20.e(err);
            } finally {
              _iterator20.f();
            }
          }
        } catch (err) {
          _iterator19.e(err);
        } finally {
          _iterator19.f();
        }
      }
    } catch (err) {
      _iterator18.e(err);
    } finally {
      _iterator18.f();
    }

    return parts;
  }

  function _getBounds(property, first, last, loop) {
    if (loop) {
      return;
    }

    var start = first[property];
    var end = last[property];

    if (property === 'angle') {
      start = _normalizeAngle(start);
      end = _normalizeAngle(end);
    }

    return {
      property: property,
      start: start,
      end: end
    };
  }

  function _pointsFromSegments(boundary, line) {
    var _ref7 = boundary || {},
        _ref7$x = _ref7.x,
        x = _ref7$x === void 0 ? null : _ref7$x,
        _ref7$y = _ref7.y,
        y = _ref7$y === void 0 ? null : _ref7$y;

    var linePoints = line.points;
    var points = [];
    line.segments.forEach(function (_ref8) {
      var start = _ref8.start,
          end = _ref8.end;
      end = _findSegmentEnd(start, end, linePoints);
      var first = linePoints[start];
      var last = linePoints[end];

      if (y !== null) {
        points.push({
          x: first.x,
          y: y
        });
        points.push({
          x: last.x,
          y: y
        });
      } else if (x !== null) {
        points.push({
          x: x,
          y: first.y
        });
        points.push({
          x: x,
          y: last.y
        });
      }
    });
    return points;
  }

  function _findSegmentEnd(start, end, points) {
    for (; end > start; end--) {
      var point = points[end];

      if (!isNaN(point.x) && !isNaN(point.y)) {
        break;
      }
    }

    return end;
  }

  function _getEdge(a, b, prop, fn) {
    if (a && b) {
      return fn(a[prop], b[prop]);
    }

    return a ? a[prop] : b ? b[prop] : 0;
  }

  function _createBoundaryLine(boundary, line) {
    var points = [];
    var _loop = false;

    if (isArray(boundary)) {
      _loop = true;
      points = boundary;
    } else {
      points = _pointsFromSegments(boundary, line);
    }

    return points.length ? new LineElement({
      points: points,
      options: {
        tension: 0
      },
      _loop: _loop,
      _fullLoop: _loop
    }) : null;
  }

  function _shouldApplyFill(source) {
    return source && source.fill !== false;
  }

  function _resolveTarget(sources, index, propagate) {
    var source = sources[index];
    var fill = source.fill;
    var visited = [index];
    var target;

    if (!propagate) {
      return fill;
    }

    while (fill !== false && visited.indexOf(fill) === -1) {
      if (!isNumberFinite(fill)) {
        return fill;
      }

      target = sources[fill];

      if (!target) {
        return false;
      }

      if (target.visible) {
        return fill;
      }

      visited.push(fill);
      fill = target.fill;
    }

    return false;
  }

  function _decodeFill(line, index, count) {
    var fill = parseFillOption(line);

    if (isObject(fill)) {
      return isNaN(fill.value) ? false : fill;
    }

    var target = parseFloat(fill);

    if (isNumberFinite(target) && Math.floor(target) === target) {
      return decodeTargetIndex(fill[0], index, target, count);
    }

    return ['origin', 'start', 'end', 'stack', 'shape'].indexOf(fill) >= 0 && fill;
  }

  function decodeTargetIndex(firstCh, index, target, count) {
    if (firstCh === '-' || firstCh === '+') {
      target = index + target;
    }

    if (target === index || target < 0 || target >= count) {
      return false;
    }

    return target;
  }

  function _getTargetPixel(fill, scale) {
    var pixel = null;

    if (fill === 'start') {
      pixel = scale.bottom;
    } else if (fill === 'end') {
      pixel = scale.top;
    } else if (isObject(fill)) {
      pixel = scale.getPixelForValue(fill.value);
    } else if (scale.getBasePixel) {
      pixel = scale.getBasePixel();
    }

    return pixel;
  }

  function _getTargetValue(fill, scale, startValue) {
    var value;

    if (fill === 'start') {
      value = startValue;
    } else if (fill === 'end') {
      value = scale.options.reverse ? scale.min : scale.max;
    } else if (isObject(fill)) {
      value = fill.value;
    } else {
      value = scale.getBaseValue();
    }

    return value;
  }

  function parseFillOption(line) {
    var options = line.options;
    var fillOption = options.fill;
    var fill = valueOrDefault(fillOption && fillOption.target, fillOption);

    if (fill === undefined) {
      fill = !!options.backgroundColor;
    }

    if (fill === false || fill === null) {
      return false;
    }

    if (fill === true) {
      return 'origin';
    }

    return fill;
  }

  function _buildStackLine(source) {
    var scale = source.scale,
        index = source.index,
        line = source.line;
    var points = [];
    var segments = line.segments;
    var sourcePoints = line.points;
    var linesBelow = getLinesBelow(scale, index);
    linesBelow.push(_createBoundaryLine({
      x: null,
      y: scale.bottom
    }, line));

    for (var i = 0; i < segments.length; i++) {
      var segment = segments[i];

      for (var j = segment.start; j <= segment.end; j++) {
        addPointsBelow(points, sourcePoints[j], linesBelow);
      }
    }

    return new LineElement({
      points: points,
      options: {}
    });
  }

  function getLinesBelow(scale, index) {
    var below = [];
    var metas = scale.getMatchingVisibleMetas('line');

    for (var i = 0; i < metas.length; i++) {
      var meta = metas[i];

      if (meta.index === index) {
        break;
      }

      if (!meta.hidden) {
        below.unshift(meta.dataset);
      }
    }

    return below;
  }

  function addPointsBelow(points, sourcePoint, linesBelow) {
    var postponed = [];

    for (var j = 0; j < linesBelow.length; j++) {
      var line = linesBelow[j];

      var _findPoint = findPoint(line, sourcePoint, 'x'),
          first = _findPoint.first,
          last = _findPoint.last,
          point = _findPoint.point;

      if (!point || first && last) {
        continue;
      }

      if (first) {
        postponed.unshift(point);
      } else {
        points.push(point);

        if (!last) {
          break;
        }
      }
    }

    points.push.apply(points, postponed);
  }

  function findPoint(line, sourcePoint, property) {
    var point = line.interpolate(sourcePoint, property);

    if (!point) {
      return {};
    }

    var pointValue = point[property];
    var segments = line.segments;
    var linePoints = line.points;
    var first = false;
    var last = false;

    for (var i = 0; i < segments.length; i++) {
      var segment = segments[i];
      var firstValue = linePoints[segment.start][property];
      var lastValue = linePoints[segment.end][property];

      if (_isBetween(pointValue, firstValue, lastValue)) {
        first = pointValue === firstValue;
        last = pointValue === lastValue;
        break;
      }
    }

    return {
      first: first,
      last: last,
      point: point
    };
  }

  var simpleArc = /*#__PURE__*/function () {
    function simpleArc(opts) {
      _classCallCheck(this, simpleArc);

      this.x = opts.x;
      this.y = opts.y;
      this.radius = opts.radius;
    }

    _createClass(simpleArc, [{
      key: "pathSegment",
      value: function pathSegment(ctx, bounds, opts) {
        var x = this.x,
            y = this.y,
            radius = this.radius;
        bounds = bounds || {
          start: 0,
          end: TAU
        };
        ctx.arc(x, y, radius, bounds.end, bounds.start, true);
        return !opts.bounds;
      }
    }, {
      key: "interpolate",
      value: function interpolate(point) {
        var x = this.x,
            y = this.y,
            radius = this.radius;
        var angle = point.angle;
        return {
          x: x + Math.cos(angle) * radius,
          y: y + Math.sin(angle) * radius,
          angle: angle
        };
      }
    }]);

    return simpleArc;
  }();

  function _getTarget(source) {
    var chart = source.chart,
        fill = source.fill,
        line = source.line;

    if (isNumberFinite(fill)) {
      return getLineByIndex(chart, fill);
    }

    if (fill === 'stack') {
      return _buildStackLine(source);
    }

    if (fill === 'shape') {
      return true;
    }

    var boundary = computeBoundary(source);

    if (boundary instanceof simpleArc) {
      return boundary;
    }

    return _createBoundaryLine(boundary, line);
  }

  function getLineByIndex(chart, index) {
    var meta = chart.getDatasetMeta(index);
    var visible = meta && chart.isDatasetVisible(index);
    return visible ? meta.dataset : null;
  }

  function computeBoundary(source) {
    var scale = source.scale || {};

    if (scale.getPointPositionForValue) {
      return computeCircularBoundary(source);
    }

    return computeLinearBoundary(source);
  }

  function computeLinearBoundary(source) {
    var _source$scale = source.scale,
        scale = _source$scale === void 0 ? {} : _source$scale,
        fill = source.fill;

    var pixel = _getTargetPixel(fill, scale);

    if (isNumberFinite(pixel)) {
      var horizontal = scale.isHorizontal();
      return {
        x: horizontal ? pixel : null,
        y: horizontal ? null : pixel
      };
    }

    return null;
  }

  function computeCircularBoundary(source) {
    var scale = source.scale,
        fill = source.fill;
    var options = scale.options;
    var length = scale.getLabels().length;
    var start = options.reverse ? scale.max : scale.min;

    var value = _getTargetValue(fill, scale, start);

    var target = [];

    if (options.grid.circular) {
      var center = scale.getPointPositionForValue(0, start);
      return new simpleArc({
        x: center.x,
        y: center.y,
        radius: scale.getDistanceFromCenterForValue(value)
      });
    }

    for (var i = 0; i < length; ++i) {
      target.push(scale.getPointPositionForValue(i, value));
    }

    return target;
  }

  function _drawfill(ctx, source, area) {
    var target = _getTarget(source);

    var line = source.line,
        scale = source.scale,
        axis = source.axis;
    var lineOpts = line.options;
    var fillOption = lineOpts.fill;
    var color = lineOpts.backgroundColor;

    var _ref9 = fillOption || {},
        _ref9$above = _ref9.above,
        above = _ref9$above === void 0 ? color : _ref9$above,
        _ref9$below = _ref9.below,
        below = _ref9$below === void 0 ? color : _ref9$below;

    if (target && line.points.length) {
      clipArea(ctx, area);
      doFill(ctx, {
        line: line,
        target: target,
        above: above,
        below: below,
        area: area,
        scale: scale,
        axis: axis
      });
      unclipArea(ctx);
    }
  }

  function doFill(ctx, cfg) {
    var line = cfg.line,
        target = cfg.target,
        above = cfg.above,
        below = cfg.below,
        area = cfg.area,
        scale = cfg.scale;
    var property = line._loop ? 'angle' : cfg.axis;
    ctx.save();

    if (property === 'x' && below !== above) {
      clipVertical(ctx, target, area.top);
      fill(ctx, {
        line: line,
        target: target,
        color: above,
        scale: scale,
        property: property
      });
      ctx.restore();
      ctx.save();
      clipVertical(ctx, target, area.bottom);
    }

    fill(ctx, {
      line: line,
      target: target,
      color: below,
      scale: scale,
      property: property
    });
    ctx.restore();
  }

  function clipVertical(ctx, target, clipY) {
    var segments = target.segments,
        points = target.points;
    var first = true;
    var lineLoop = false;
    ctx.beginPath();

    var _iterator21 = _createForOfIteratorHelper(segments),
        _step21;

    try {
      for (_iterator21.s(); !(_step21 = _iterator21.n()).done;) {
        var segment = _step21.value;
        var start = segment.start,
            end = segment.end;
        var firstPoint = points[start];

        var lastPoint = points[_findSegmentEnd(start, end, points)];

        if (first) {
          ctx.moveTo(firstPoint.x, firstPoint.y);
          first = false;
        } else {
          ctx.lineTo(firstPoint.x, clipY);
          ctx.lineTo(firstPoint.x, firstPoint.y);
        }

        lineLoop = !!target.pathSegment(ctx, segment, {
          move: lineLoop
        });

        if (lineLoop) {
          ctx.closePath();
        } else {
          ctx.lineTo(lastPoint.x, clipY);
        }
      }
    } catch (err) {
      _iterator21.e(err);
    } finally {
      _iterator21.f();
    }

    ctx.lineTo(target.first().x, clipY);
    ctx.closePath();
    ctx.clip();
  }

  function fill(ctx, cfg) {
    var line = cfg.line,
        target = cfg.target,
        property = cfg.property,
        color = cfg.color,
        scale = cfg.scale;

    var segments = _segments(line, target, property);

    var _iterator22 = _createForOfIteratorHelper(segments),
        _step22;

    try {
      for (_iterator22.s(); !(_step22 = _iterator22.n()).done;) {
        var _step22$value = _step22.value,
            src = _step22$value.source,
            tgt = _step22$value.target,
            start = _step22$value.start,
            end = _step22$value.end;
        var _src$style = src.style;
        _src$style = _src$style === void 0 ? {} : _src$style;
        var _src$style$background = _src$style.backgroundColor,
            backgroundColor = _src$style$background === void 0 ? color : _src$style$background;
        var notShape = target !== true;
        ctx.save();
        ctx.fillStyle = backgroundColor;
        clipBounds(ctx, scale, notShape && _getBounds(property, start, end));
        ctx.beginPath();
        var lineLoop = !!line.pathSegment(ctx, src);
        var loop = void 0;

        if (notShape) {
          if (lineLoop) {
            ctx.closePath();
          } else {
            interpolatedLineTo(ctx, target, end, property);
          }

          var targetLoop = !!target.pathSegment(ctx, tgt, {
            move: lineLoop,
            reverse: true
          });
          loop = lineLoop && targetLoop;

          if (!loop) {
            interpolatedLineTo(ctx, target, start, property);
          }
        }

        ctx.closePath();
        ctx.fill(loop ? 'evenodd' : 'nonzero');
        ctx.restore();
      }
    } catch (err) {
      _iterator22.e(err);
    } finally {
      _iterator22.f();
    }
  }

  function clipBounds(ctx, scale, bounds) {
    var _scale$chart$chartAre = scale.chart.chartArea,
        top = _scale$chart$chartAre.top,
        bottom = _scale$chart$chartAre.bottom;

    var _ref10 = bounds || {},
        property = _ref10.property,
        start = _ref10.start,
        end = _ref10.end;

    if (property === 'x') {
      ctx.beginPath();
      ctx.rect(start, top, end - start, bottom - top);
      ctx.clip();
    }
  }

  function interpolatedLineTo(ctx, target, point, property) {
    var interpolatedPoint = target.interpolate(point, property);

    if (interpolatedPoint) {
      ctx.lineTo(interpolatedPoint.x, interpolatedPoint.y);
    }
  }

  var index = {
    id: 'filler',
    afterDatasetsUpdate: function afterDatasetsUpdate(chart, _args, options) {
      var count = (chart.data.datasets || []).length;
      var sources = [];
      var meta, i, line, source;

      for (i = 0; i < count; ++i) {
        meta = chart.getDatasetMeta(i);
        line = meta.dataset;
        source = null;

        if (line && line.options && line instanceof LineElement) {
          source = {
            visible: chart.isDatasetVisible(i),
            index: i,
            fill: _decodeFill(line, i, count),
            chart: chart,
            axis: meta.controller.options.indexAxis,
            scale: meta.vScale,
            line: line
          };
        }

        meta.$filler = source;
        sources.push(source);
      }

      for (i = 0; i < count; ++i) {
        source = sources[i];

        if (!source || source.fill === false) {
          continue;
        }

        source.fill = _resolveTarget(sources, i, options.propagate);
      }
    },
    beforeDraw: function beforeDraw(chart, _args, options) {
      var draw = options.drawTime === 'beforeDraw';
      var metasets = chart.getSortedVisibleDatasetMetas();
      var area = chart.chartArea;

      for (var i = metasets.length - 1; i >= 0; --i) {
        var source = metasets[i].$filler;

        if (!source) {
          continue;
        }

        source.line.updateControlPoints(area, source.axis);

        if (draw && source.fill) {
          _drawfill(chart.ctx, source, area);
        }
      }
    },
    beforeDatasetsDraw: function beforeDatasetsDraw(chart, _args, options) {
      if (options.drawTime !== 'beforeDatasetsDraw') {
        return;
      }

      var metasets = chart.getSortedVisibleDatasetMetas();

      for (var i = metasets.length - 1; i >= 0; --i) {
        var source = metasets[i].$filler;

        if (_shouldApplyFill(source)) {
          _drawfill(chart.ctx, source, chart.chartArea);
        }
      }
    },
    beforeDatasetDraw: function beforeDatasetDraw(chart, args, options) {
      var source = args.meta.$filler;

      if (!_shouldApplyFill(source) || options.drawTime !== 'beforeDatasetDraw') {
        return;
      }

      _drawfill(chart.ctx, source, chart.chartArea);
    },
    defaults: {
      propagate: true,
      drawTime: 'beforeDatasetDraw'
    }
  };

  var getBoxSize = function getBoxSize(labelOpts, fontSize) {
    var _labelOpts$boxHeight = labelOpts.boxHeight,
        boxHeight = _labelOpts$boxHeight === void 0 ? fontSize : _labelOpts$boxHeight,
        _labelOpts$boxWidth = labelOpts.boxWidth,
        boxWidth = _labelOpts$boxWidth === void 0 ? fontSize : _labelOpts$boxWidth;

    if (labelOpts.usePointStyle) {
      boxHeight = Math.min(boxHeight, fontSize);
      boxWidth = labelOpts.pointStyleWidth || Math.min(boxWidth, fontSize);
    }

    return {
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      itemHeight: Math.max(fontSize, boxHeight)
    };
  };

  var itemsEqual = function itemsEqual(a, b) {
    return a !== null && b !== null && a.datasetIndex === b.datasetIndex && a.index === b.index;
  };

  var Legend = /*#__PURE__*/function (_Element6) {
    _inherits(Legend, _Element6);

    var _super16 = _createSuper(Legend);

    function Legend(config) {
      var _this27;

      _classCallCheck(this, Legend);

      _this27 = _super16.call(this);
      _this27._added = false;
      _this27.legendHitBoxes = [];
      _this27._hoveredItem = null;
      _this27.doughnutMode = false;
      _this27.chart = config.chart;
      _this27.options = config.options;
      _this27.ctx = config.ctx;
      _this27.legendItems = undefined;
      _this27.columnSizes = undefined;
      _this27.lineWidths = undefined;
      _this27.maxHeight = undefined;
      _this27.maxWidth = undefined;
      _this27.top = undefined;
      _this27.bottom = undefined;
      _this27.left = undefined;
      _this27.right = undefined;
      _this27.height = undefined;
      _this27.width = undefined;
      _this27._margins = undefined;
      _this27.position = undefined;
      _this27.weight = undefined;
      _this27.fullSize = undefined;
      return _this27;
    }

    _createClass(Legend, [{
      key: "update",
      value: function update(maxWidth, maxHeight, margins) {
        this.maxWidth = maxWidth;
        this.maxHeight = maxHeight;
        this._margins = margins;
        this.setDimensions();
        this.buildLabels();
        this.fit();
      }
    }, {
      key: "setDimensions",
      value: function setDimensions() {
        if (this.isHorizontal()) {
          this.width = this.maxWidth;
          this.left = this._margins.left;
          this.right = this.width;
        } else {
          this.height = this.maxHeight;
          this.top = this._margins.top;
          this.bottom = this.height;
        }
      }
    }, {
      key: "buildLabels",
      value: function buildLabels() {
        var _this28 = this;

        var labelOpts = this.options.labels || {};
        var legendItems = callback(labelOpts.generateLabels, [this.chart], this) || [];

        if (labelOpts.filter) {
          legendItems = legendItems.filter(function (item) {
            return labelOpts.filter(item, _this28.chart.data);
          });
        }

        if (labelOpts.sort) {
          legendItems = legendItems.sort(function (a, b) {
            return labelOpts.sort(a, b, _this28.chart.data);
          });
        }

        if (this.options.reverse) {
          legendItems.reverse();
        }

        this.legendItems = legendItems;
      }
    }, {
      key: "fit",
      value: function fit() {
        var options = this.options,
            ctx = this.ctx;

        if (!options.display) {
          this.width = this.height = 0;
          return;
        }

        var labelOpts = options.labels;
        var labelFont = toFont(labelOpts.font);
        var fontSize = labelFont.size;

        var titleHeight = this._computeTitleHeight();

        var _getBoxSize = getBoxSize(labelOpts, fontSize),
            boxWidth = _getBoxSize.boxWidth,
            itemHeight = _getBoxSize.itemHeight;

        var width, height;
        ctx.font = labelFont.string;

        if (this.isHorizontal()) {
          width = this.maxWidth;
          height = this._fitRows(titleHeight, fontSize, boxWidth, itemHeight) + 10;
        } else {
          height = this.maxHeight;
          width = this._fitCols(titleHeight, fontSize, boxWidth, itemHeight) + 10;
        }

        this.width = Math.min(width, options.maxWidth || this.maxWidth);
        this.height = Math.min(height, options.maxHeight || this.maxHeight);
      }
    }, {
      key: "_fitRows",
      value: function _fitRows(titleHeight, fontSize, boxWidth, itemHeight) {
        var ctx = this.ctx,
            maxWidth = this.maxWidth,
            padding = this.options.labels.padding;
        var hitboxes = this.legendHitBoxes = [];
        var lineWidths = this.lineWidths = [0];
        var lineHeight = itemHeight + padding;
        var totalHeight = titleHeight;
        ctx.textAlign = 'left';
        ctx.textBaseline = 'middle';
        var row = -1;
        var top = -lineHeight;
        this.legendItems.forEach(function (legendItem, i) {
          var itemWidth = boxWidth + fontSize / 2 + ctx.measureText(legendItem.text).width;

          if (i === 0 || lineWidths[lineWidths.length - 1] + itemWidth + 2 * padding > maxWidth) {
            totalHeight += lineHeight;
            lineWidths[lineWidths.length - (i > 0 ? 0 : 1)] = 0;
            top += lineHeight;
            row++;
          }

          hitboxes[i] = {
            left: 0,
            top: top,
            row: row,
            width: itemWidth,
            height: itemHeight
          };
          lineWidths[lineWidths.length - 1] += itemWidth + padding;
        });
        return totalHeight;
      }
    }, {
      key: "_fitCols",
      value: function _fitCols(titleHeight, fontSize, boxWidth, itemHeight) {
        var ctx = this.ctx,
            maxHeight = this.maxHeight,
            padding = this.options.labels.padding;
        var hitboxes = this.legendHitBoxes = [];
        var columnSizes = this.columnSizes = [];
        var heightLimit = maxHeight - titleHeight;
        var totalWidth = padding;
        var currentColWidth = 0;
        var currentColHeight = 0;
        var left = 0;
        var col = 0;
        this.legendItems.forEach(function (legendItem, i) {
          var itemWidth = boxWidth + fontSize / 2 + ctx.measureText(legendItem.text).width;

          if (i > 0 && currentColHeight + itemHeight + 2 * padding > heightLimit) {
            totalWidth += currentColWidth + padding;
            columnSizes.push({
              width: currentColWidth,
              height: currentColHeight
            });
            left += currentColWidth + padding;
            col++;
            currentColWidth = currentColHeight = 0;
          }

          hitboxes[i] = {
            left: left,
            top: currentColHeight,
            col: col,
            width: itemWidth,
            height: itemHeight
          };
          currentColWidth = Math.max(currentColWidth, itemWidth);
          currentColHeight += itemHeight + padding;
        });
        totalWidth += currentColWidth;
        columnSizes.push({
          width: currentColWidth,
          height: currentColHeight
        });
        return totalWidth;
      }
    }, {
      key: "adjustHitBoxes",
      value: function adjustHitBoxes() {
        if (!this.options.display) {
          return;
        }

        var titleHeight = this._computeTitleHeight();

        var hitboxes = this.legendHitBoxes,
            _this$options14 = this.options,
            align = _this$options14.align,
            padding = _this$options14.labels.padding,
            rtl = _this$options14.rtl;
        var rtlHelper = getRtlAdapter(rtl, this.left, this.width);

        if (this.isHorizontal()) {
          var row = 0;

          var left = _alignStartEnd(align, this.left + padding, this.right - this.lineWidths[row]);

          var _iterator23 = _createForOfIteratorHelper(hitboxes),
              _step23;

          try {
            for (_iterator23.s(); !(_step23 = _iterator23.n()).done;) {
              var hitbox = _step23.value;

              if (row !== hitbox.row) {
                row = hitbox.row;
                left = _alignStartEnd(align, this.left + padding, this.right - this.lineWidths[row]);
              }

              hitbox.top += this.top + titleHeight + padding;
              hitbox.left = rtlHelper.leftForLtr(rtlHelper.x(left), hitbox.width);
              left += hitbox.width + padding;
            }
          } catch (err) {
            _iterator23.e(err);
          } finally {
            _iterator23.f();
          }
        } else {
          var col = 0;

          var top = _alignStartEnd(align, this.top + titleHeight + padding, this.bottom - this.columnSizes[col].height);

          var _iterator24 = _createForOfIteratorHelper(hitboxes),
              _step24;

          try {
            for (_iterator24.s(); !(_step24 = _iterator24.n()).done;) {
              var _hitbox = _step24.value;

              if (_hitbox.col !== col) {
                col = _hitbox.col;
                top = _alignStartEnd(align, this.top + titleHeight + padding, this.bottom - this.columnSizes[col].height);
              }

              _hitbox.top = top;
              _hitbox.left += this.left + padding;
              _hitbox.left = rtlHelper.leftForLtr(rtlHelper.x(_hitbox.left), _hitbox.width);
              top += _hitbox.height + padding;
            }
          } catch (err) {
            _iterator24.e(err);
          } finally {
            _iterator24.f();
          }
        }
      }
    }, {
      key: "isHorizontal",
      value: function isHorizontal() {
        return this.options.position === 'top' || this.options.position === 'bottom';
      }
    }, {
      key: "draw",
      value: function draw() {
        if (this.options.display) {
          var ctx = this.ctx;
          clipArea(ctx, this);

          this._draw();

          unclipArea(ctx);
        }
      }
    }, {
      key: "_draw",
      value: function _draw() {
        var _this29 = this;

        var opts = this.options,
            columnSizes = this.columnSizes,
            lineWidths = this.lineWidths,
            ctx = this.ctx;
        var align = opts.align,
            labelOpts = opts.labels;
        var defaultColor = defaults.color;
        var rtlHelper = getRtlAdapter(opts.rtl, this.left, this.width);
        var labelFont = toFont(labelOpts.font);
        var fontColor = labelOpts.color,
            padding = labelOpts.padding;
        var fontSize = labelFont.size;
        var halfFontSize = fontSize / 2;
        var cursor;
        this.drawTitle();
        ctx.textAlign = rtlHelper.textAlign('left');
        ctx.textBaseline = 'middle';
        ctx.lineWidth = 0.5;
        ctx.font = labelFont.string;

        var _getBoxSize2 = getBoxSize(labelOpts, fontSize),
            boxWidth = _getBoxSize2.boxWidth,
            boxHeight = _getBoxSize2.boxHeight,
            itemHeight = _getBoxSize2.itemHeight;

        var drawLegendBox = function drawLegendBox(x, y, legendItem) {
          if (isNaN(boxWidth) || boxWidth <= 0 || isNaN(boxHeight) || boxHeight < 0) {
            return;
          }

          ctx.save();
          var lineWidth = valueOrDefault(legendItem.lineWidth, 1);
          ctx.fillStyle = valueOrDefault(legendItem.fillStyle, defaultColor);
          ctx.lineCap = valueOrDefault(legendItem.lineCap, 'butt');
          ctx.lineDashOffset = valueOrDefault(legendItem.lineDashOffset, 0);
          ctx.lineJoin = valueOrDefault(legendItem.lineJoin, 'miter');
          ctx.lineWidth = lineWidth;
          ctx.strokeStyle = valueOrDefault(legendItem.strokeStyle, defaultColor);
          ctx.setLineDash(valueOrDefault(legendItem.lineDash, []));

          if (labelOpts.usePointStyle) {
            var drawOptions = {
              radius: boxHeight * Math.SQRT2 / 2,
              pointStyle: legendItem.pointStyle,
              rotation: legendItem.rotation,
              borderWidth: lineWidth
            };
            var centerX = rtlHelper.xPlus(x, boxWidth / 2);
            var centerY = y + halfFontSize;
            drawPointLegend(ctx, drawOptions, centerX, centerY, labelOpts.pointStyleWidth && boxWidth);
          } else {
            var yBoxTop = y + Math.max((fontSize - boxHeight) / 2, 0);
            var xBoxLeft = rtlHelper.leftForLtr(x, boxWidth);
            var borderRadius = toTRBLCorners(legendItem.borderRadius);
            ctx.beginPath();

            if (Object.values(borderRadius).some(function (v) {
              return v !== 0;
            })) {
              addRoundedRectPath(ctx, {
                x: xBoxLeft,
                y: yBoxTop,
                w: boxWidth,
                h: boxHeight,
                radius: borderRadius
              });
            } else {
              ctx.rect(xBoxLeft, yBoxTop, boxWidth, boxHeight);
            }

            ctx.fill();

            if (lineWidth !== 0) {
              ctx.stroke();
            }
          }

          ctx.restore();
        };

        var fillText = function fillText(x, y, legendItem) {
          renderText(ctx, legendItem.text, x, y + itemHeight / 2, labelFont, {
            strikethrough: legendItem.hidden,
            textAlign: rtlHelper.textAlign(legendItem.textAlign)
          });
        };

        var isHorizontal = this.isHorizontal();

        var titleHeight = this._computeTitleHeight();

        if (isHorizontal) {
          cursor = {
            x: _alignStartEnd(align, this.left + padding, this.right - lineWidths[0]),
            y: this.top + padding + titleHeight,
            line: 0
          };
        } else {
          cursor = {
            x: this.left + padding,
            y: _alignStartEnd(align, this.top + titleHeight + padding, this.bottom - columnSizes[0].height),
            line: 0
          };
        }

        overrideTextDirection(this.ctx, opts.textDirection);
        var lineHeight = itemHeight + padding;
        this.legendItems.forEach(function (legendItem, i) {
          ctx.strokeStyle = legendItem.fontColor || fontColor;
          ctx.fillStyle = legendItem.fontColor || fontColor;
          var textWidth = ctx.measureText(legendItem.text).width;
          var textAlign = rtlHelper.textAlign(legendItem.textAlign || (legendItem.textAlign = labelOpts.textAlign));
          var width = boxWidth + halfFontSize + textWidth;
          var x = cursor.x;
          var y = cursor.y;
          rtlHelper.setWidth(_this29.width);

          if (isHorizontal) {
            if (i > 0 && x + width + padding > _this29.right) {
              y = cursor.y += lineHeight;
              cursor.line++;
              x = cursor.x = _alignStartEnd(align, _this29.left + padding, _this29.right - lineWidths[cursor.line]);
            }
          } else if (i > 0 && y + lineHeight > _this29.bottom) {
            x = cursor.x = x + columnSizes[cursor.line].width + padding;
            cursor.line++;
            y = cursor.y = _alignStartEnd(align, _this29.top + titleHeight + padding, _this29.bottom - columnSizes[cursor.line].height);
          }

          var realX = rtlHelper.x(x);
          drawLegendBox(realX, y, legendItem);
          x = _textX(textAlign, x + boxWidth + halfFontSize, isHorizontal ? x + width : _this29.right, opts.rtl);
          fillText(rtlHelper.x(x), y, legendItem);

          if (isHorizontal) {
            cursor.x += width + padding;
          } else {
            cursor.y += lineHeight;
          }
        });
        restoreTextDirection(this.ctx, opts.textDirection);
      }
    }, {
      key: "drawTitle",
      value: function drawTitle() {
        var opts = this.options;
        var titleOpts = opts.title;
        var titleFont = toFont(titleOpts.font);
        var titlePadding = toPadding(titleOpts.padding);

        if (!titleOpts.display) {
          return;
        }

        var rtlHelper = getRtlAdapter(opts.rtl, this.left, this.width);
        var ctx = this.ctx;
        var position = titleOpts.position;
        var halfFontSize = titleFont.size / 2;
        var topPaddingPlusHalfFontSize = titlePadding.top + halfFontSize;
        var y;
        var left = this.left;
        var maxWidth = this.width;

        if (this.isHorizontal()) {
          maxWidth = Math.max.apply(Math, _toConsumableArray(this.lineWidths));
          y = this.top + topPaddingPlusHalfFontSize;
          left = _alignStartEnd(opts.align, left, this.right - maxWidth);
        } else {
          var maxHeight = this.columnSizes.reduce(function (acc, size) {
            return Math.max(acc, size.height);
          }, 0);
          y = topPaddingPlusHalfFontSize + _alignStartEnd(opts.align, this.top, this.bottom - maxHeight - opts.labels.padding - this._computeTitleHeight());
        }

        var x = _alignStartEnd(position, left, left + maxWidth);

        ctx.textAlign = rtlHelper.textAlign(_toLeftRightCenter(position));
        ctx.textBaseline = 'middle';
        ctx.strokeStyle = titleOpts.color;
        ctx.fillStyle = titleOpts.color;
        ctx.font = titleFont.string;
        renderText(ctx, titleOpts.text, x, y, titleFont);
      }
    }, {
      key: "_computeTitleHeight",
      value: function _computeTitleHeight() {
        var titleOpts = this.options.title;
        var titleFont = toFont(titleOpts.font);
        var titlePadding = toPadding(titleOpts.padding);
        return titleOpts.display ? titleFont.lineHeight + titlePadding.height : 0;
      }
    }, {
      key: "_getLegendItemAt",
      value: function _getLegendItemAt(x, y) {
        var i, hitBox, lh;

        if (_isBetween(x, this.left, this.right) && _isBetween(y, this.top, this.bottom)) {
          lh = this.legendHitBoxes;

          for (i = 0; i < lh.length; ++i) {
            hitBox = lh[i];

            if (_isBetween(x, hitBox.left, hitBox.left + hitBox.width) && _isBetween(y, hitBox.top, hitBox.top + hitBox.height)) {
              return this.legendItems[i];
            }
          }
        }

        return null;
      }
    }, {
      key: "handleEvent",
      value: function handleEvent(e) {
        var opts = this.options;

        if (!isListened(e.type, opts)) {
          return;
        }

        var hoveredItem = this._getLegendItemAt(e.x, e.y);

        if (e.type === 'mousemove' || e.type === 'mouseout') {
          var previous = this._hoveredItem;
          var sameItem = itemsEqual(previous, hoveredItem);

          if (previous && !sameItem) {
            callback(opts.onLeave, [e, previous, this], this);
          }

          this._hoveredItem = hoveredItem;

          if (hoveredItem && !sameItem) {
            callback(opts.onHover, [e, hoveredItem, this], this);
          }
        } else if (hoveredItem) {
          callback(opts.onClick, [e, hoveredItem, this], this);
        }
      }
    }]);

    return Legend;
  }(Element);

  function isListened(type, opts) {
    if ((type === 'mousemove' || type === 'mouseout') && (opts.onHover || opts.onLeave)) {
      return true;
    }

    if (opts.onClick && (type === 'click' || type === 'mouseup')) {
      return true;
    }

    return false;
  }

  var plugin_legend = {
    id: 'legend',
    _element: Legend,
    start: function start(chart, _args, options) {
      var legend = chart.legend = new Legend({
        ctx: chart.ctx,
        options: options,
        chart: chart
      });
      layouts.configure(chart, legend, options);
      layouts.addBox(chart, legend);
    },
    stop: function stop(chart) {
      layouts.removeBox(chart, chart.legend);
      delete chart.legend;
    },
    beforeUpdate: function beforeUpdate(chart, _args, options) {
      var legend = chart.legend;
      layouts.configure(chart, legend, options);
      legend.options = options;
    },
    afterUpdate: function afterUpdate(chart) {
      var legend = chart.legend;
      legend.buildLabels();
      legend.adjustHitBoxes();
    },
    afterEvent: function afterEvent(chart, args) {
      if (!args.replay) {
        chart.legend.handleEvent(args.event);
      }
    },
    defaults: {
      display: true,
      position: 'top',
      align: 'center',
      fullSize: true,
      reverse: false,
      weight: 1000,
      onClick: function onClick(e, legendItem, legend) {
        var index = legendItem.datasetIndex;
        var ci = legend.chart;

        if (ci.isDatasetVisible(index)) {
          ci.hide(index);
          legendItem.hidden = true;
        } else {
          ci.show(index);
          legendItem.hidden = false;
        }
      },
      onHover: null,
      onLeave: null,
      labels: {
        color: function color(ctx) {
          return ctx.chart.options.color;
        },
        boxWidth: 40,
        padding: 10,
        generateLabels: function generateLabels(chart) {
          var datasets = chart.data.datasets;
          var _chart$legend$options = chart.legend.options.labels,
              usePointStyle = _chart$legend$options.usePointStyle,
              pointStyle = _chart$legend$options.pointStyle,
              textAlign = _chart$legend$options.textAlign,
              color = _chart$legend$options.color;
          return chart._getSortedDatasetMetas().map(function (meta) {
            var style = meta.controller.getStyle(usePointStyle ? 0 : undefined);
            var borderWidth = toPadding(style.borderWidth);
            return {
              text: datasets[meta.index].label,
              fillStyle: style.backgroundColor,
              fontColor: color,
              hidden: !meta.visible,
              lineCap: style.borderCapStyle,
              lineDash: style.borderDash,
              lineDashOffset: style.borderDashOffset,
              lineJoin: style.borderJoinStyle,
              lineWidth: (borderWidth.width + borderWidth.height) / 4,
              strokeStyle: style.borderColor,
              pointStyle: pointStyle || style.pointStyle,
              rotation: style.rotation,
              textAlign: textAlign || style.textAlign,
              borderRadius: 0,
              datasetIndex: meta.index
            };
          }, this);
        }
      },
      title: {
        color: function color(ctx) {
          return ctx.chart.options.color;
        },
        display: false,
        position: 'center',
        text: ''
      }
    },
    descriptors: {
      _scriptable: function _scriptable(name) {
        return !name.startsWith('on');
      },
      labels: {
        _scriptable: function _scriptable(name) {
          return !['generateLabels', 'filter', 'sort'].includes(name);
        }
      }
    }
  };

  var Title = /*#__PURE__*/function (_Element7) {
    _inherits(Title, _Element7);

    var _super17 = _createSuper(Title);

    function Title(config) {
      var _this30;

      _classCallCheck(this, Title);

      _this30 = _super17.call(this);
      _this30.chart = config.chart;
      _this30.options = config.options;
      _this30.ctx = config.ctx;
      _this30._padding = undefined;
      _this30.top = undefined;
      _this30.bottom = undefined;
      _this30.left = undefined;
      _this30.right = undefined;
      _this30.width = undefined;
      _this30.height = undefined;
      _this30.position = undefined;
      _this30.weight = undefined;
      _this30.fullSize = undefined;
      return _this30;
    }

    _createClass(Title, [{
      key: "update",
      value: function update(maxWidth, maxHeight) {
        var opts = this.options;
        this.left = 0;
        this.top = 0;

        if (!opts.display) {
          this.width = this.height = this.right = this.bottom = 0;
          return;
        }

        this.width = this.right = maxWidth;
        this.height = this.bottom = maxHeight;
        var lineCount = isArray(opts.text) ? opts.text.length : 1;
        this._padding = toPadding(opts.padding);

        var textSize = lineCount * toFont(opts.font).lineHeight + this._padding.height;

        if (this.isHorizontal()) {
          this.height = textSize;
        } else {
          this.width = textSize;
        }
      }
    }, {
      key: "isHorizontal",
      value: function isHorizontal() {
        var pos = this.options.position;
        return pos === 'top' || pos === 'bottom';
      }
    }, {
      key: "_drawArgs",
      value: function _drawArgs(offset) {
        var top = this.top,
            left = this.left,
            bottom = this.bottom,
            right = this.right,
            options = this.options;
        var align = options.align;
        var rotation = 0;
        var maxWidth, titleX, titleY;

        if (this.isHorizontal()) {
          titleX = _alignStartEnd(align, left, right);
          titleY = top + offset;
          maxWidth = right - left;
        } else {
          if (options.position === 'left') {
            titleX = left + offset;
            titleY = _alignStartEnd(align, bottom, top);
            rotation = PI * -0.5;
          } else {
            titleX = right - offset;
            titleY = _alignStartEnd(align, top, bottom);
            rotation = PI * 0.5;
          }

          maxWidth = bottom - top;
        }

        return {
          titleX: titleX,
          titleY: titleY,
          maxWidth: maxWidth,
          rotation: rotation
        };
      }
    }, {
      key: "draw",
      value: function draw() {
        var ctx = this.ctx;
        var opts = this.options;

        if (!opts.display) {
          return;
        }

        var fontOpts = toFont(opts.font);
        var lineHeight = fontOpts.lineHeight;
        var offset = lineHeight / 2 + this._padding.top;

        var _this$_drawArgs = this._drawArgs(offset),
            titleX = _this$_drawArgs.titleX,
            titleY = _this$_drawArgs.titleY,
            maxWidth = _this$_drawArgs.maxWidth,
            rotation = _this$_drawArgs.rotation;

        renderText(ctx, opts.text, 0, 0, fontOpts, {
          color: opts.color,
          maxWidth: maxWidth,
          rotation: rotation,
          textAlign: _toLeftRightCenter(opts.align),
          textBaseline: 'middle',
          translation: [titleX, titleY]
        });
      }
    }]);

    return Title;
  }(Element);

  function createTitle(chart, titleOpts) {
    var title = new Title({
      ctx: chart.ctx,
      options: titleOpts,
      chart: chart
    });
    layouts.configure(chart, title, titleOpts);
    layouts.addBox(chart, title);
    chart.titleBlock = title;
  }

  var plugin_title = {
    id: 'title',
    _element: Title,
    start: function start(chart, _args, options) {
      createTitle(chart, options);
    },
    stop: function stop(chart) {
      var titleBlock = chart.titleBlock;
      layouts.removeBox(chart, titleBlock);
      delete chart.titleBlock;
    },
    beforeUpdate: function beforeUpdate(chart, _args, options) {
      var title = chart.titleBlock;
      layouts.configure(chart, title, options);
      title.options = options;
    },
    defaults: {
      align: 'center',
      display: false,
      font: {
        weight: 'bold'
      },
      fullSize: true,
      padding: 10,
      position: 'top',
      text: '',
      weight: 2000
    },
    defaultRoutes: {
      color: 'color'
    },
    descriptors: {
      _scriptable: true,
      _indexable: false
    }
  };
  var map = new WeakMap();
  var plugin_subtitle = {
    id: 'subtitle',
    start: function start(chart, _args, options) {
      var title = new Title({
        ctx: chart.ctx,
        options: options,
        chart: chart
      });
      layouts.configure(chart, title, options);
      layouts.addBox(chart, title);
      map.set(chart, title);
    },
    stop: function stop(chart) {
      layouts.removeBox(chart, map.get(chart));
      map.delete(chart);
    },
    beforeUpdate: function beforeUpdate(chart, _args, options) {
      var title = map.get(chart);
      layouts.configure(chart, title, options);
      title.options = options;
    },
    defaults: {
      align: 'center',
      display: false,
      font: {
        weight: 'normal'
      },
      fullSize: true,
      padding: 0,
      position: 'top',
      text: '',
      weight: 1500
    },
    defaultRoutes: {
      color: 'color'
    },
    descriptors: {
      _scriptable: true,
      _indexable: false
    }
  };
  var positioners = {
    average: function average(items) {
      if (!items.length) {
        return false;
      }

      var i, len;
      var x = 0;
      var y = 0;
      var count = 0;

      for (i = 0, len = items.length; i < len; ++i) {
        var el = items[i].element;

        if (el && el.hasValue()) {
          var pos = el.tooltipPosition();
          x += pos.x;
          y += pos.y;
          ++count;
        }
      }

      return {
        x: x / count,
        y: y / count
      };
    },
    nearest: function nearest(items, eventPosition) {
      if (!items.length) {
        return false;
      }

      var x = eventPosition.x;
      var y = eventPosition.y;
      var minDistance = Number.POSITIVE_INFINITY;
      var i, len, nearestElement;

      for (i = 0, len = items.length; i < len; ++i) {
        var el = items[i].element;

        if (el && el.hasValue()) {
          var center = el.getCenterPoint();
          var d = distanceBetweenPoints(eventPosition, center);

          if (d < minDistance) {
            minDistance = d;
            nearestElement = el;
          }
        }
      }

      if (nearestElement) {
        var tp = nearestElement.tooltipPosition();
        x = tp.x;
        y = tp.y;
      }

      return {
        x: x,
        y: y
      };
    }
  };

  function pushOrConcat(base, toPush) {
    if (toPush) {
      if (isArray(toPush)) {
        Array.prototype.push.apply(base, toPush);
      } else {
        base.push(toPush);
      }
    }

    return base;
  }

  function splitNewlines(str) {
    if ((typeof str === 'string' || str instanceof String) && str.indexOf('\n') > -1) {
      return str.split('\n');
    }

    return str;
  }

  function createTooltipItem(chart, item) {
    var element = item.element,
        datasetIndex = item.datasetIndex,
        index = item.index;
    var controller = chart.getDatasetMeta(datasetIndex).controller;

    var _controller$getLabelA = controller.getLabelAndValue(index),
        label = _controller$getLabelA.label,
        value = _controller$getLabelA.value;

    return {
      chart: chart,
      label: label,
      parsed: controller.getParsed(index),
      raw: chart.data.datasets[datasetIndex].data[index],
      formattedValue: value,
      dataset: controller.getDataset(),
      dataIndex: index,
      datasetIndex: datasetIndex,
      element: element
    };
  }

  function getTooltipSize(tooltip, options) {
    var ctx = tooltip.chart.ctx;
    var body = tooltip.body,
        footer = tooltip.footer,
        title = tooltip.title;
    var boxWidth = options.boxWidth,
        boxHeight = options.boxHeight;
    var bodyFont = toFont(options.bodyFont);
    var titleFont = toFont(options.titleFont);
    var footerFont = toFont(options.footerFont);
    var titleLineCount = title.length;
    var footerLineCount = footer.length;
    var bodyLineItemCount = body.length;
    var padding = toPadding(options.padding);
    var height = padding.height;
    var width = 0;
    var combinedBodyLength = body.reduce(function (count, bodyItem) {
      return count + bodyItem.before.length + bodyItem.lines.length + bodyItem.after.length;
    }, 0);
    combinedBodyLength += tooltip.beforeBody.length + tooltip.afterBody.length;

    if (titleLineCount) {
      height += titleLineCount * titleFont.lineHeight + (titleLineCount - 1) * options.titleSpacing + options.titleMarginBottom;
    }

    if (combinedBodyLength) {
      var bodyLineHeight = options.displayColors ? Math.max(boxHeight, bodyFont.lineHeight) : bodyFont.lineHeight;
      height += bodyLineItemCount * bodyLineHeight + (combinedBodyLength - bodyLineItemCount) * bodyFont.lineHeight + (combinedBodyLength - 1) * options.bodySpacing;
    }

    if (footerLineCount) {
      height += options.footerMarginTop + footerLineCount * footerFont.lineHeight + (footerLineCount - 1) * options.footerSpacing;
    }

    var widthPadding = 0;

    var maxLineWidth = function maxLineWidth(line) {
      width = Math.max(width, ctx.measureText(line).width + widthPadding);
    };

    ctx.save();
    ctx.font = titleFont.string;
    each(tooltip.title, maxLineWidth);
    ctx.font = bodyFont.string;
    each(tooltip.beforeBody.concat(tooltip.afterBody), maxLineWidth);
    widthPadding = options.displayColors ? boxWidth + 2 + options.boxPadding : 0;
    each(body, function (bodyItem) {
      each(bodyItem.before, maxLineWidth);
      each(bodyItem.lines, maxLineWidth);
      each(bodyItem.after, maxLineWidth);
    });
    widthPadding = 0;
    ctx.font = footerFont.string;
    each(tooltip.footer, maxLineWidth);
    ctx.restore();
    width += padding.width;
    return {
      width: width,
      height: height
    };
  }

  function determineYAlign(chart, size) {
    var y = size.y,
        height = size.height;

    if (y < height / 2) {
      return 'top';
    } else if (y > chart.height - height / 2) {
      return 'bottom';
    }

    return 'center';
  }

  function doesNotFitWithAlign(xAlign, chart, options, size) {
    var x = size.x,
        width = size.width;
    var caret = options.caretSize + options.caretPadding;

    if (xAlign === 'left' && x + width + caret > chart.width) {
      return true;
    }

    if (xAlign === 'right' && x - width - caret < 0) {
      return true;
    }
  }

  function determineXAlign(chart, options, size, yAlign) {
    var x = size.x,
        width = size.width;
    var chartWidth = chart.width,
        _chart$chartArea = chart.chartArea,
        left = _chart$chartArea.left,
        right = _chart$chartArea.right;
    var xAlign = 'center';

    if (yAlign === 'center') {
      xAlign = x <= (left + right) / 2 ? 'left' : 'right';
    } else if (x <= width / 2) {
      xAlign = 'left';
    } else if (x >= chartWidth - width / 2) {
      xAlign = 'right';
    }

    if (doesNotFitWithAlign(xAlign, chart, options, size)) {
      xAlign = 'center';
    }

    return xAlign;
  }

  function determineAlignment(chart, options, size) {
    var yAlign = size.yAlign || options.yAlign || determineYAlign(chart, size);
    return {
      xAlign: size.xAlign || options.xAlign || determineXAlign(chart, options, size, yAlign),
      yAlign: yAlign
    };
  }

  function alignX(size, xAlign) {
    var x = size.x,
        width = size.width;

    if (xAlign === 'right') {
      x -= width;
    } else if (xAlign === 'center') {
      x -= width / 2;
    }

    return x;
  }

  function alignY(size, yAlign, paddingAndSize) {
    var y = size.y,
        height = size.height;

    if (yAlign === 'top') {
      y += paddingAndSize;
    } else if (yAlign === 'bottom') {
      y -= height + paddingAndSize;
    } else {
      y -= height / 2;
    }

    return y;
  }

  function getBackgroundPoint(options, size, alignment, chart) {
    var caretSize = options.caretSize,
        caretPadding = options.caretPadding,
        cornerRadius = options.cornerRadius;
    var xAlign = alignment.xAlign,
        yAlign = alignment.yAlign;
    var paddingAndSize = caretSize + caretPadding;

    var _toTRBLCorners = toTRBLCorners(cornerRadius),
        topLeft = _toTRBLCorners.topLeft,
        topRight = _toTRBLCorners.topRight,
        bottomLeft = _toTRBLCorners.bottomLeft,
        bottomRight = _toTRBLCorners.bottomRight;

    var x = alignX(size, xAlign);
    var y = alignY(size, yAlign, paddingAndSize);

    if (yAlign === 'center') {
      if (xAlign === 'left') {
        x += paddingAndSize;
      } else if (xAlign === 'right') {
        x -= paddingAndSize;
      }
    } else if (xAlign === 'left') {
      x -= Math.max(topLeft, bottomLeft) + caretSize;
    } else if (xAlign === 'right') {
      x += Math.max(topRight, bottomRight) + caretSize;
    }

    return {
      x: _limitValue(x, 0, chart.width - size.width),
      y: _limitValue(y, 0, chart.height - size.height)
    };
  }

  function getAlignedX(tooltip, align, options) {
    var padding = toPadding(options.padding);
    return align === 'center' ? tooltip.x + tooltip.width / 2 : align === 'right' ? tooltip.x + tooltip.width - padding.right : tooltip.x + padding.left;
  }

  function getBeforeAfterBodyLines(callback) {
    return pushOrConcat([], splitNewlines(callback));
  }

  function createTooltipContext(parent, tooltip, tooltipItems) {
    return createContext(parent, {
      tooltip: tooltip,
      tooltipItems: tooltipItems,
      type: 'tooltip'
    });
  }

  function overrideCallbacks(callbacks, context) {
    var override = context && context.dataset && context.dataset.tooltip && context.dataset.tooltip.callbacks;
    return override ? callbacks.override(override) : callbacks;
  }

  var Tooltip = /*#__PURE__*/function (_Element8) {
    _inherits(Tooltip, _Element8);

    var _super18 = _createSuper(Tooltip);

    function Tooltip(config) {
      var _this31;

      _classCallCheck(this, Tooltip);

      _this31 = _super18.call(this);
      _this31.opacity = 0;
      _this31._active = [];
      _this31._eventPosition = undefined;
      _this31._size = undefined;
      _this31._cachedAnimations = undefined;
      _this31._tooltipItems = [];
      _this31.$animations = undefined;
      _this31.$context = undefined;
      _this31.chart = config.chart || config._chart;
      _this31._chart = _this31.chart;
      _this31.options = config.options;
      _this31.dataPoints = undefined;
      _this31.title = undefined;
      _this31.beforeBody = undefined;
      _this31.body = undefined;
      _this31.afterBody = undefined;
      _this31.footer = undefined;
      _this31.xAlign = undefined;
      _this31.yAlign = undefined;
      _this31.x = undefined;
      _this31.y = undefined;
      _this31.height = undefined;
      _this31.width = undefined;
      _this31.caretX = undefined;
      _this31.caretY = undefined;
      _this31.labelColors = undefined;
      _this31.labelPointStyles = undefined;
      _this31.labelTextColors = undefined;
      return _this31;
    }

    _createClass(Tooltip, [{
      key: "initialize",
      value: function initialize(options) {
        this.options = options;
        this._cachedAnimations = undefined;
        this.$context = undefined;
      }
    }, {
      key: "_resolveAnimations",
      value: function _resolveAnimations() {
        var cached = this._cachedAnimations;

        if (cached) {
          return cached;
        }

        var chart = this.chart;
        var options = this.options.setContext(this.getContext());
        var opts = options.enabled && chart.options.animation && options.animations;
        var animations = new Animations(this.chart, opts);

        if (opts._cacheable) {
          this._cachedAnimations = Object.freeze(animations);
        }

        return animations;
      }
    }, {
      key: "getContext",
      value: function getContext() {
        return this.$context || (this.$context = createTooltipContext(this.chart.getContext(), this, this._tooltipItems));
      }
    }, {
      key: "getTitle",
      value: function getTitle(context, options) {
        var callbacks = options.callbacks;
        var beforeTitle = callbacks.beforeTitle.apply(this, [context]);
        var title = callbacks.title.apply(this, [context]);
        var afterTitle = callbacks.afterTitle.apply(this, [context]);
        var lines = [];
        lines = pushOrConcat(lines, splitNewlines(beforeTitle));
        lines = pushOrConcat(lines, splitNewlines(title));
        lines = pushOrConcat(lines, splitNewlines(afterTitle));
        return lines;
      }
    }, {
      key: "getBeforeBody",
      value: function getBeforeBody(tooltipItems, options) {
        return getBeforeAfterBodyLines(options.callbacks.beforeBody.apply(this, [tooltipItems]));
      }
    }, {
      key: "getBody",
      value: function getBody(tooltipItems, options) {
        var _this32 = this;

        var callbacks = options.callbacks;
        var bodyItems = [];
        each(tooltipItems, function (context) {
          var bodyItem = {
            before: [],
            lines: [],
            after: []
          };
          var scoped = overrideCallbacks(callbacks, context);
          pushOrConcat(bodyItem.before, splitNewlines(scoped.beforeLabel.call(_this32, context)));
          pushOrConcat(bodyItem.lines, scoped.label.call(_this32, context));
          pushOrConcat(bodyItem.after, splitNewlines(scoped.afterLabel.call(_this32, context)));
          bodyItems.push(bodyItem);
        });
        return bodyItems;
      }
    }, {
      key: "getAfterBody",
      value: function getAfterBody(tooltipItems, options) {
        return getBeforeAfterBodyLines(options.callbacks.afterBody.apply(this, [tooltipItems]));
      }
    }, {
      key: "getFooter",
      value: function getFooter(tooltipItems, options) {
        var callbacks = options.callbacks;
        var beforeFooter = callbacks.beforeFooter.apply(this, [tooltipItems]);
        var footer = callbacks.footer.apply(this, [tooltipItems]);
        var afterFooter = callbacks.afterFooter.apply(this, [tooltipItems]);
        var lines = [];
        lines = pushOrConcat(lines, splitNewlines(beforeFooter));
        lines = pushOrConcat(lines, splitNewlines(footer));
        lines = pushOrConcat(lines, splitNewlines(afterFooter));
        return lines;
      }
    }, {
      key: "_createItems",
      value: function _createItems(options) {
        var _this33 = this;

        var active = this._active;
        var data = this.chart.data;
        var labelColors = [];
        var labelPointStyles = [];
        var labelTextColors = [];
        var tooltipItems = [];
        var i, len;

        for (i = 0, len = active.length; i < len; ++i) {
          tooltipItems.push(createTooltipItem(this.chart, active[i]));
        }

        if (options.filter) {
          tooltipItems = tooltipItems.filter(function (element, index, array) {
            return options.filter(element, index, array, data);
          });
        }

        if (options.itemSort) {
          tooltipItems = tooltipItems.sort(function (a, b) {
            return options.itemSort(a, b, data);
          });
        }

        each(tooltipItems, function (context) {
          var scoped = overrideCallbacks(options.callbacks, context);
          labelColors.push(scoped.labelColor.call(_this33, context));
          labelPointStyles.push(scoped.labelPointStyle.call(_this33, context));
          labelTextColors.push(scoped.labelTextColor.call(_this33, context));
        });
        this.labelColors = labelColors;
        this.labelPointStyles = labelPointStyles;
        this.labelTextColors = labelTextColors;
        this.dataPoints = tooltipItems;
        return tooltipItems;
      }
    }, {
      key: "update",
      value: function update(changed, replay) {
        var options = this.options.setContext(this.getContext());
        var active = this._active;
        var properties;
        var tooltipItems = [];

        if (!active.length) {
          if (this.opacity !== 0) {
            properties = {
              opacity: 0
            };
          }
        } else {
          var position = positioners[options.position].call(this, active, this._eventPosition);
          tooltipItems = this._createItems(options);
          this.title = this.getTitle(tooltipItems, options);
          this.beforeBody = this.getBeforeBody(tooltipItems, options);
          this.body = this.getBody(tooltipItems, options);
          this.afterBody = this.getAfterBody(tooltipItems, options);
          this.footer = this.getFooter(tooltipItems, options);
          var size = this._size = getTooltipSize(this, options);
          var positionAndSize = Object.assign({}, position, size);
          var alignment = determineAlignment(this.chart, options, positionAndSize);
          var backgroundPoint = getBackgroundPoint(options, positionAndSize, alignment, this.chart);
          this.xAlign = alignment.xAlign;
          this.yAlign = alignment.yAlign;
          properties = {
            opacity: 1,
            x: backgroundPoint.x,
            y: backgroundPoint.y,
            width: size.width,
            height: size.height,
            caretX: position.x,
            caretY: position.y
          };
        }

        this._tooltipItems = tooltipItems;
        this.$context = undefined;

        if (properties) {
          this._resolveAnimations().update(this, properties);
        }

        if (changed && options.external) {
          options.external.call(this, {
            chart: this.chart,
            tooltip: this,
            replay: replay
          });
        }
      }
    }, {
      key: "drawCaret",
      value: function drawCaret(tooltipPoint, ctx, size, options) {
        var caretPosition = this.getCaretPosition(tooltipPoint, size, options);
        ctx.lineTo(caretPosition.x1, caretPosition.y1);
        ctx.lineTo(caretPosition.x2, caretPosition.y2);
        ctx.lineTo(caretPosition.x3, caretPosition.y3);
      }
    }, {
      key: "getCaretPosition",
      value: function getCaretPosition(tooltipPoint, size, options) {
        var xAlign = this.xAlign,
            yAlign = this.yAlign;
        var caretSize = options.caretSize,
            cornerRadius = options.cornerRadius;

        var _toTRBLCorners2 = toTRBLCorners(cornerRadius),
            topLeft = _toTRBLCorners2.topLeft,
            topRight = _toTRBLCorners2.topRight,
            bottomLeft = _toTRBLCorners2.bottomLeft,
            bottomRight = _toTRBLCorners2.bottomRight;

        var ptX = tooltipPoint.x,
            ptY = tooltipPoint.y;
        var width = size.width,
            height = size.height;
        var x1, x2, x3, y1, y2, y3;

        if (yAlign === 'center') {
          y2 = ptY + height / 2;

          if (xAlign === 'left') {
            x1 = ptX;
            x2 = x1 - caretSize;
            y1 = y2 + caretSize;
            y3 = y2 - caretSize;
          } else {
            x1 = ptX + width;
            x2 = x1 + caretSize;
            y1 = y2 - caretSize;
            y3 = y2 + caretSize;
          }

          x3 = x1;
        } else {
          if (xAlign === 'left') {
            x2 = ptX + Math.max(topLeft, bottomLeft) + caretSize;
          } else if (xAlign === 'right') {
            x2 = ptX + width - Math.max(topRight, bottomRight) - caretSize;
          } else {
            x2 = this.caretX;
          }

          if (yAlign === 'top') {
            y1 = ptY;
            y2 = y1 - caretSize;
            x1 = x2 - caretSize;
            x3 = x2 + caretSize;
          } else {
            y1 = ptY + height;
            y2 = y1 + caretSize;
            x1 = x2 + caretSize;
            x3 = x2 - caretSize;
          }

          y3 = y1;
        }

        return {
          x1: x1,
          x2: x2,
          x3: x3,
          y1: y1,
          y2: y2,
          y3: y3
        };
      }
    }, {
      key: "drawTitle",
      value: function drawTitle(pt, ctx, options) {
        var title = this.title;
        var length = title.length;
        var titleFont, titleSpacing, i;

        if (length) {
          var rtlHelper = getRtlAdapter(options.rtl, this.x, this.width);
          pt.x = getAlignedX(this, options.titleAlign, options);
          ctx.textAlign = rtlHelper.textAlign(options.titleAlign);
          ctx.textBaseline = 'middle';
          titleFont = toFont(options.titleFont);
          titleSpacing = options.titleSpacing;
          ctx.fillStyle = options.titleColor;
          ctx.font = titleFont.string;

          for (i = 0; i < length; ++i) {
            ctx.fillText(title[i], rtlHelper.x(pt.x), pt.y + titleFont.lineHeight / 2);
            pt.y += titleFont.lineHeight + titleSpacing;

            if (i + 1 === length) {
              pt.y += options.titleMarginBottom - titleSpacing;
            }
          }
        }
      }
    }, {
      key: "_drawColorBox",
      value: function _drawColorBox(ctx, pt, i, rtlHelper, options) {
        var labelColors = this.labelColors[i];
        var labelPointStyle = this.labelPointStyles[i];
        var boxHeight = options.boxHeight,
            boxWidth = options.boxWidth,
            boxPadding = options.boxPadding;
        var bodyFont = toFont(options.bodyFont);
        var colorX = getAlignedX(this, 'left', options);
        var rtlColorX = rtlHelper.x(colorX);
        var yOffSet = boxHeight < bodyFont.lineHeight ? (bodyFont.lineHeight - boxHeight) / 2 : 0;
        var colorY = pt.y + yOffSet;

        if (options.usePointStyle) {
          var drawOptions = {
            radius: Math.min(boxWidth, boxHeight) / 2,
            pointStyle: labelPointStyle.pointStyle,
            rotation: labelPointStyle.rotation,
            borderWidth: 1
          };
          var centerX = rtlHelper.leftForLtr(rtlColorX, boxWidth) + boxWidth / 2;
          var centerY = colorY + boxHeight / 2;
          ctx.strokeStyle = options.multiKeyBackground;
          ctx.fillStyle = options.multiKeyBackground;
          drawPoint(ctx, drawOptions, centerX, centerY);
          ctx.strokeStyle = labelColors.borderColor;
          ctx.fillStyle = labelColors.backgroundColor;
          drawPoint(ctx, drawOptions, centerX, centerY);
        } else {
          ctx.lineWidth = isObject(labelColors.borderWidth) ? Math.max.apply(Math, _toConsumableArray(Object.values(labelColors.borderWidth))) : labelColors.borderWidth || 1;
          ctx.strokeStyle = labelColors.borderColor;
          ctx.setLineDash(labelColors.borderDash || []);
          ctx.lineDashOffset = labelColors.borderDashOffset || 0;
          var outerX = rtlHelper.leftForLtr(rtlColorX, boxWidth - boxPadding);
          var innerX = rtlHelper.leftForLtr(rtlHelper.xPlus(rtlColorX, 1), boxWidth - boxPadding - 2);
          var borderRadius = toTRBLCorners(labelColors.borderRadius);

          if (Object.values(borderRadius).some(function (v) {
            return v !== 0;
          })) {
            ctx.beginPath();
            ctx.fillStyle = options.multiKeyBackground;
            addRoundedRectPath(ctx, {
              x: outerX,
              y: colorY,
              w: boxWidth,
              h: boxHeight,
              radius: borderRadius
            });
            ctx.fill();
            ctx.stroke();
            ctx.fillStyle = labelColors.backgroundColor;
            ctx.beginPath();
            addRoundedRectPath(ctx, {
              x: innerX,
              y: colorY + 1,
              w: boxWidth - 2,
              h: boxHeight - 2,
              radius: borderRadius
            });
            ctx.fill();
          } else {
            ctx.fillStyle = options.multiKeyBackground;
            ctx.fillRect(outerX, colorY, boxWidth, boxHeight);
            ctx.strokeRect(outerX, colorY, boxWidth, boxHeight);
            ctx.fillStyle = labelColors.backgroundColor;
            ctx.fillRect(innerX, colorY + 1, boxWidth - 2, boxHeight - 2);
          }
        }

        ctx.fillStyle = this.labelTextColors[i];
      }
    }, {
      key: "drawBody",
      value: function drawBody(pt, ctx, options) {
        var body = this.body;
        var bodySpacing = options.bodySpacing,
            bodyAlign = options.bodyAlign,
            displayColors = options.displayColors,
            boxHeight = options.boxHeight,
            boxWidth = options.boxWidth,
            boxPadding = options.boxPadding;
        var bodyFont = toFont(options.bodyFont);
        var bodyLineHeight = bodyFont.lineHeight;
        var xLinePadding = 0;
        var rtlHelper = getRtlAdapter(options.rtl, this.x, this.width);

        var fillLineOfText = function fillLineOfText(line) {
          ctx.fillText(line, rtlHelper.x(pt.x + xLinePadding), pt.y + bodyLineHeight / 2);
          pt.y += bodyLineHeight + bodySpacing;
        };

        var bodyAlignForCalculation = rtlHelper.textAlign(bodyAlign);
        var bodyItem, textColor, lines, i, j, ilen, jlen;
        ctx.textAlign = bodyAlign;
        ctx.textBaseline = 'middle';
        ctx.font = bodyFont.string;
        pt.x = getAlignedX(this, bodyAlignForCalculation, options);
        ctx.fillStyle = options.bodyColor;
        each(this.beforeBody, fillLineOfText);
        xLinePadding = displayColors && bodyAlignForCalculation !== 'right' ? bodyAlign === 'center' ? boxWidth / 2 + boxPadding : boxWidth + 2 + boxPadding : 0;

        for (i = 0, ilen = body.length; i < ilen; ++i) {
          bodyItem = body[i];
          textColor = this.labelTextColors[i];
          ctx.fillStyle = textColor;
          each(bodyItem.before, fillLineOfText);
          lines = bodyItem.lines;

          if (displayColors && lines.length) {
            this._drawColorBox(ctx, pt, i, rtlHelper, options);

            bodyLineHeight = Math.max(bodyFont.lineHeight, boxHeight);
          }

          for (j = 0, jlen = lines.length; j < jlen; ++j) {
            fillLineOfText(lines[j]);
            bodyLineHeight = bodyFont.lineHeight;
          }

          each(bodyItem.after, fillLineOfText);
        }

        xLinePadding = 0;
        bodyLineHeight = bodyFont.lineHeight;
        each(this.afterBody, fillLineOfText);
        pt.y -= bodySpacing;
      }
    }, {
      key: "drawFooter",
      value: function drawFooter(pt, ctx, options) {
        var footer = this.footer;
        var length = footer.length;
        var footerFont, i;

        if (length) {
          var rtlHelper = getRtlAdapter(options.rtl, this.x, this.width);
          pt.x = getAlignedX(this, options.footerAlign, options);
          pt.y += options.footerMarginTop;
          ctx.textAlign = rtlHelper.textAlign(options.footerAlign);
          ctx.textBaseline = 'middle';
          footerFont = toFont(options.footerFont);
          ctx.fillStyle = options.footerColor;
          ctx.font = footerFont.string;

          for (i = 0; i < length; ++i) {
            ctx.fillText(footer[i], rtlHelper.x(pt.x), pt.y + footerFont.lineHeight / 2);
            pt.y += footerFont.lineHeight + options.footerSpacing;
          }
        }
      }
    }, {
      key: "drawBackground",
      value: function drawBackground(pt, ctx, tooltipSize, options) {
        var xAlign = this.xAlign,
            yAlign = this.yAlign;
        var x = pt.x,
            y = pt.y;
        var width = tooltipSize.width,
            height = tooltipSize.height;

        var _toTRBLCorners3 = toTRBLCorners(options.cornerRadius),
            topLeft = _toTRBLCorners3.topLeft,
            topRight = _toTRBLCorners3.topRight,
            bottomLeft = _toTRBLCorners3.bottomLeft,
            bottomRight = _toTRBLCorners3.bottomRight;

        ctx.fillStyle = options.backgroundColor;
        ctx.strokeStyle = options.borderColor;
        ctx.lineWidth = options.borderWidth;
        ctx.beginPath();
        ctx.moveTo(x + topLeft, y);

        if (yAlign === 'top') {
          this.drawCaret(pt, ctx, tooltipSize, options);
        }

        ctx.lineTo(x + width - topRight, y);
        ctx.quadraticCurveTo(x + width, y, x + width, y + topRight);

        if (yAlign === 'center' && xAlign === 'right') {
          this.drawCaret(pt, ctx, tooltipSize, options);
        }

        ctx.lineTo(x + width, y + height - bottomRight);
        ctx.quadraticCurveTo(x + width, y + height, x + width - bottomRight, y + height);

        if (yAlign === 'bottom') {
          this.drawCaret(pt, ctx, tooltipSize, options);
        }

        ctx.lineTo(x + bottomLeft, y + height);
        ctx.quadraticCurveTo(x, y + height, x, y + height - bottomLeft);

        if (yAlign === 'center' && xAlign === 'left') {
          this.drawCaret(pt, ctx, tooltipSize, options);
        }

        ctx.lineTo(x, y + topLeft);
        ctx.quadraticCurveTo(x, y, x + topLeft, y);
        ctx.closePath();
        ctx.fill();

        if (options.borderWidth > 0) {
          ctx.stroke();
        }
      }
    }, {
      key: "_updateAnimationTarget",
      value: function _updateAnimationTarget(options) {
        var chart = this.chart;
        var anims = this.$animations;
        var animX = anims && anims.x;
        var animY = anims && anims.y;

        if (animX || animY) {
          var position = positioners[options.position].call(this, this._active, this._eventPosition);

          if (!position) {
            return;
          }

          var size = this._size = getTooltipSize(this, options);
          var positionAndSize = Object.assign({}, position, this._size);
          var alignment = determineAlignment(chart, options, positionAndSize);
          var point = getBackgroundPoint(options, positionAndSize, alignment, chart);

          if (animX._to !== point.x || animY._to !== point.y) {
            this.xAlign = alignment.xAlign;
            this.yAlign = alignment.yAlign;
            this.width = size.width;
            this.height = size.height;
            this.caretX = position.x;
            this.caretY = position.y;

            this._resolveAnimations().update(this, point);
          }
        }
      }
    }, {
      key: "_willRender",
      value: function _willRender() {
        return !!this.opacity;
      }
    }, {
      key: "draw",
      value: function draw(ctx) {
        var options = this.options.setContext(this.getContext());
        var opacity = this.opacity;

        if (!opacity) {
          return;
        }

        this._updateAnimationTarget(options);

        var tooltipSize = {
          width: this.width,
          height: this.height
        };
        var pt = {
          x: this.x,
          y: this.y
        };
        opacity = Math.abs(opacity) < 1e-3 ? 0 : opacity;
        var padding = toPadding(options.padding);
        var hasTooltipContent = this.title.length || this.beforeBody.length || this.body.length || this.afterBody.length || this.footer.length;

        if (options.enabled && hasTooltipContent) {
          ctx.save();
          ctx.globalAlpha = opacity;
          this.drawBackground(pt, ctx, tooltipSize, options);
          overrideTextDirection(ctx, options.textDirection);
          pt.y += padding.top;
          this.drawTitle(pt, ctx, options);
          this.drawBody(pt, ctx, options);
          this.drawFooter(pt, ctx, options);
          restoreTextDirection(ctx, options.textDirection);
          ctx.restore();
        }
      }
    }, {
      key: "getActiveElements",
      value: function getActiveElements() {
        return this._active || [];
      }
    }, {
      key: "setActiveElements",
      value: function setActiveElements(activeElements, eventPosition) {
        var _this34 = this;

        var lastActive = this._active;
        var active = activeElements.map(function (_ref11) {
          var datasetIndex = _ref11.datasetIndex,
              index = _ref11.index;

          var meta = _this34.chart.getDatasetMeta(datasetIndex);

          if (!meta) {
            throw new Error('Cannot find a dataset at index ' + datasetIndex);
          }

          return {
            datasetIndex: datasetIndex,
            element: meta.data[index],
            index: index
          };
        });
        var changed = !_elementsEqual(lastActive, active);

        var positionChanged = this._positionChanged(active, eventPosition);

        if (changed || positionChanged) {
          this._active = active;
          this._eventPosition = eventPosition;
          this._ignoreReplayEvents = true;
          this.update(true);
        }
      }
    }, {
      key: "handleEvent",
      value: function handleEvent(e, replay) {
        var inChartArea = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : true;

        if (replay && this._ignoreReplayEvents) {
          return false;
        }

        this._ignoreReplayEvents = false;
        var options = this.options;
        var lastActive = this._active || [];

        var active = this._getActiveElements(e, lastActive, replay, inChartArea);

        var positionChanged = this._positionChanged(active, e);

        var changed = replay || !_elementsEqual(active, lastActive) || positionChanged;

        if (changed) {
          this._active = active;

          if (options.enabled || options.external) {
            this._eventPosition = {
              x: e.x,
              y: e.y
            };
            this.update(true, replay);
          }
        }

        return changed;
      }
    }, {
      key: "_getActiveElements",
      value: function _getActiveElements(e, lastActive, replay, inChartArea) {
        var options = this.options;

        if (e.type === 'mouseout') {
          return [];
        }

        if (!inChartArea) {
          return lastActive;
        }

        var active = this.chart.getElementsAtEventForMode(e, options.mode, options, replay);

        if (options.reverse) {
          active.reverse();
        }

        return active;
      }
    }, {
      key: "_positionChanged",
      value: function _positionChanged(active, e) {
        var caretX = this.caretX,
            caretY = this.caretY,
            options = this.options;
        var position = positioners[options.position].call(this, active, e);
        return position !== false && (caretX !== position.x || caretY !== position.y);
      }
    }]);

    return Tooltip;
  }(Element);

  Tooltip.positioners = positioners;
  var plugin_tooltip = {
    id: 'tooltip',
    _element: Tooltip,
    positioners: positioners,
    afterInit: function afterInit(chart, _args, options) {
      if (options) {
        chart.tooltip = new Tooltip({
          chart: chart,
          options: options
        });
      }
    },
    beforeUpdate: function beforeUpdate(chart, _args, options) {
      if (chart.tooltip) {
        chart.tooltip.initialize(options);
      }
    },
    reset: function reset(chart, _args, options) {
      if (chart.tooltip) {
        chart.tooltip.initialize(options);
      }
    },
    afterDraw: function afterDraw(chart) {
      var tooltip = chart.tooltip;

      if (tooltip && tooltip._willRender()) {
        var args = {
          tooltip: tooltip
        };

        if (chart.notifyPlugins('beforeTooltipDraw', args) === false) {
          return;
        }

        tooltip.draw(chart.ctx);
        chart.notifyPlugins('afterTooltipDraw', args);
      }
    },
    afterEvent: function afterEvent(chart, args) {
      if (chart.tooltip) {
        var useFinalPosition = args.replay;

        if (chart.tooltip.handleEvent(args.event, useFinalPosition, args.inChartArea)) {
          args.changed = true;
        }
      }
    },
    defaults: {
      enabled: true,
      external: null,
      position: 'average',
      backgroundColor: 'rgba(0,0,0,0.8)',
      titleColor: '#fff',
      titleFont: {
        weight: 'bold'
      },
      titleSpacing: 2,
      titleMarginBottom: 6,
      titleAlign: 'left',
      bodyColor: '#fff',
      bodySpacing: 2,
      bodyFont: {},
      bodyAlign: 'left',
      footerColor: '#fff',
      footerSpacing: 2,
      footerMarginTop: 6,
      footerFont: {
        weight: 'bold'
      },
      footerAlign: 'left',
      padding: 6,
      caretPadding: 2,
      caretSize: 5,
      cornerRadius: 6,
      boxHeight: function boxHeight(ctx, opts) {
        return opts.bodyFont.size;
      },
      boxWidth: function boxWidth(ctx, opts) {
        return opts.bodyFont.size;
      },
      multiKeyBackground: '#fff',
      displayColors: true,
      boxPadding: 0,
      borderColor: 'rgba(0,0,0,0)',
      borderWidth: 0,
      animation: {
        duration: 400,
        easing: 'easeOutQuart'
      },
      animations: {
        numbers: {
          type: 'number',
          properties: ['x', 'y', 'width', 'height', 'caretX', 'caretY']
        },
        opacity: {
          easing: 'linear',
          duration: 200
        }
      },
      callbacks: {
        beforeTitle: noop,
        title: function title(tooltipItems) {
          if (tooltipItems.length > 0) {
            var item = tooltipItems[0];
            var labels = item.chart.data.labels;
            var labelCount = labels ? labels.length : 0;

            if (this && this.options && this.options.mode === 'dataset') {
              return item.dataset.label || '';
            } else if (item.label) {
              return item.label;
            } else if (labelCount > 0 && item.dataIndex < labelCount) {
              return labels[item.dataIndex];
            }
          }

          return '';
        },
        afterTitle: noop,
        beforeBody: noop,
        beforeLabel: noop,
        label: function label(tooltipItem) {
          if (this && this.options && this.options.mode === 'dataset') {
            return tooltipItem.label + ': ' + tooltipItem.formattedValue || tooltipItem.formattedValue;
          }

          var label = tooltipItem.dataset.label || '';

          if (label) {
            label += ': ';
          }

          var value = tooltipItem.formattedValue;

          if (!isNullOrUndef(value)) {
            label += value;
          }

          return label;
        },
        labelColor: function labelColor(tooltipItem) {
          var meta = tooltipItem.chart.getDatasetMeta(tooltipItem.datasetIndex);
          var options = meta.controller.getStyle(tooltipItem.dataIndex);
          return {
            borderColor: options.borderColor,
            backgroundColor: options.backgroundColor,
            borderWidth: options.borderWidth,
            borderDash: options.borderDash,
            borderDashOffset: options.borderDashOffset,
            borderRadius: 0
          };
        },
        labelTextColor: function labelTextColor() {
          return this.options.bodyColor;
        },
        labelPointStyle: function labelPointStyle(tooltipItem) {
          var meta = tooltipItem.chart.getDatasetMeta(tooltipItem.datasetIndex);
          var options = meta.controller.getStyle(tooltipItem.dataIndex);
          return {
            pointStyle: options.pointStyle,
            rotation: options.rotation
          };
        },
        afterLabel: noop,
        afterBody: noop,
        beforeFooter: noop,
        footer: noop,
        afterFooter: noop
      }
    },
    defaultRoutes: {
      bodyFont: 'font',
      footerFont: 'font',
      titleFont: 'font'
    },
    descriptors: {
      _scriptable: function _scriptable(name) {
        return name !== 'filter' && name !== 'itemSort' && name !== 'external';
      },
      _indexable: false,
      callbacks: {
        _scriptable: false,
        _indexable: false
      },
      animation: {
        _fallback: false
      },
      animations: {
        _fallback: 'animation'
      }
    },
    additionalOptionScopes: ['interaction']
  };
  var plugins = /*#__PURE__*/Object.freeze({
    __proto__: null,
    Decimation: plugin_decimation,
    Filler: index,
    Legend: plugin_legend,
    SubTitle: plugin_subtitle,
    Title: plugin_title,
    Tooltip: plugin_tooltip
  });

  var addIfString = function addIfString(labels, raw, index, addedLabels) {
    if (typeof raw === 'string') {
      index = labels.push(raw) - 1;
      addedLabels.unshift({
        index: index,
        label: raw
      });
    } else if (isNaN(raw)) {
      index = null;
    }

    return index;
  };

  function findOrAddLabel(labels, raw, index, addedLabels) {
    var first = labels.indexOf(raw);

    if (first === -1) {
      return addIfString(labels, raw, index, addedLabels);
    }

    var last = labels.lastIndexOf(raw);
    return first !== last ? index : first;
  }

  var validIndex = function validIndex(index, max) {
    return index === null ? null : _limitValue(Math.round(index), 0, max);
  };

  var CategoryScale = /*#__PURE__*/function (_Scale) {
    _inherits(CategoryScale, _Scale);

    var _super19 = _createSuper(CategoryScale);

    function CategoryScale(cfg) {
      var _this35;

      _classCallCheck(this, CategoryScale);

      _this35 = _super19.call(this, cfg);
      _this35._startValue = undefined;
      _this35._valueRange = 0;
      _this35._addedLabels = [];
      return _this35;
    }

    _createClass(CategoryScale, [{
      key: "init",
      value: function init(scaleOptions) {
        var added = this._addedLabels;

        if (added.length) {
          var labels = this.getLabels();

          var _iterator25 = _createForOfIteratorHelper(added),
              _step25;

          try {
            for (_iterator25.s(); !(_step25 = _iterator25.n()).done;) {
              var _step25$value = _step25.value,
                  _index3 = _step25$value.index,
                  label = _step25$value.label;

              if (labels[_index3] === label) {
                labels.splice(_index3, 1);
              }
            }
          } catch (err) {
            _iterator25.e(err);
          } finally {
            _iterator25.f();
          }

          this._addedLabels = [];
        }

        _get(_getPrototypeOf(CategoryScale.prototype), "init", this).call(this, scaleOptions);
      }
    }, {
      key: "parse",
      value: function parse(raw, index) {
        if (isNullOrUndef(raw)) {
          return null;
        }

        var labels = this.getLabels();
        index = isFinite(index) && labels[index] === raw ? index : findOrAddLabel(labels, raw, valueOrDefault(index, raw), this._addedLabels);
        return validIndex(index, labels.length - 1);
      }
    }, {
      key: "determineDataLimits",
      value: function determineDataLimits() {
        var _this$getUserBounds2 = this.getUserBounds(),
            minDefined = _this$getUserBounds2.minDefined,
            maxDefined = _this$getUserBounds2.maxDefined;

        var _this$getMinMax = this.getMinMax(true),
            min = _this$getMinMax.min,
            max = _this$getMinMax.max;

        if (this.options.bounds === 'ticks') {
          if (!minDefined) {
            min = 0;
          }

          if (!maxDefined) {
            max = this.getLabels().length - 1;
          }
        }

        this.min = min;
        this.max = max;
      }
    }, {
      key: "buildTicks",
      value: function buildTicks() {
        var min = this.min;
        var max = this.max;
        var offset = this.options.offset;
        var ticks = [];
        var labels = this.getLabels();
        labels = min === 0 && max === labels.length - 1 ? labels : labels.slice(min, max + 1);
        this._valueRange = Math.max(labels.length - (offset ? 0 : 1), 1);
        this._startValue = this.min - (offset ? 0.5 : 0);

        for (var value = min; value <= max; value++) {
          ticks.push({
            value: value
          });
        }

        return ticks;
      }
    }, {
      key: "getLabelForValue",
      value: function getLabelForValue(value) {
        var labels = this.getLabels();

        if (value >= 0 && value < labels.length) {
          return labels[value];
        }

        return value;
      }
    }, {
      key: "configure",
      value: function configure() {
        _get(_getPrototypeOf(CategoryScale.prototype), "configure", this).call(this);

        if (!this.isHorizontal()) {
          this._reversePixels = !this._reversePixels;
        }
      }
    }, {
      key: "getPixelForValue",
      value: function getPixelForValue(value) {
        if (typeof value !== 'number') {
          value = this.parse(value);
        }

        return value === null ? NaN : this.getPixelForDecimal((value - this._startValue) / this._valueRange);
      }
    }, {
      key: "getPixelForTick",
      value: function getPixelForTick(index) {
        var ticks = this.ticks;

        if (index < 0 || index > ticks.length - 1) {
          return null;
        }

        return this.getPixelForValue(ticks[index].value);
      }
    }, {
      key: "getValueForPixel",
      value: function getValueForPixel(pixel) {
        return Math.round(this._startValue + this.getDecimalForPixel(pixel) * this._valueRange);
      }
    }, {
      key: "getBasePixel",
      value: function getBasePixel() {
        return this.bottom;
      }
    }]);

    return CategoryScale;
  }(Scale);

  CategoryScale.id = 'category';
  CategoryScale.defaults = {
    ticks: {
      callback: CategoryScale.prototype.getLabelForValue
    }
  };

  function generateTicks$1(generationOptions, dataRange) {
    var ticks = [];
    var MIN_SPACING = 1e-14;
    var bounds = generationOptions.bounds,
        step = generationOptions.step,
        min = generationOptions.min,
        max = generationOptions.max,
        precision = generationOptions.precision,
        count = generationOptions.count,
        maxTicks = generationOptions.maxTicks,
        maxDigits = generationOptions.maxDigits,
        includeBounds = generationOptions.includeBounds;
    var unit = step || 1;
    var maxSpaces = maxTicks - 1;
    var rmin = dataRange.min,
        rmax = dataRange.max;
    var minDefined = !isNullOrUndef(min);
    var maxDefined = !isNullOrUndef(max);
    var countDefined = !isNullOrUndef(count);
    var minSpacing = (rmax - rmin) / (maxDigits + 1);
    var spacing = niceNum((rmax - rmin) / maxSpaces / unit) * unit;
    var factor, niceMin, niceMax, numSpaces;

    if (spacing < MIN_SPACING && !minDefined && !maxDefined) {
      return [{
        value: rmin
      }, {
        value: rmax
      }];
    }

    numSpaces = Math.ceil(rmax / spacing) - Math.floor(rmin / spacing);

    if (numSpaces > maxSpaces) {
      spacing = niceNum(numSpaces * spacing / maxSpaces / unit) * unit;
    }

    if (!isNullOrUndef(precision)) {
      factor = Math.pow(10, precision);
      spacing = Math.ceil(spacing * factor) / factor;
    }

    if (bounds === 'ticks') {
      niceMin = Math.floor(rmin / spacing) * spacing;
      niceMax = Math.ceil(rmax / spacing) * spacing;
    } else {
      niceMin = rmin;
      niceMax = rmax;
    }

    if (minDefined && maxDefined && step && almostWhole((max - min) / step, spacing / 1000)) {
      numSpaces = Math.round(Math.min((max - min) / spacing, maxTicks));
      spacing = (max - min) / numSpaces;
      niceMin = min;
      niceMax = max;
    } else if (countDefined) {
      niceMin = minDefined ? min : niceMin;
      niceMax = maxDefined ? max : niceMax;
      numSpaces = count - 1;
      spacing = (niceMax - niceMin) / numSpaces;
    } else {
      numSpaces = (niceMax - niceMin) / spacing;

      if (almostEquals(numSpaces, Math.round(numSpaces), spacing / 1000)) {
        numSpaces = Math.round(numSpaces);
      } else {
        numSpaces = Math.ceil(numSpaces);
      }
    }

    var decimalPlaces = Math.max(_decimalPlaces(spacing), _decimalPlaces(niceMin));
    factor = Math.pow(10, isNullOrUndef(precision) ? decimalPlaces : precision);
    niceMin = Math.round(niceMin * factor) / factor;
    niceMax = Math.round(niceMax * factor) / factor;
    var j = 0;

    if (minDefined) {
      if (includeBounds && niceMin !== min) {
        ticks.push({
          value: min
        });

        if (niceMin < min) {
          j++;
        }

        if (almostEquals(Math.round((niceMin + j * spacing) * factor) / factor, min, relativeLabelSize(min, minSpacing, generationOptions))) {
          j++;
        }
      } else if (niceMin < min) {
        j++;
      }
    }

    for (; j < numSpaces; ++j) {
      ticks.push({
        value: Math.round((niceMin + j * spacing) * factor) / factor
      });
    }

    if (maxDefined && includeBounds && niceMax !== max) {
      if (ticks.length && almostEquals(ticks[ticks.length - 1].value, max, relativeLabelSize(max, minSpacing, generationOptions))) {
        ticks[ticks.length - 1].value = max;
      } else {
        ticks.push({
          value: max
        });
      }
    } else if (!maxDefined || niceMax === max) {
      ticks.push({
        value: niceMax
      });
    }

    return ticks;
  }

  function relativeLabelSize(value, minSpacing, _ref12) {
    var horizontal = _ref12.horizontal,
        minRotation = _ref12.minRotation;
    var rad = toRadians(minRotation);
    var ratio = (horizontal ? Math.sin(rad) : Math.cos(rad)) || 0.001;
    var length = 0.75 * minSpacing * ('' + value).length;
    return Math.min(minSpacing / ratio, length);
  }

  var LinearScaleBase = /*#__PURE__*/function (_Scale2) {
    _inherits(LinearScaleBase, _Scale2);

    var _super20 = _createSuper(LinearScaleBase);

    function LinearScaleBase(cfg) {
      var _this36;

      _classCallCheck(this, LinearScaleBase);

      _this36 = _super20.call(this, cfg);
      _this36.start = undefined;
      _this36.end = undefined;
      _this36._startValue = undefined;
      _this36._endValue = undefined;
      _this36._valueRange = 0;
      return _this36;
    }

    _createClass(LinearScaleBase, [{
      key: "parse",
      value: function parse(raw, index) {
        if (isNullOrUndef(raw)) {
          return null;
        }

        if ((typeof raw === 'number' || raw instanceof Number) && !isFinite(+raw)) {
          return null;
        }

        return +raw;
      }
    }, {
      key: "handleTickRangeOptions",
      value: function handleTickRangeOptions() {
        var beginAtZero = this.options.beginAtZero;

        var _this$getUserBounds3 = this.getUserBounds(),
            minDefined = _this$getUserBounds3.minDefined,
            maxDefined = _this$getUserBounds3.maxDefined;

        var min = this.min,
            max = this.max;

        var setMin = function setMin(v) {
          return min = minDefined ? min : v;
        };

        var setMax = function setMax(v) {
          return max = maxDefined ? max : v;
        };

        if (beginAtZero) {
          var minSign = sign(min);
          var maxSign = sign(max);

          if (minSign < 0 && maxSign < 0) {
            setMax(0);
          } else if (minSign > 0 && maxSign > 0) {
            setMin(0);
          }
        }

        if (min === max) {
          var offset = 1;

          if (max >= Number.MAX_SAFE_INTEGER || min <= Number.MIN_SAFE_INTEGER) {
            offset = Math.abs(max * 0.05);
          }

          setMax(max + offset);

          if (!beginAtZero) {
            setMin(min - offset);
          }
        }

        this.min = min;
        this.max = max;
      }
    }, {
      key: "getTickLimit",
      value: function getTickLimit() {
        var tickOpts = this.options.ticks;
        var maxTicksLimit = tickOpts.maxTicksLimit,
            stepSize = tickOpts.stepSize;
        var maxTicks;

        if (stepSize) {
          maxTicks = Math.ceil(this.max / stepSize) - Math.floor(this.min / stepSize) + 1;

          if (maxTicks > 1000) {
            console.warn("scales.".concat(this.id, ".ticks.stepSize: ").concat(stepSize, " would result generating up to ").concat(maxTicks, " ticks. Limiting to 1000."));
            maxTicks = 1000;
          }
        } else {
          maxTicks = this.computeTickLimit();
          maxTicksLimit = maxTicksLimit || 11;
        }

        if (maxTicksLimit) {
          maxTicks = Math.min(maxTicksLimit, maxTicks);
        }

        return maxTicks;
      }
    }, {
      key: "computeTickLimit",
      value: function computeTickLimit() {
        return Number.POSITIVE_INFINITY;
      }
    }, {
      key: "buildTicks",
      value: function buildTicks() {
        var opts = this.options;
        var tickOpts = opts.ticks;
        var maxTicks = this.getTickLimit();
        maxTicks = Math.max(2, maxTicks);
        var numericGeneratorOptions = {
          maxTicks: maxTicks,
          bounds: opts.bounds,
          min: opts.min,
          max: opts.max,
          precision: tickOpts.precision,
          step: tickOpts.stepSize,
          count: tickOpts.count,
          maxDigits: this._maxDigits(),
          horizontal: this.isHorizontal(),
          minRotation: tickOpts.minRotation || 0,
          includeBounds: tickOpts.includeBounds !== false
        };
        var dataRange = this._range || this;
        var ticks = generateTicks$1(numericGeneratorOptions, dataRange);

        if (opts.bounds === 'ticks') {
          _setMinAndMaxByKey(ticks, this, 'value');
        }

        if (opts.reverse) {
          ticks.reverse();
          this.start = this.max;
          this.end = this.min;
        } else {
          this.start = this.min;
          this.end = this.max;
        }

        return ticks;
      }
    }, {
      key: "configure",
      value: function configure() {
        var ticks = this.ticks;
        var start = this.min;
        var end = this.max;

        _get(_getPrototypeOf(LinearScaleBase.prototype), "configure", this).call(this);

        if (this.options.offset && ticks.length) {
          var offset = (end - start) / Math.max(ticks.length - 1, 1) / 2;
          start -= offset;
          end += offset;
        }

        this._startValue = start;
        this._endValue = end;
        this._valueRange = end - start;
      }
    }, {
      key: "getLabelForValue",
      value: function getLabelForValue(value) {
        return formatNumber(value, this.chart.options.locale, this.options.ticks.format);
      }
    }]);

    return LinearScaleBase;
  }(Scale);

  var LinearScale = /*#__PURE__*/function (_LinearScaleBase) {
    _inherits(LinearScale, _LinearScaleBase);

    var _super21 = _createSuper(LinearScale);

    function LinearScale() {
      _classCallCheck(this, LinearScale);

      return _super21.apply(this, arguments);
    }

    _createClass(LinearScale, [{
      key: "determineDataLimits",
      value: function determineDataLimits() {
        var _this$getMinMax2 = this.getMinMax(true),
            min = _this$getMinMax2.min,
            max = _this$getMinMax2.max;

        this.min = isNumberFinite(min) ? min : 0;
        this.max = isNumberFinite(max) ? max : 1;
        this.handleTickRangeOptions();
      }
    }, {
      key: "computeTickLimit",
      value: function computeTickLimit() {
        var horizontal = this.isHorizontal();
        var length = horizontal ? this.width : this.height;
        var minRotation = toRadians(this.options.ticks.minRotation);
        var ratio = (horizontal ? Math.sin(minRotation) : Math.cos(minRotation)) || 0.001;

        var tickFont = this._resolveTickFontOptions(0);

        return Math.ceil(length / Math.min(40, tickFont.lineHeight / ratio));
      }
    }, {
      key: "getPixelForValue",
      value: function getPixelForValue(value) {
        return value === null ? NaN : this.getPixelForDecimal((value - this._startValue) / this._valueRange);
      }
    }, {
      key: "getValueForPixel",
      value: function getValueForPixel(pixel) {
        return this._startValue + this.getDecimalForPixel(pixel) * this._valueRange;
      }
    }]);

    return LinearScale;
  }(LinearScaleBase);

  LinearScale.id = 'linear';
  LinearScale.defaults = {
    ticks: {
      callback: Ticks.formatters.numeric
    }
  };

  function isMajor(tickVal) {
    var remain = tickVal / Math.pow(10, Math.floor(log10(tickVal)));
    return remain === 1;
  }

  function generateTicks(generationOptions, dataRange) {
    var endExp = Math.floor(log10(dataRange.max));
    var endSignificand = Math.ceil(dataRange.max / Math.pow(10, endExp));
    var ticks = [];
    var tickVal = finiteOrDefault(generationOptions.min, Math.pow(10, Math.floor(log10(dataRange.min))));
    var exp = Math.floor(log10(tickVal));
    var significand = Math.floor(tickVal / Math.pow(10, exp));
    var precision = exp < 0 ? Math.pow(10, Math.abs(exp)) : 1;

    do {
      ticks.push({
        value: tickVal,
        major: isMajor(tickVal)
      });
      ++significand;

      if (significand === 10) {
        significand = 1;
        ++exp;
        precision = exp >= 0 ? 1 : precision;
      }

      tickVal = Math.round(significand * Math.pow(10, exp) * precision) / precision;
    } while (exp < endExp || exp === endExp && significand < endSignificand);

    var lastTick = finiteOrDefault(generationOptions.max, tickVal);
    ticks.push({
      value: lastTick,
      major: isMajor(tickVal)
    });
    return ticks;
  }

  var LogarithmicScale = /*#__PURE__*/function (_Scale3) {
    _inherits(LogarithmicScale, _Scale3);

    var _super22 = _createSuper(LogarithmicScale);

    function LogarithmicScale(cfg) {
      var _this37;

      _classCallCheck(this, LogarithmicScale);

      _this37 = _super22.call(this, cfg);
      _this37.start = undefined;
      _this37.end = undefined;
      _this37._startValue = undefined;
      _this37._valueRange = 0;
      return _this37;
    }

    _createClass(LogarithmicScale, [{
      key: "parse",
      value: function parse(raw, index) {
        var value = LinearScaleBase.prototype.parse.apply(this, [raw, index]);

        if (value === 0) {
          this._zero = true;
          return undefined;
        }

        return isNumberFinite(value) && value > 0 ? value : null;
      }
    }, {
      key: "determineDataLimits",
      value: function determineDataLimits() {
        var _this$getMinMax3 = this.getMinMax(true),
            min = _this$getMinMax3.min,
            max = _this$getMinMax3.max;

        this.min = isNumberFinite(min) ? Math.max(0, min) : null;
        this.max = isNumberFinite(max) ? Math.max(0, max) : null;

        if (this.options.beginAtZero) {
          this._zero = true;
        }

        this.handleTickRangeOptions();
      }
    }, {
      key: "handleTickRangeOptions",
      value: function handleTickRangeOptions() {
        var _this$getUserBounds4 = this.getUserBounds(),
            minDefined = _this$getUserBounds4.minDefined,
            maxDefined = _this$getUserBounds4.maxDefined;

        var min = this.min;
        var max = this.max;

        var setMin = function setMin(v) {
          return min = minDefined ? min : v;
        };

        var setMax = function setMax(v) {
          return max = maxDefined ? max : v;
        };

        var exp = function exp(v, m) {
          return Math.pow(10, Math.floor(log10(v)) + m);
        };

        if (min === max) {
          if (min <= 0) {
            setMin(1);
            setMax(10);
          } else {
            setMin(exp(min, -1));
            setMax(exp(max, +1));
          }
        }

        if (min <= 0) {
          setMin(exp(max, -1));
        }

        if (max <= 0) {
          setMax(exp(min, +1));
        }

        if (this._zero && this.min !== this._suggestedMin && min === exp(this.min, 0)) {
          setMin(exp(min, -1));
        }

        this.min = min;
        this.max = max;
      }
    }, {
      key: "buildTicks",
      value: function buildTicks() {
        var opts = this.options;
        var generationOptions = {
          min: this._userMin,
          max: this._userMax
        };
        var ticks = generateTicks(generationOptions, this);

        if (opts.bounds === 'ticks') {
          _setMinAndMaxByKey(ticks, this, 'value');
        }

        if (opts.reverse) {
          ticks.reverse();
          this.start = this.max;
          this.end = this.min;
        } else {
          this.start = this.min;
          this.end = this.max;
        }

        return ticks;
      }
    }, {
      key: "getLabelForValue",
      value: function getLabelForValue(value) {
        return value === undefined ? '0' : formatNumber(value, this.chart.options.locale, this.options.ticks.format);
      }
    }, {
      key: "configure",
      value: function configure() {
        var start = this.min;

        _get(_getPrototypeOf(LogarithmicScale.prototype), "configure", this).call(this);

        this._startValue = log10(start);
        this._valueRange = log10(this.max) - log10(start);
      }
    }, {
      key: "getPixelForValue",
      value: function getPixelForValue(value) {
        if (value === undefined || value === 0) {
          value = this.min;
        }

        if (value === null || isNaN(value)) {
          return NaN;
        }

        return this.getPixelForDecimal(value === this.min ? 0 : (log10(value) - this._startValue) / this._valueRange);
      }
    }, {
      key: "getValueForPixel",
      value: function getValueForPixel(pixel) {
        var decimal = this.getDecimalForPixel(pixel);
        return Math.pow(10, this._startValue + decimal * this._valueRange);
      }
    }]);

    return LogarithmicScale;
  }(Scale);

  LogarithmicScale.id = 'logarithmic';
  LogarithmicScale.defaults = {
    ticks: {
      callback: Ticks.formatters.logarithmic,
      major: {
        enabled: true
      }
    }
  };

  function getTickBackdropHeight(opts) {
    var tickOpts = opts.ticks;

    if (tickOpts.display && opts.display) {
      var padding = toPadding(tickOpts.backdropPadding);
      return valueOrDefault(tickOpts.font && tickOpts.font.size, defaults.font.size) + padding.height;
    }

    return 0;
  }

  function measureLabelSize(ctx, font, label) {
    label = isArray(label) ? label : [label];
    return {
      w: _longestText(ctx, font.string, label),
      h: label.length * font.lineHeight
    };
  }

  function determineLimits(angle, pos, size, min, max) {
    if (angle === min || angle === max) {
      return {
        start: pos - size / 2,
        end: pos + size / 2
      };
    } else if (angle < min || angle > max) {
      return {
        start: pos - size,
        end: pos
      };
    }

    return {
      start: pos,
      end: pos + size
    };
  }

  function fitWithPointLabels(scale) {
    var orig = {
      l: scale.left + scale._padding.left,
      r: scale.right - scale._padding.right,
      t: scale.top + scale._padding.top,
      b: scale.bottom - scale._padding.bottom
    };
    var limits = Object.assign({}, orig);
    var labelSizes = [];
    var padding = [];
    var valueCount = scale._pointLabels.length;
    var pointLabelOpts = scale.options.pointLabels;
    var additionalAngle = pointLabelOpts.centerPointLabels ? PI / valueCount : 0;

    for (var i = 0; i < valueCount; i++) {
      var opts = pointLabelOpts.setContext(scale.getPointLabelContext(i));
      padding[i] = opts.padding;
      var pointPosition = scale.getPointPosition(i, scale.drawingArea + padding[i], additionalAngle);
      var plFont = toFont(opts.font);
      var textSize = measureLabelSize(scale.ctx, plFont, scale._pointLabels[i]);
      labelSizes[i] = textSize;

      var angleRadians = _normalizeAngle(scale.getIndexAngle(i) + additionalAngle);

      var angle = Math.round(toDegrees(angleRadians));
      var hLimits = determineLimits(angle, pointPosition.x, textSize.w, 0, 180);
      var vLimits = determineLimits(angle, pointPosition.y, textSize.h, 90, 270);
      updateLimits(limits, orig, angleRadians, hLimits, vLimits);
    }

    scale.setCenterPoint(orig.l - limits.l, limits.r - orig.r, orig.t - limits.t, limits.b - orig.b);
    scale._pointLabelItems = buildPointLabelItems(scale, labelSizes, padding);
  }

  function updateLimits(limits, orig, angle, hLimits, vLimits) {
    var sin = Math.abs(Math.sin(angle));
    var cos = Math.abs(Math.cos(angle));
    var x = 0;
    var y = 0;

    if (hLimits.start < orig.l) {
      x = (orig.l - hLimits.start) / sin;
      limits.l = Math.min(limits.l, orig.l - x);
    } else if (hLimits.end > orig.r) {
      x = (hLimits.end - orig.r) / sin;
      limits.r = Math.max(limits.r, orig.r + x);
    }

    if (vLimits.start < orig.t) {
      y = (orig.t - vLimits.start) / cos;
      limits.t = Math.min(limits.t, orig.t - y);
    } else if (vLimits.end > orig.b) {
      y = (vLimits.end - orig.b) / cos;
      limits.b = Math.max(limits.b, orig.b + y);
    }
  }

  function buildPointLabelItems(scale, labelSizes, padding) {
    var items = [];
    var valueCount = scale._pointLabels.length;
    var opts = scale.options;
    var extra = getTickBackdropHeight(opts) / 2;
    var outerDistance = scale.drawingArea;
    var additionalAngle = opts.pointLabels.centerPointLabels ? PI / valueCount : 0;

    for (var i = 0; i < valueCount; i++) {
      var pointLabelPosition = scale.getPointPosition(i, outerDistance + extra + padding[i], additionalAngle);
      var angle = Math.round(toDegrees(_normalizeAngle(pointLabelPosition.angle + HALF_PI)));
      var size = labelSizes[i];
      var y = yForAngle(pointLabelPosition.y, size.h, angle);
      var textAlign = getTextAlignForAngle(angle);
      var left = leftForTextAlign(pointLabelPosition.x, size.w, textAlign);
      items.push({
        x: pointLabelPosition.x,
        y: y,
        textAlign: textAlign,
        left: left,
        top: y,
        right: left + size.w,
        bottom: y + size.h
      });
    }

    return items;
  }

  function getTextAlignForAngle(angle) {
    if (angle === 0 || angle === 180) {
      return 'center';
    } else if (angle < 180) {
      return 'left';
    }

    return 'right';
  }

  function leftForTextAlign(x, w, align) {
    if (align === 'right') {
      x -= w;
    } else if (align === 'center') {
      x -= w / 2;
    }

    return x;
  }

  function yForAngle(y, h, angle) {
    if (angle === 90 || angle === 270) {
      y -= h / 2;
    } else if (angle > 270 || angle < 90) {
      y -= h;
    }

    return y;
  }

  function drawPointLabels(scale, labelCount) {
    var ctx = scale.ctx,
        pointLabels = scale.options.pointLabels;

    for (var i = labelCount - 1; i >= 0; i--) {
      var optsAtIndex = pointLabels.setContext(scale.getPointLabelContext(i));
      var plFont = toFont(optsAtIndex.font);
      var _scale$_pointLabelIte = scale._pointLabelItems[i],
          x = _scale$_pointLabelIte.x,
          y = _scale$_pointLabelIte.y,
          textAlign = _scale$_pointLabelIte.textAlign,
          left = _scale$_pointLabelIte.left,
          top = _scale$_pointLabelIte.top,
          right = _scale$_pointLabelIte.right,
          bottom = _scale$_pointLabelIte.bottom;
      var backdropColor = optsAtIndex.backdropColor;

      if (!isNullOrUndef(backdropColor)) {
        var borderRadius = toTRBLCorners(optsAtIndex.borderRadius);
        var padding = toPadding(optsAtIndex.backdropPadding);
        ctx.fillStyle = backdropColor;
        var backdropLeft = left - padding.left;
        var backdropTop = top - padding.top;
        var backdropWidth = right - left + padding.width;
        var backdropHeight = bottom - top + padding.height;

        if (Object.values(borderRadius).some(function (v) {
          return v !== 0;
        })) {
          ctx.beginPath();
          addRoundedRectPath(ctx, {
            x: backdropLeft,
            y: backdropTop,
            w: backdropWidth,
            h: backdropHeight,
            radius: borderRadius
          });
          ctx.fill();
        } else {
          ctx.fillRect(backdropLeft, backdropTop, backdropWidth, backdropHeight);
        }
      }

      renderText(ctx, scale._pointLabels[i], x, y + plFont.lineHeight / 2, plFont, {
        color: optsAtIndex.color,
        textAlign: textAlign,
        textBaseline: 'middle'
      });
    }
  }

  function pathRadiusLine(scale, radius, circular, labelCount) {
    var ctx = scale.ctx;

    if (circular) {
      ctx.arc(scale.xCenter, scale.yCenter, radius, 0, TAU);
    } else {
      var pointPosition = scale.getPointPosition(0, radius);
      ctx.moveTo(pointPosition.x, pointPosition.y);

      for (var i = 1; i < labelCount; i++) {
        pointPosition = scale.getPointPosition(i, radius);
        ctx.lineTo(pointPosition.x, pointPosition.y);
      }
    }
  }

  function drawRadiusLine(scale, gridLineOpts, radius, labelCount) {
    var ctx = scale.ctx;
    var circular = gridLineOpts.circular;
    var color = gridLineOpts.color,
        lineWidth = gridLineOpts.lineWidth;

    if (!circular && !labelCount || !color || !lineWidth || radius < 0) {
      return;
    }

    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = lineWidth;
    ctx.setLineDash(gridLineOpts.borderDash);
    ctx.lineDashOffset = gridLineOpts.borderDashOffset;
    ctx.beginPath();
    pathRadiusLine(scale, radius, circular, labelCount);
    ctx.closePath();
    ctx.stroke();
    ctx.restore();
  }

  function createPointLabelContext(parent, index, label) {
    return createContext(parent, {
      label: label,
      index: index,
      type: 'pointLabel'
    });
  }

  var RadialLinearScale = /*#__PURE__*/function (_LinearScaleBase2) {
    _inherits(RadialLinearScale, _LinearScaleBase2);

    var _super23 = _createSuper(RadialLinearScale);

    function RadialLinearScale(cfg) {
      var _this38;

      _classCallCheck(this, RadialLinearScale);

      _this38 = _super23.call(this, cfg);
      _this38.xCenter = undefined;
      _this38.yCenter = undefined;
      _this38.drawingArea = undefined;
      _this38._pointLabels = [];
      _this38._pointLabelItems = [];
      return _this38;
    }

    _createClass(RadialLinearScale, [{
      key: "setDimensions",
      value: function setDimensions() {
        var padding = this._padding = toPadding(getTickBackdropHeight(this.options) / 2);
        var w = this.width = this.maxWidth - padding.width;
        var h = this.height = this.maxHeight - padding.height;
        this.xCenter = Math.floor(this.left + w / 2 + padding.left);
        this.yCenter = Math.floor(this.top + h / 2 + padding.top);
        this.drawingArea = Math.floor(Math.min(w, h) / 2);
      }
    }, {
      key: "determineDataLimits",
      value: function determineDataLimits() {
        var _this$getMinMax4 = this.getMinMax(false),
            min = _this$getMinMax4.min,
            max = _this$getMinMax4.max;

        this.min = isNumberFinite(min) && !isNaN(min) ? min : 0;
        this.max = isNumberFinite(max) && !isNaN(max) ? max : 0;
        this.handleTickRangeOptions();
      }
    }, {
      key: "computeTickLimit",
      value: function computeTickLimit() {
        return Math.ceil(this.drawingArea / getTickBackdropHeight(this.options));
      }
    }, {
      key: "generateTickLabels",
      value: function generateTickLabels(ticks) {
        var _this39 = this;

        LinearScaleBase.prototype.generateTickLabels.call(this, ticks);
        this._pointLabels = this.getLabels().map(function (value, index) {
          var label = callback(_this39.options.pointLabels.callback, [value, index], _this39);
          return label || label === 0 ? label : '';
        }).filter(function (v, i) {
          return _this39.chart.getDataVisibility(i);
        });
      }
    }, {
      key: "fit",
      value: function fit() {
        var opts = this.options;

        if (opts.display && opts.pointLabels.display) {
          fitWithPointLabels(this);
        } else {
          this.setCenterPoint(0, 0, 0, 0);
        }
      }
    }, {
      key: "setCenterPoint",
      value: function setCenterPoint(leftMovement, rightMovement, topMovement, bottomMovement) {
        this.xCenter += Math.floor((leftMovement - rightMovement) / 2);
        this.yCenter += Math.floor((topMovement - bottomMovement) / 2);
        this.drawingArea -= Math.min(this.drawingArea / 2, Math.max(leftMovement, rightMovement, topMovement, bottomMovement));
      }
    }, {
      key: "getIndexAngle",
      value: function getIndexAngle(index) {
        var angleMultiplier = TAU / (this._pointLabels.length || 1);
        var startAngle = this.options.startAngle || 0;
        return _normalizeAngle(index * angleMultiplier + toRadians(startAngle));
      }
    }, {
      key: "getDistanceFromCenterForValue",
      value: function getDistanceFromCenterForValue(value) {
        if (isNullOrUndef(value)) {
          return NaN;
        }

        var scalingFactor = this.drawingArea / (this.max - this.min);

        if (this.options.reverse) {
          return (this.max - value) * scalingFactor;
        }

        return (value - this.min) * scalingFactor;
      }
    }, {
      key: "getValueForDistanceFromCenter",
      value: function getValueForDistanceFromCenter(distance) {
        if (isNullOrUndef(distance)) {
          return NaN;
        }

        var scaledDistance = distance / (this.drawingArea / (this.max - this.min));
        return this.options.reverse ? this.max - scaledDistance : this.min + scaledDistance;
      }
    }, {
      key: "getPointLabelContext",
      value: function getPointLabelContext(index) {
        var pointLabels = this._pointLabels || [];

        if (index >= 0 && index < pointLabels.length) {
          var pointLabel = pointLabels[index];
          return createPointLabelContext(this.getContext(), index, pointLabel);
        }
      }
    }, {
      key: "getPointPosition",
      value: function getPointPosition(index, distanceFromCenter) {
        var additionalAngle = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
        var angle = this.getIndexAngle(index) - HALF_PI + additionalAngle;
        return {
          x: Math.cos(angle) * distanceFromCenter + this.xCenter,
          y: Math.sin(angle) * distanceFromCenter + this.yCenter,
          angle: angle
        };
      }
    }, {
      key: "getPointPositionForValue",
      value: function getPointPositionForValue(index, value) {
        return this.getPointPosition(index, this.getDistanceFromCenterForValue(value));
      }
    }, {
      key: "getBasePosition",
      value: function getBasePosition(index) {
        return this.getPointPositionForValue(index || 0, this.getBaseValue());
      }
    }, {
      key: "getPointLabelPosition",
      value: function getPointLabelPosition(index) {
        var _this$_pointLabelItem = this._pointLabelItems[index],
            left = _this$_pointLabelItem.left,
            top = _this$_pointLabelItem.top,
            right = _this$_pointLabelItem.right,
            bottom = _this$_pointLabelItem.bottom;
        return {
          left: left,
          top: top,
          right: right,
          bottom: bottom
        };
      }
    }, {
      key: "drawBackground",
      value: function drawBackground() {
        var _this$options15 = this.options,
            backgroundColor = _this$options15.backgroundColor,
            circular = _this$options15.grid.circular;

        if (backgroundColor) {
          var ctx = this.ctx;
          ctx.save();
          ctx.beginPath();
          pathRadiusLine(this, this.getDistanceFromCenterForValue(this._endValue), circular, this._pointLabels.length);
          ctx.closePath();
          ctx.fillStyle = backgroundColor;
          ctx.fill();
          ctx.restore();
        }
      }
    }, {
      key: "drawGrid",
      value: function drawGrid() {
        var _this40 = this;

        var ctx = this.ctx;
        var opts = this.options;
        var angleLines = opts.angleLines,
            grid = opts.grid;
        var labelCount = this._pointLabels.length;
        var i, offset, position;

        if (opts.pointLabels.display) {
          drawPointLabels(this, labelCount);
        }

        if (grid.display) {
          this.ticks.forEach(function (tick, index) {
            if (index !== 0) {
              offset = _this40.getDistanceFromCenterForValue(tick.value);
              var optsAtIndex = grid.setContext(_this40.getContext(index - 1));
              drawRadiusLine(_this40, optsAtIndex, offset, labelCount);
            }
          });
        }

        if (angleLines.display) {
          ctx.save();

          for (i = labelCount - 1; i >= 0; i--) {
            var optsAtIndex = angleLines.setContext(this.getPointLabelContext(i));
            var color = optsAtIndex.color,
                lineWidth = optsAtIndex.lineWidth;

            if (!lineWidth || !color) {
              continue;
            }

            ctx.lineWidth = lineWidth;
            ctx.strokeStyle = color;
            ctx.setLineDash(optsAtIndex.borderDash);
            ctx.lineDashOffset = optsAtIndex.borderDashOffset;
            offset = this.getDistanceFromCenterForValue(opts.ticks.reverse ? this.min : this.max);
            position = this.getPointPosition(i, offset);
            ctx.beginPath();
            ctx.moveTo(this.xCenter, this.yCenter);
            ctx.lineTo(position.x, position.y);
            ctx.stroke();
          }

          ctx.restore();
        }
      }
    }, {
      key: "drawBorder",
      value: function drawBorder() {}
    }, {
      key: "drawLabels",
      value: function drawLabels() {
        var _this41 = this;

        var ctx = this.ctx;
        var opts = this.options;
        var tickOpts = opts.ticks;

        if (!tickOpts.display) {
          return;
        }

        var startAngle = this.getIndexAngle(0);
        var offset, width;
        ctx.save();
        ctx.translate(this.xCenter, this.yCenter);
        ctx.rotate(startAngle);
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        this.ticks.forEach(function (tick, index) {
          if (index === 0 && !opts.reverse) {
            return;
          }

          var optsAtIndex = tickOpts.setContext(_this41.getContext(index));
          var tickFont = toFont(optsAtIndex.font);
          offset = _this41.getDistanceFromCenterForValue(_this41.ticks[index].value);

          if (optsAtIndex.showLabelBackdrop) {
            ctx.font = tickFont.string;
            width = ctx.measureText(tick.label).width;
            ctx.fillStyle = optsAtIndex.backdropColor;
            var padding = toPadding(optsAtIndex.backdropPadding);
            ctx.fillRect(-width / 2 - padding.left, -offset - tickFont.size / 2 - padding.top, width + padding.width, tickFont.size + padding.height);
          }

          renderText(ctx, tick.label, 0, -offset, tickFont, {
            color: optsAtIndex.color
          });
        });
        ctx.restore();
      }
    }, {
      key: "drawTitle",
      value: function drawTitle() {}
    }]);

    return RadialLinearScale;
  }(LinearScaleBase);

  RadialLinearScale.id = 'radialLinear';
  RadialLinearScale.defaults = {
    display: true,
    animate: true,
    position: 'chartArea',
    angleLines: {
      display: true,
      lineWidth: 1,
      borderDash: [],
      borderDashOffset: 0.0
    },
    grid: {
      circular: false
    },
    startAngle: 0,
    ticks: {
      showLabelBackdrop: true,
      callback: Ticks.formatters.numeric
    },
    pointLabels: {
      backdropColor: undefined,
      backdropPadding: 2,
      display: true,
      font: {
        size: 10
      },
      callback: function callback(label) {
        return label;
      },
      padding: 5,
      centerPointLabels: false
    }
  };
  RadialLinearScale.defaultRoutes = {
    'angleLines.color': 'borderColor',
    'pointLabels.color': 'color',
    'ticks.color': 'color'
  };
  RadialLinearScale.descriptors = {
    angleLines: {
      _fallback: 'grid'
    }
  };
  var INTERVALS = {
    millisecond: {
      common: true,
      size: 1,
      steps: 1000
    },
    second: {
      common: true,
      size: 1000,
      steps: 60
    },
    minute: {
      common: true,
      size: 60000,
      steps: 60
    },
    hour: {
      common: true,
      size: 3600000,
      steps: 24
    },
    day: {
      common: true,
      size: 86400000,
      steps: 30
    },
    week: {
      common: false,
      size: 604800000,
      steps: 4
    },
    month: {
      common: true,
      size: 2.628e9,
      steps: 12
    },
    quarter: {
      common: false,
      size: 7.884e9,
      steps: 4
    },
    year: {
      common: true,
      size: 3.154e10
    }
  };
  var UNITS = Object.keys(INTERVALS);

  function sorter(a, b) {
    return a - b;
  }

  function _parse(scale, input) {
    if (isNullOrUndef(input)) {
      return null;
    }

    var adapter = scale._adapter;
    var _scale$_parseOpts = scale._parseOpts,
        parser = _scale$_parseOpts.parser,
        round = _scale$_parseOpts.round,
        isoWeekday = _scale$_parseOpts.isoWeekday;
    var value = input;

    if (typeof parser === 'function') {
      value = parser(value);
    }

    if (!isNumberFinite(value)) {
      value = typeof parser === 'string' ? adapter.parse(value, parser) : adapter.parse(value);
    }

    if (value === null) {
      return null;
    }

    if (round) {
      value = round === 'week' && (isNumber(isoWeekday) || isoWeekday === true) ? adapter.startOf(value, 'isoWeek', isoWeekday) : adapter.startOf(value, round);
    }

    return +value;
  }

  function determineUnitForAutoTicks(minUnit, min, max, capacity) {
    var ilen = UNITS.length;

    for (var i = UNITS.indexOf(minUnit); i < ilen - 1; ++i) {
      var interval = INTERVALS[UNITS[i]];
      var factor = interval.steps ? interval.steps : Number.MAX_SAFE_INTEGER;

      if (interval.common && Math.ceil((max - min) / (factor * interval.size)) <= capacity) {
        return UNITS[i];
      }
    }

    return UNITS[ilen - 1];
  }

  function determineUnitForFormatting(scale, numTicks, minUnit, min, max) {
    for (var i = UNITS.length - 1; i >= UNITS.indexOf(minUnit); i--) {
      var unit = UNITS[i];

      if (INTERVALS[unit].common && scale._adapter.diff(max, min, unit) >= numTicks - 1) {
        return unit;
      }
    }

    return UNITS[minUnit ? UNITS.indexOf(minUnit) : 0];
  }

  function determineMajorUnit(unit) {
    for (var i = UNITS.indexOf(unit) + 1, ilen = UNITS.length; i < ilen; ++i) {
      if (INTERVALS[UNITS[i]].common) {
        return UNITS[i];
      }
    }
  }

  function addTick(ticks, time, timestamps) {
    if (!timestamps) {
      ticks[time] = true;
    } else if (timestamps.length) {
      var _lookup2 = _lookup(timestamps, time),
          lo = _lookup2.lo,
          hi = _lookup2.hi;

      var timestamp = timestamps[lo] >= time ? timestamps[lo] : timestamps[hi];
      ticks[timestamp] = true;
    }
  }

  function setMajorTicks(scale, ticks, map, majorUnit) {
    var adapter = scale._adapter;
    var first = +adapter.startOf(ticks[0].value, majorUnit);
    var last = ticks[ticks.length - 1].value;
    var major, index;

    for (major = first; major <= last; major = +adapter.add(major, 1, majorUnit)) {
      index = map[major];

      if (index >= 0) {
        ticks[index].major = true;
      }
    }

    return ticks;
  }

  function ticksFromTimestamps(scale, values, majorUnit) {
    var ticks = [];
    var map = {};
    var ilen = values.length;
    var i, value;

    for (i = 0; i < ilen; ++i) {
      value = values[i];
      map[value] = i;
      ticks.push({
        value: value,
        major: false
      });
    }

    return ilen === 0 || !majorUnit ? ticks : setMajorTicks(scale, ticks, map, majorUnit);
  }

  var TimeScale = /*#__PURE__*/function (_Scale4) {
    _inherits(TimeScale, _Scale4);

    var _super24 = _createSuper(TimeScale);

    function TimeScale(props) {
      var _this42;

      _classCallCheck(this, TimeScale);

      _this42 = _super24.call(this, props);
      _this42._cache = {
        data: [],
        labels: [],
        all: []
      };
      _this42._unit = 'day';
      _this42._majorUnit = undefined;
      _this42._offsets = {};
      _this42._normalized = false;
      _this42._parseOpts = undefined;
      return _this42;
    }

    _createClass(TimeScale, [{
      key: "init",
      value: function init(scaleOpts, opts) {
        var time = scaleOpts.time || (scaleOpts.time = {});
        var adapter = this._adapter = new adapters._date(scaleOpts.adapters.date);
        adapter.init(opts);
        mergeIf(time.displayFormats, adapter.formats());
        this._parseOpts = {
          parser: time.parser,
          round: time.round,
          isoWeekday: time.isoWeekday
        };

        _get(_getPrototypeOf(TimeScale.prototype), "init", this).call(this, scaleOpts);

        this._normalized = opts.normalized;
      }
    }, {
      key: "parse",
      value: function parse(raw, index) {
        if (raw === undefined) {
          return null;
        }

        return _parse(this, raw);
      }
    }, {
      key: "beforeLayout",
      value: function beforeLayout() {
        _get(_getPrototypeOf(TimeScale.prototype), "beforeLayout", this).call(this);

        this._cache = {
          data: [],
          labels: [],
          all: []
        };
      }
    }, {
      key: "determineDataLimits",
      value: function determineDataLimits() {
        var options = this.options;
        var adapter = this._adapter;
        var unit = options.time.unit || 'day';

        var _this$getUserBounds5 = this.getUserBounds(),
            min = _this$getUserBounds5.min,
            max = _this$getUserBounds5.max,
            minDefined = _this$getUserBounds5.minDefined,
            maxDefined = _this$getUserBounds5.maxDefined;

        function _applyBounds(bounds) {
          if (!minDefined && !isNaN(bounds.min)) {
            min = Math.min(min, bounds.min);
          }

          if (!maxDefined && !isNaN(bounds.max)) {
            max = Math.max(max, bounds.max);
          }
        }

        if (!minDefined || !maxDefined) {
          _applyBounds(this._getLabelBounds());

          if (options.bounds !== 'ticks' || options.ticks.source !== 'labels') {
            _applyBounds(this.getMinMax(false));
          }
        }

        min = isNumberFinite(min) && !isNaN(min) ? min : +adapter.startOf(Date.now(), unit);
        max = isNumberFinite(max) && !isNaN(max) ? max : +adapter.endOf(Date.now(), unit) + 1;
        this.min = Math.min(min, max - 1);
        this.max = Math.max(min + 1, max);
      }
    }, {
      key: "_getLabelBounds",
      value: function _getLabelBounds() {
        var arr = this.getLabelTimestamps();
        var min = Number.POSITIVE_INFINITY;
        var max = Number.NEGATIVE_INFINITY;

        if (arr.length) {
          min = arr[0];
          max = arr[arr.length - 1];
        }

        return {
          min: min,
          max: max
        };
      }
    }, {
      key: "buildTicks",
      value: function buildTicks() {
        var options = this.options;
        var timeOpts = options.time;
        var tickOpts = options.ticks;
        var timestamps = tickOpts.source === 'labels' ? this.getLabelTimestamps() : this._generate();

        if (options.bounds === 'ticks' && timestamps.length) {
          this.min = this._userMin || timestamps[0];
          this.max = this._userMax || timestamps[timestamps.length - 1];
        }

        var min = this.min;
        var max = this.max;

        var ticks = _filterBetween(timestamps, min, max);

        this._unit = timeOpts.unit || (tickOpts.autoSkip ? determineUnitForAutoTicks(timeOpts.minUnit, this.min, this.max, this._getLabelCapacity(min)) : determineUnitForFormatting(this, ticks.length, timeOpts.minUnit, this.min, this.max));
        this._majorUnit = !tickOpts.major.enabled || this._unit === 'year' ? undefined : determineMajorUnit(this._unit);
        this.initOffsets(timestamps);

        if (options.reverse) {
          ticks.reverse();
        }

        return ticksFromTimestamps(this, ticks, this._majorUnit);
      }
    }, {
      key: "afterAutoSkip",
      value: function afterAutoSkip() {
        if (this.options.offsetAfterAutoskip) {
          this.initOffsets(this.ticks.map(function (tick) {
            return +tick.value;
          }));
        }
      }
    }, {
      key: "initOffsets",
      value: function initOffsets(timestamps) {
        var start = 0;
        var end = 0;
        var first, last;

        if (this.options.offset && timestamps.length) {
          first = this.getDecimalForValue(timestamps[0]);

          if (timestamps.length === 1) {
            start = 1 - first;
          } else {
            start = (this.getDecimalForValue(timestamps[1]) - first) / 2;
          }

          last = this.getDecimalForValue(timestamps[timestamps.length - 1]);

          if (timestamps.length === 1) {
            end = last;
          } else {
            end = (last - this.getDecimalForValue(timestamps[timestamps.length - 2])) / 2;
          }
        }

        var limit = timestamps.length < 3 ? 0.5 : 0.25;
        start = _limitValue(start, 0, limit);
        end = _limitValue(end, 0, limit);
        this._offsets = {
          start: start,
          end: end,
          factor: 1 / (start + 1 + end)
        };
      }
    }, {
      key: "_generate",
      value: function _generate() {
        var adapter = this._adapter;
        var min = this.min;
        var max = this.max;
        var options = this.options;
        var timeOpts = options.time;
        var minor = timeOpts.unit || determineUnitForAutoTicks(timeOpts.minUnit, min, max, this._getLabelCapacity(min));
        var stepSize = valueOrDefault(timeOpts.stepSize, 1);
        var weekday = minor === 'week' ? timeOpts.isoWeekday : false;
        var hasWeekday = isNumber(weekday) || weekday === true;
        var ticks = {};
        var first = min;
        var time, count;

        if (hasWeekday) {
          first = +adapter.startOf(first, 'isoWeek', weekday);
        }

        first = +adapter.startOf(first, hasWeekday ? 'day' : minor);

        if (adapter.diff(max, min, minor) > 100000 * stepSize) {
          throw new Error(min + ' and ' + max + ' are too far apart with stepSize of ' + stepSize + ' ' + minor);
        }

        var timestamps = options.ticks.source === 'data' && this.getDataTimestamps();

        for (time = first, count = 0; time < max; time = +adapter.add(time, stepSize, minor), count++) {
          addTick(ticks, time, timestamps);
        }

        if (time === max || options.bounds === 'ticks' || count === 1) {
          addTick(ticks, time, timestamps);
        }

        return Object.keys(ticks).sort(function (a, b) {
          return a - b;
        }).map(function (x) {
          return +x;
        });
      }
    }, {
      key: "getLabelForValue",
      value: function getLabelForValue(value) {
        var adapter = this._adapter;
        var timeOpts = this.options.time;

        if (timeOpts.tooltipFormat) {
          return adapter.format(value, timeOpts.tooltipFormat);
        }

        return adapter.format(value, timeOpts.displayFormats.datetime);
      }
    }, {
      key: "_tickFormatFunction",
      value: function _tickFormatFunction(time, index, ticks, format) {
        var options = this.options;
        var formats = options.time.displayFormats;
        var unit = this._unit;
        var majorUnit = this._majorUnit;
        var minorFormat = unit && formats[unit];
        var majorFormat = majorUnit && formats[majorUnit];
        var tick = ticks[index];
        var major = majorUnit && majorFormat && tick && tick.major;

        var label = this._adapter.format(time, format || (major ? majorFormat : minorFormat));

        var formatter = options.ticks.callback;
        return formatter ? callback(formatter, [label, index, ticks], this) : label;
      }
    }, {
      key: "generateTickLabels",
      value: function generateTickLabels(ticks) {
        var i, ilen, tick;

        for (i = 0, ilen = ticks.length; i < ilen; ++i) {
          tick = ticks[i];
          tick.label = this._tickFormatFunction(tick.value, i, ticks);
        }
      }
    }, {
      key: "getDecimalForValue",
      value: function getDecimalForValue(value) {
        return value === null ? NaN : (value - this.min) / (this.max - this.min);
      }
    }, {
      key: "getPixelForValue",
      value: function getPixelForValue(value) {
        var offsets = this._offsets;
        var pos = this.getDecimalForValue(value);
        return this.getPixelForDecimal((offsets.start + pos) * offsets.factor);
      }
    }, {
      key: "getValueForPixel",
      value: function getValueForPixel(pixel) {
        var offsets = this._offsets;
        var pos = this.getDecimalForPixel(pixel) / offsets.factor - offsets.end;
        return this.min + pos * (this.max - this.min);
      }
    }, {
      key: "_getLabelSize",
      value: function _getLabelSize(label) {
        var ticksOpts = this.options.ticks;
        var tickLabelWidth = this.ctx.measureText(label).width;
        var angle = toRadians(this.isHorizontal() ? ticksOpts.maxRotation : ticksOpts.minRotation);
        var cosRotation = Math.cos(angle);
        var sinRotation = Math.sin(angle);

        var tickFontSize = this._resolveTickFontOptions(0).size;

        return {
          w: tickLabelWidth * cosRotation + tickFontSize * sinRotation,
          h: tickLabelWidth * sinRotation + tickFontSize * cosRotation
        };
      }
    }, {
      key: "_getLabelCapacity",
      value: function _getLabelCapacity(exampleTime) {
        var timeOpts = this.options.time;
        var displayFormats = timeOpts.displayFormats;
        var format = displayFormats[timeOpts.unit] || displayFormats.millisecond;

        var exampleLabel = this._tickFormatFunction(exampleTime, 0, ticksFromTimestamps(this, [exampleTime], this._majorUnit), format);

        var size = this._getLabelSize(exampleLabel);

        var capacity = Math.floor(this.isHorizontal() ? this.width / size.w : this.height / size.h) - 1;
        return capacity > 0 ? capacity : 1;
      }
    }, {
      key: "getDataTimestamps",
      value: function getDataTimestamps() {
        var timestamps = this._cache.data || [];
        var i, ilen;

        if (timestamps.length) {
          return timestamps;
        }

        var metas = this.getMatchingVisibleMetas();

        if (this._normalized && metas.length) {
          return this._cache.data = metas[0].controller.getAllParsedValues(this);
        }

        for (i = 0, ilen = metas.length; i < ilen; ++i) {
          timestamps = timestamps.concat(metas[i].controller.getAllParsedValues(this));
        }

        return this._cache.data = this.normalize(timestamps);
      }
    }, {
      key: "getLabelTimestamps",
      value: function getLabelTimestamps() {
        var timestamps = this._cache.labels || [];
        var i, ilen;

        if (timestamps.length) {
          return timestamps;
        }

        var labels = this.getLabels();

        for (i = 0, ilen = labels.length; i < ilen; ++i) {
          timestamps.push(_parse(this, labels[i]));
        }

        return this._cache.labels = this._normalized ? timestamps : this.normalize(timestamps);
      }
    }, {
      key: "normalize",
      value: function normalize(values) {
        return _arrayUnique(values.sort(sorter));
      }
    }]);

    return TimeScale;
  }(Scale);

  TimeScale.id = 'time';
  TimeScale.defaults = {
    bounds: 'data',
    adapters: {},
    time: {
      parser: false,
      unit: false,
      round: false,
      isoWeekday: false,
      minUnit: 'millisecond',
      displayFormats: {}
    },
    ticks: {
      source: 'auto',
      major: {
        enabled: false
      }
    }
  };

  function interpolate(table, val, reverse) {
    var lo = 0;
    var hi = table.length - 1;
    var prevSource, nextSource, prevTarget, nextTarget;

    if (reverse) {
      if (val >= table[lo].pos && val <= table[hi].pos) {
        var _lookupByKey2 = _lookupByKey(table, 'pos', val);

        lo = _lookupByKey2.lo;
        hi = _lookupByKey2.hi;
      }

      var _table$lo = table[lo];
      prevSource = _table$lo.pos;
      prevTarget = _table$lo.time;
      var _table$hi = table[hi];
      nextSource = _table$hi.pos;
      nextTarget = _table$hi.time;
    } else {
      if (val >= table[lo].time && val <= table[hi].time) {
        var _lookupByKey3 = _lookupByKey(table, 'time', val);

        lo = _lookupByKey3.lo;
        hi = _lookupByKey3.hi;
      }

      var _table$lo2 = table[lo];
      prevSource = _table$lo2.time;
      prevTarget = _table$lo2.pos;
      var _table$hi2 = table[hi];
      nextSource = _table$hi2.time;
      nextTarget = _table$hi2.pos;
    }

    var span = nextSource - prevSource;
    return span ? prevTarget + (nextTarget - prevTarget) * (val - prevSource) / span : prevTarget;
  }

  var TimeSeriesScale = /*#__PURE__*/function (_TimeScale) {
    _inherits(TimeSeriesScale, _TimeScale);

    var _super25 = _createSuper(TimeSeriesScale);

    function TimeSeriesScale(props) {
      var _this43;

      _classCallCheck(this, TimeSeriesScale);

      _this43 = _super25.call(this, props);
      _this43._table = [];
      _this43._minPos = undefined;
      _this43._tableRange = undefined;
      return _this43;
    }

    _createClass(TimeSeriesScale, [{
      key: "initOffsets",
      value: function initOffsets() {
        var timestamps = this._getTimestampsForTable();

        var table = this._table = this.buildLookupTable(timestamps);
        this._minPos = interpolate(table, this.min);
        this._tableRange = interpolate(table, this.max) - this._minPos;

        _get(_getPrototypeOf(TimeSeriesScale.prototype), "initOffsets", this).call(this, timestamps);
      }
    }, {
      key: "buildLookupTable",
      value: function buildLookupTable(timestamps) {
        var min = this.min,
            max = this.max;
        var items = [];
        var table = [];
        var i, ilen, prev, curr, next;

        for (i = 0, ilen = timestamps.length; i < ilen; ++i) {
          curr = timestamps[i];

          if (curr >= min && curr <= max) {
            items.push(curr);
          }
        }

        if (items.length < 2) {
          return [{
            time: min,
            pos: 0
          }, {
            time: max,
            pos: 1
          }];
        }

        for (i = 0, ilen = items.length; i < ilen; ++i) {
          next = items[i + 1];
          prev = items[i - 1];
          curr = items[i];

          if (Math.round((next + prev) / 2) !== curr) {
            table.push({
              time: curr,
              pos: i / (ilen - 1)
            });
          }
        }

        return table;
      }
    }, {
      key: "_getTimestampsForTable",
      value: function _getTimestampsForTable() {
        var timestamps = this._cache.all || [];

        if (timestamps.length) {
          return timestamps;
        }

        var data = this.getDataTimestamps();
        var label = this.getLabelTimestamps();

        if (data.length && label.length) {
          timestamps = this.normalize(data.concat(label));
        } else {
          timestamps = data.length ? data : label;
        }

        timestamps = this._cache.all = timestamps;
        return timestamps;
      }
    }, {
      key: "getDecimalForValue",
      value: function getDecimalForValue(value) {
        return (interpolate(this._table, value) - this._minPos) / this._tableRange;
      }
    }, {
      key: "getValueForPixel",
      value: function getValueForPixel(pixel) {
        var offsets = this._offsets;
        var decimal = this.getDecimalForPixel(pixel) / offsets.factor - offsets.end;
        return interpolate(this._table, decimal * this._tableRange + this._minPos, true);
      }
    }]);

    return TimeSeriesScale;
  }(TimeScale);

  TimeSeriesScale.id = 'timeseries';
  TimeSeriesScale.defaults = TimeScale.defaults;
  var scales = /*#__PURE__*/Object.freeze({
    __proto__: null,
    CategoryScale: CategoryScale,
    LinearScale: LinearScale,
    LogarithmicScale: LogarithmicScale,
    RadialLinearScale: RadialLinearScale,
    TimeScale: TimeScale,
    TimeSeriesScale: TimeSeriesScale
  });
  var registerables = [controllers, elements, plugins, scales];

  Chart.register.apply(Chart, _toConsumableArray(registerables));

  function toInteger(dirtyNumber) {
    if (dirtyNumber === null || dirtyNumber === true || dirtyNumber === false) {
      return NaN;
    }

    var number = Number(dirtyNumber);

    if (isNaN(number)) {
      return number;
    }

    return number < 0 ? Math.ceil(number) : Math.floor(number);
  }

  function requiredArgs(required, args) {
    if (args.length < required) {
      throw new TypeError(required + ' argument' + (required > 1 ? 's' : '') + ' required, but only ' + args.length + ' present');
    }
  }

  /**
   * @name toDate
   * @category Common Helpers
   * @summary Convert the given argument to an instance of Date.
   *
   * @description
   * Convert the given argument to an instance of Date.
   *
   * If the argument is an instance of Date, the function returns its clone.
   *
   * If the argument is a number, it is treated as a timestamp.
   *
   * If the argument is none of the above, the function returns Invalid Date.
   *
   * **Note**: *all* Date arguments passed to any *date-fns* function is processed by `toDate`.
   *
   * @param {Date|Number} argument - the value to convert
   * @returns {Date} the parsed date in the local time zone
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // Clone the date:
   * const result = toDate(new Date(2014, 1, 11, 11, 30, 30))
   * //=> Tue Feb 11 2014 11:30:30
   *
   * @example
   * // Convert the timestamp to date:
   * const result = toDate(1392098430000)
   * //=> Tue Feb 11 2014 11:30:30
   */

  function toDate(argument) {
    requiredArgs(1, arguments);
    var argStr = Object.prototype.toString.call(argument); // Clone the date

    if (argument instanceof Date || _typeof(argument) === 'object' && argStr === '[object Date]') {
      // Prevent the date to lose the milliseconds when passed to new Date() in IE10
      return new Date(argument.getTime());
    } else if (typeof argument === 'number' || argStr === '[object Number]') {
      return new Date(argument);
    } else {
      if ((typeof argument === 'string' || argStr === '[object String]') && typeof console !== 'undefined') {
        // eslint-disable-next-line no-console
        console.warn("Starting with v2.0.0-beta.1 date-fns doesn't accept strings as date arguments. Please use `parseISO` to parse strings. See: https://github.com/date-fns/date-fns/blob/master/docs/upgradeGuide.md#string-arguments"); // eslint-disable-next-line no-console

        console.warn(new Error().stack);
      }

      return new Date(NaN);
    }
  }

  /**
   * @name addDays
   * @category Day Helpers
   * @summary Add the specified number of days to the given date.
   *
   * @description
   * Add the specified number of days to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of days to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} - the new date with the days added
   * @throws {TypeError} - 2 arguments required
   *
   * @example
   * // Add 10 days to 1 September 2014:
   * const result = addDays(new Date(2014, 8, 1), 10)
   * //=> Thu Sep 11 2014 00:00:00
   */

  function addDays(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var date = toDate(dirtyDate);
    var amount = toInteger(dirtyAmount);

    if (isNaN(amount)) {
      return new Date(NaN);
    }

    if (!amount) {
      // If 0 days, no-op to avoid changing times in the hour before end of DST
      return date;
    }

    date.setDate(date.getDate() + amount);
    return date;
  }

  /**
   * @name addMonths
   * @category Month Helpers
   * @summary Add the specified number of months to the given date.
   *
   * @description
   * Add the specified number of months to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of months to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the months added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 5 months to 1 September 2014:
   * const result = addMonths(new Date(2014, 8, 1), 5)
   * //=> Sun Feb 01 2015 00:00:00
   */

  function addMonths(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var date = toDate(dirtyDate);
    var amount = toInteger(dirtyAmount);

    if (isNaN(amount)) {
      return new Date(NaN);
    }

    if (!amount) {
      // If 0 months, no-op to avoid changing times in the hour before end of DST
      return date;
    }

    var dayOfMonth = date.getDate(); // The JS Date object supports date math by accepting out-of-bounds values for
    // month, day, etc. For example, new Date(2020, 0, 0) returns 31 Dec 2019 and
    // new Date(2020, 13, 1) returns 1 Feb 2021.  This is *almost* the behavior we
    // want except that dates will wrap around the end of a month, meaning that
    // new Date(2020, 13, 31) will return 3 Mar 2021 not 28 Feb 2021 as desired. So
    // we'll default to the end of the desired month by adding 1 to the desired
    // month and using a date of 0 to back up one day to the end of the desired
    // month.

    var endOfDesiredMonth = new Date(date.getTime());
    endOfDesiredMonth.setMonth(date.getMonth() + amount + 1, 0);
    var daysInMonth = endOfDesiredMonth.getDate();

    if (dayOfMonth >= daysInMonth) {
      // If we're already at the end of the month, then this is the correct date
      // and we're done.
      return endOfDesiredMonth;
    } else {
      // Otherwise, we now know that setting the original day-of-month value won't
      // cause an overflow, so set the desired day-of-month. Note that we can't
      // just set the date of `endOfDesiredMonth` because that object may have had
      // its time changed in the unusual case where where a DST transition was on
      // the last day of the month and its local time was in the hour skipped or
      // repeated next to a DST transition.  So we use `date` instead which is
      // guaranteed to still have the original time.
      date.setFullYear(endOfDesiredMonth.getFullYear(), endOfDesiredMonth.getMonth(), dayOfMonth);
      return date;
    }
  }

  /**
   * @name addMilliseconds
   * @category Millisecond Helpers
   * @summary Add the specified number of milliseconds to the given date.
   *
   * @description
   * Add the specified number of milliseconds to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of milliseconds to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the milliseconds added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 750 milliseconds to 10 July 2014 12:45:30.000:
   * const result = addMilliseconds(new Date(2014, 6, 10, 12, 45, 30, 0), 750)
   * //=> Thu Jul 10 2014 12:45:30.750
   */

  function addMilliseconds(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var timestamp = toDate(dirtyDate).getTime();
    var amount = toInteger(dirtyAmount);
    return new Date(timestamp + amount);
  }

  var MILLISECONDS_IN_HOUR = 3600000;
  /**
   * @name addHours
   * @category Hour Helpers
   * @summary Add the specified number of hours to the given date.
   *
   * @description
   * Add the specified number of hours to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of hours to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the hours added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 2 hours to 10 July 2014 23:00:00:
   * const result = addHours(new Date(2014, 6, 10, 23, 0), 2)
   * //=> Fri Jul 11 2014 01:00:00
   */

  function addHours(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    return addMilliseconds(dirtyDate, amount * MILLISECONDS_IN_HOUR);
  }

  var defaultOptions = {};
  function getDefaultOptions() {
    return defaultOptions;
  }

  /**
   * @name startOfWeek
   * @category Week Helpers
   * @summary Return the start of a week for the given date.
   *
   * @description
   * Return the start of a week for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @param {Object} [options] - an object with options.
   * @param {Locale} [options.locale=defaultLocale] - the locale object. See [Locale]{@link https://date-fns.org/docs/Locale}
   * @param {0|1|2|3|4|5|6} [options.weekStartsOn=0] - the index of the first day of the week (0 - Sunday)
   * @returns {Date} the start of a week
   * @throws {TypeError} 1 argument required
   * @throws {RangeError} `options.weekStartsOn` must be between 0 and 6
   *
   * @example
   * // The start of a week for 2 September 2014 11:55:00:
   * const result = startOfWeek(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Sun Aug 31 2014 00:00:00
   *
   * @example
   * // If the week starts on Monday, the start of the week for 2 September 2014 11:55:00:
   * const result = startOfWeek(new Date(2014, 8, 2, 11, 55, 0), { weekStartsOn: 1 })
   * //=> Mon Sep 01 2014 00:00:00
   */

  function startOfWeek(dirtyDate, options) {
    var _ref, _ref2, _ref3, _options$weekStartsOn, _options$locale, _options$locale$optio, _defaultOptions$local, _defaultOptions$local2;

    requiredArgs(1, arguments);
    var defaultOptions = getDefaultOptions();
    var weekStartsOn = toInteger((_ref = (_ref2 = (_ref3 = (_options$weekStartsOn = options === null || options === void 0 ? void 0 : options.weekStartsOn) !== null && _options$weekStartsOn !== void 0 ? _options$weekStartsOn : options === null || options === void 0 ? void 0 : (_options$locale = options.locale) === null || _options$locale === void 0 ? void 0 : (_options$locale$optio = _options$locale.options) === null || _options$locale$optio === void 0 ? void 0 : _options$locale$optio.weekStartsOn) !== null && _ref3 !== void 0 ? _ref3 : defaultOptions.weekStartsOn) !== null && _ref2 !== void 0 ? _ref2 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.weekStartsOn) !== null && _ref !== void 0 ? _ref : 0); // Test if weekStartsOn is between 0 and 6 _and_ is not NaN

    if (!(weekStartsOn >= 0 && weekStartsOn <= 6)) {
      throw new RangeError('weekStartsOn must be between 0 and 6 inclusively');
    }

    var date = toDate(dirtyDate);
    var day = date.getDay();
    var diff = (day < weekStartsOn ? 7 : 0) + day - weekStartsOn;
    date.setDate(date.getDate() - diff);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  /**
   * Google Chrome as of 67.0.3396.87 introduced timezones with offset that includes seconds.
   * They usually appear for dates that denote time before the timezones were introduced
   * (e.g. for 'Europe/Prague' timezone the offset is GMT+00:57:44 before 1 October 1891
   * and GMT+01:00:00 after that date)
   *
   * Date#getTimezoneOffset returns the offset in minutes and would return 57 for the example above,
   * which would lead to incorrect calculations.
   *
   * This function returns the timezone offset in milliseconds that takes seconds in account.
   */
  function getTimezoneOffsetInMilliseconds(date) {
    var utcDate = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds(), date.getMilliseconds()));
    utcDate.setUTCFullYear(date.getFullYear());
    return date.getTime() - utcDate.getTime();
  }

  /**
   * @name startOfDay
   * @category Day Helpers
   * @summary Return the start of a day for the given date.
   *
   * @description
   * Return the start of a day for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of a day
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of a day for 2 September 2014 11:55:00:
   * const result = startOfDay(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Tue Sep 02 2014 00:00:00
   */

  function startOfDay(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  var MILLISECONDS_IN_DAY$1 = 86400000;
  /**
   * @name differenceInCalendarDays
   * @category Day Helpers
   * @summary Get the number of calendar days between the given dates.
   *
   * @description
   * Get the number of calendar days between the given dates. This means that the times are removed
   * from the dates and then the difference in days is calculated.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of calendar days
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many calendar days are between
   * // 2 July 2011 23:00:00 and 2 July 2012 00:00:00?
   * const result = differenceInCalendarDays(
   *   new Date(2012, 6, 2, 0, 0),
   *   new Date(2011, 6, 2, 23, 0)
   * )
   * //=> 366
   * // How many calendar days are between
   * // 2 July 2011 23:59:00 and 3 July 2011 00:01:00?
   * const result = differenceInCalendarDays(
   *   new Date(2011, 6, 3, 0, 1),
   *   new Date(2011, 6, 2, 23, 59)
   * )
   * //=> 1
   */

  function differenceInCalendarDays(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var startOfDayLeft = startOfDay(dirtyDateLeft);
    var startOfDayRight = startOfDay(dirtyDateRight);
    var timestampLeft = startOfDayLeft.getTime() - getTimezoneOffsetInMilliseconds(startOfDayLeft);
    var timestampRight = startOfDayRight.getTime() - getTimezoneOffsetInMilliseconds(startOfDayRight); // Round the number of days to the nearest integer
    // because the number of milliseconds in a day is not constant
    // (e.g. it's different in the day of the daylight saving time clock shift)

    return Math.round((timestampLeft - timestampRight) / MILLISECONDS_IN_DAY$1);
  }

  var MILLISECONDS_IN_MINUTE = 60000;
  /**
   * @name addMinutes
   * @category Minute Helpers
   * @summary Add the specified number of minutes to the given date.
   *
   * @description
   * Add the specified number of minutes to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of minutes to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the minutes added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 30 minutes to 10 July 2014 12:00:00:
   * const result = addMinutes(new Date(2014, 6, 10, 12, 0), 30)
   * //=> Thu Jul 10 2014 12:30:00
   */

  function addMinutes(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    return addMilliseconds(dirtyDate, amount * MILLISECONDS_IN_MINUTE);
  }

  /**
   * @name addQuarters
   * @category Quarter Helpers
   * @summary Add the specified number of year quarters to the given date.
   *
   * @description
   * Add the specified number of year quarters to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of quarters to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the quarters added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 1 quarter to 1 September 2014:
   * const result = addQuarters(new Date(2014, 8, 1), 1)
   * //=> Mon Dec 01 2014 00:00:00
   */

  function addQuarters(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    var months = amount * 3;
    return addMonths(dirtyDate, months);
  }

  /**
   * @name addSeconds
   * @category Second Helpers
   * @summary Add the specified number of seconds to the given date.
   *
   * @description
   * Add the specified number of seconds to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of seconds to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the seconds added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 30 seconds to 10 July 2014 12:45:00:
   * const result = addSeconds(new Date(2014, 6, 10, 12, 45, 0), 30)
   * //=> Thu Jul 10 2014 12:45:30
   */

  function addSeconds(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    return addMilliseconds(dirtyDate, amount * 1000);
  }

  /**
   * @name addWeeks
   * @category Week Helpers
   * @summary Add the specified number of weeks to the given date.
   *
   * @description
   * Add the specified number of week to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of weeks to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the weeks added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 4 weeks to 1 September 2014:
   * const result = addWeeks(new Date(2014, 8, 1), 4)
   * //=> Mon Sep 29 2014 00:00:00
   */

  function addWeeks(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    var days = amount * 7;
    return addDays(dirtyDate, days);
  }

  /**
   * @name addYears
   * @category Year Helpers
   * @summary Add the specified number of years to the given date.
   *
   * @description
   * Add the specified number of years to the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of years to be added. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the years added
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Add 5 years to 1 September 2014:
   * const result = addYears(new Date(2014, 8, 1), 5)
   * //=> Sun Sep 01 2019 00:00:00
   */

  function addYears(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    return addMonths(dirtyDate, amount * 12);
  }

  /**
   * @name compareAsc
   * @category Common Helpers
   * @summary Compare the two dates and return -1, 0 or 1.
   *
   * @description
   * Compare the two dates and return 1 if the first date is after the second,
   * -1 if the first date is before the second or 0 if dates are equal.
   *
   * @param {Date|Number} dateLeft - the first date to compare
   * @param {Date|Number} dateRight - the second date to compare
   * @returns {Number} the result of the comparison
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Compare 11 February 1987 and 10 July 1989:
   * const result = compareAsc(new Date(1987, 1, 11), new Date(1989, 6, 10))
   * //=> -1
   *
   * @example
   * // Sort the array of dates:
   * const result = [
   *   new Date(1995, 6, 2),
   *   new Date(1987, 1, 11),
   *   new Date(1989, 6, 10)
   * ].sort(compareAsc)
   * //=> [
   * //   Wed Feb 11 1987 00:00:00,
   * //   Mon Jul 10 1989 00:00:00,
   * //   Sun Jul 02 1995 00:00:00
   * // ]
   */

  function compareAsc(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var dateLeft = toDate(dirtyDateLeft);
    var dateRight = toDate(dirtyDateRight);
    var diff = dateLeft.getTime() - dateRight.getTime();

    if (diff < 0) {
      return -1;
    } else if (diff > 0) {
      return 1; // Return 0 if diff is 0; return NaN if diff is NaN
    } else {
      return diff;
    }
  }

  /**
   * Days in 1 week.
   *
   * @name daysInWeek
   * @constant
   * @type {number}
   * @default
   */
  /**
   * Milliseconds in 1 minute
   *
   * @name millisecondsInMinute
   * @constant
   * @type {number}
   * @default
   */

  var millisecondsInMinute = 60000;
  /**
   * Milliseconds in 1 hour
   *
   * @name millisecondsInHour
   * @constant
   * @type {number}
   * @default
   */

  var millisecondsInHour = 3600000;
  /**
   * Milliseconds in 1 second
   *
   * @name millisecondsInSecond
   * @constant
   * @type {number}
   * @default
   */

  var millisecondsInSecond = 1000;

  /**
   * @name isDate
   * @category Common Helpers
   * @summary Is the given value a date?
   *
   * @description
   * Returns true if the given value is an instance of Date. The function works for dates transferred across iframes.
   *
   * @param {*} value - the value to check
   * @returns {boolean} true if the given value is a date
   * @throws {TypeError} 1 arguments required
   *
   * @example
   * // For a valid date:
   * const result = isDate(new Date())
   * //=> true
   *
   * @example
   * // For an invalid date:
   * const result = isDate(new Date(NaN))
   * //=> true
   *
   * @example
   * // For some value:
   * const result = isDate('2014-02-31')
   * //=> false
   *
   * @example
   * // For an object:
   * const result = isDate({})
   * //=> false
   */

  function isDate(value) {
    requiredArgs(1, arguments);
    return value instanceof Date || _typeof(value) === 'object' && Object.prototype.toString.call(value) === '[object Date]';
  }

  /**
   * @name isValid
   * @category Common Helpers
   * @summary Is the given date valid?
   *
   * @description
   * Returns false if argument is Invalid Date and true otherwise.
   * Argument is converted to Date using `toDate`. See [toDate]{@link https://date-fns.org/docs/toDate}
   * Invalid Date is a Date, whose time value is NaN.
   *
   * Time value of Date: http://es5.github.io/#x15.9.1.1
   *
   * @param {*} date - the date to check
   * @returns {Boolean} the date is valid
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // For the valid date:
   * const result = isValid(new Date(2014, 1, 31))
   * //=> true
   *
   * @example
   * // For the value, convertable into a date:
   * const result = isValid(1393804800000)
   * //=> true
   *
   * @example
   * // For the invalid date:
   * const result = isValid(new Date(''))
   * //=> false
   */

  function isValid(dirtyDate) {
    requiredArgs(1, arguments);

    if (!isDate(dirtyDate) && typeof dirtyDate !== 'number') {
      return false;
    }

    var date = toDate(dirtyDate);
    return !isNaN(Number(date));
  }

  /**
   * @name differenceInCalendarMonths
   * @category Month Helpers
   * @summary Get the number of calendar months between the given dates.
   *
   * @description
   * Get the number of calendar months between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of calendar months
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many calendar months are between 31 January 2014 and 1 September 2014?
   * const result = differenceInCalendarMonths(
   *   new Date(2014, 8, 1),
   *   new Date(2014, 0, 31)
   * )
   * //=> 8
   */

  function differenceInCalendarMonths(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var dateLeft = toDate(dirtyDateLeft);
    var dateRight = toDate(dirtyDateRight);
    var yearDiff = dateLeft.getFullYear() - dateRight.getFullYear();
    var monthDiff = dateLeft.getMonth() - dateRight.getMonth();
    return yearDiff * 12 + monthDiff;
  }

  /**
   * @name differenceInCalendarYears
   * @category Year Helpers
   * @summary Get the number of calendar years between the given dates.
   *
   * @description
   * Get the number of calendar years between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of calendar years
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many calendar years are between 31 December 2013 and 11 February 2015?
   * const result = differenceInCalendarYears(
   *   new Date(2015, 1, 11),
   *   new Date(2013, 11, 31)
   * )
   * //=> 2
   */

  function differenceInCalendarYears(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var dateLeft = toDate(dirtyDateLeft);
    var dateRight = toDate(dirtyDateRight);
    return dateLeft.getFullYear() - dateRight.getFullYear();
  }

  // for accurate equality comparisons of UTC timestamps that end up
  // having the same representation in local time, e.g. one hour before
  // DST ends vs. the instant that DST ends.

  function compareLocalAsc(dateLeft, dateRight) {
    var diff = dateLeft.getFullYear() - dateRight.getFullYear() || dateLeft.getMonth() - dateRight.getMonth() || dateLeft.getDate() - dateRight.getDate() || dateLeft.getHours() - dateRight.getHours() || dateLeft.getMinutes() - dateRight.getMinutes() || dateLeft.getSeconds() - dateRight.getSeconds() || dateLeft.getMilliseconds() - dateRight.getMilliseconds();

    if (diff < 0) {
      return -1;
    } else if (diff > 0) {
      return 1; // Return 0 if diff is 0; return NaN if diff is NaN
    } else {
      return diff;
    }
  }
  /**
   * @name differenceInDays
   * @category Day Helpers
   * @summary Get the number of full days between the given dates.
   *
   * @description
   * Get the number of full day periods between two dates. Fractional days are
   * truncated towards zero.
   *
   * One "full day" is the distance between a local time in one day to the same
   * local time on the next or previous day. A full day can sometimes be less than
   * or more than 24 hours if a daylight savings change happens between two dates.
   *
   * To ignore DST and only measure exact 24-hour periods, use this instead:
   * `Math.floor(differenceInHours(dateLeft, dateRight)/24)|0`.
   *
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of full days according to the local timezone
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many full days are between
   * // 2 July 2011 23:00:00 and 2 July 2012 00:00:00?
   * const result = differenceInDays(
   *   new Date(2012, 6, 2, 0, 0),
   *   new Date(2011, 6, 2, 23, 0)
   * )
   * //=> 365
   * // How many full days are between
   * // 2 July 2011 23:59:00 and 3 July 2011 00:01:00?
   * const result = differenceInDays(
   *   new Date(2011, 6, 3, 0, 1),
   *   new Date(2011, 6, 2, 23, 59)
   * )
   * //=> 0
   * // How many full days are between
   * // 1 March 2020 0:00 and 1 June 2020 0:00 ?
   * // Note: because local time is used, the
   * // result will always be 92 days, even in
   * // time zones where DST starts and the
   * // period has only 92*24-1 hours.
   * const result = differenceInDays(
   *   new Date(2020, 5, 1),
   *   new Date(2020, 2, 1)
   * )
  //=> 92
   */


  function differenceInDays(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var dateLeft = toDate(dirtyDateLeft);
    var dateRight = toDate(dirtyDateRight);
    var sign = compareLocalAsc(dateLeft, dateRight);
    var difference = Math.abs(differenceInCalendarDays(dateLeft, dateRight));
    dateLeft.setDate(dateLeft.getDate() - sign * difference); // Math.abs(diff in full days - diff in calendar days) === 1 if last calendar day is not full
    // If so, result must be decreased by 1 in absolute value

    var isLastDayNotFull = Number(compareLocalAsc(dateLeft, dateRight) === -sign);
    var result = sign * (difference - isLastDayNotFull); // Prevent negative zero

    return result === 0 ? 0 : result;
  }

  /**
   * @name differenceInMilliseconds
   * @category Millisecond Helpers
   * @summary Get the number of milliseconds between the given dates.
   *
   * @description
   * Get the number of milliseconds between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of milliseconds
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many milliseconds are between
   * // 2 July 2014 12:30:20.600 and 2 July 2014 12:30:21.700?
   * const result = differenceInMilliseconds(
   *   new Date(2014, 6, 2, 12, 30, 21, 700),
   *   new Date(2014, 6, 2, 12, 30, 20, 600)
   * )
   * //=> 1100
   */

  function differenceInMilliseconds(dateLeft, dateRight) {
    requiredArgs(2, arguments);
    return toDate(dateLeft).getTime() - toDate(dateRight).getTime();
  }

  var roundingMap = {
    ceil: Math.ceil,
    round: Math.round,
    floor: Math.floor,
    trunc: function trunc(value) {
      return value < 0 ? Math.ceil(value) : Math.floor(value);
    } // Math.trunc is not supported by IE

  };
  var defaultRoundingMethod = 'trunc';
  function getRoundingMethod(method) {
    return method ? roundingMap[method] : roundingMap[defaultRoundingMethod];
  }

  /**
   * @name differenceInHours
   * @category Hour Helpers
   * @summary Get the number of hours between the given dates.
   *
   * @description
   * Get the number of hours between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @param {Object} [options] - an object with options.
   * @param {String} [options.roundingMethod='trunc'] - a rounding method (`ceil`, `floor`, `round` or `trunc`)
   * @returns {Number} the number of hours
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many hours are between 2 July 2014 06:50:00 and 2 July 2014 19:00:00?
   * const result = differenceInHours(
   *   new Date(2014, 6, 2, 19, 0),
   *   new Date(2014, 6, 2, 6, 50)
   * )
   * //=> 12
   */

  function differenceInHours(dateLeft, dateRight, options) {
    requiredArgs(2, arguments);
    var diff = differenceInMilliseconds(dateLeft, dateRight) / millisecondsInHour;
    return getRoundingMethod(options === null || options === void 0 ? void 0 : options.roundingMethod)(diff);
  }

  /**
   * @name differenceInMinutes
   * @category Minute Helpers
   * @summary Get the number of minutes between the given dates.
   *
   * @description
   * Get the signed number of full (rounded towards 0) minutes between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @param {Object} [options] - an object with options.
   * @param {String} [options.roundingMethod='trunc'] - a rounding method (`ceil`, `floor`, `round` or `trunc`)
   * @returns {Number} the number of minutes
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many minutes are between 2 July 2014 12:07:59 and 2 July 2014 12:20:00?
   * const result = differenceInMinutes(
   *   new Date(2014, 6, 2, 12, 20, 0),
   *   new Date(2014, 6, 2, 12, 7, 59)
   * )
   * //=> 12
   *
   * @example
   * // How many minutes are between 10:01:59 and 10:00:00
   * const result = differenceInMinutes(
   *   new Date(2000, 0, 1, 10, 0, 0),
   *   new Date(2000, 0, 1, 10, 1, 59)
   * )
   * //=> -1
   */

  function differenceInMinutes(dateLeft, dateRight, options) {
    requiredArgs(2, arguments);
    var diff = differenceInMilliseconds(dateLeft, dateRight) / millisecondsInMinute;
    return getRoundingMethod(options === null || options === void 0 ? void 0 : options.roundingMethod)(diff);
  }

  /**
   * @name endOfDay
   * @category Day Helpers
   * @summary Return the end of a day for the given date.
   *
   * @description
   * Return the end of a day for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of a day
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of a day for 2 September 2014 11:55:00:
   * const result = endOfDay(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Tue Sep 02 2014 23:59:59.999
   */

  function endOfDay(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setHours(23, 59, 59, 999);
    return date;
  }

  /**
   * @name endOfMonth
   * @category Month Helpers
   * @summary Return the end of a month for the given date.
   *
   * @description
   * Return the end of a month for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of a month
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of a month for 2 September 2014 11:55:00:
   * const result = endOfMonth(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Tue Sep 30 2014 23:59:59.999
   */

  function endOfMonth(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var month = date.getMonth();
    date.setFullYear(date.getFullYear(), month + 1, 0);
    date.setHours(23, 59, 59, 999);
    return date;
  }

  /**
   * @name isLastDayOfMonth
   * @category Month Helpers
   * @summary Is the given date the last day of a month?
   *
   * @description
   * Is the given date the last day of a month?
   *
   * @param {Date|Number} date - the date to check
   * @returns {Boolean} the date is the last day of a month
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // Is 28 February 2014 the last day of a month?
   * const result = isLastDayOfMonth(new Date(2014, 1, 28))
   * //=> true
   */

  function isLastDayOfMonth(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    return endOfDay(date).getTime() === endOfMonth(date).getTime();
  }

  /**
   * @name differenceInMonths
   * @category Month Helpers
   * @summary Get the number of full months between the given dates.
   *
   * @description
   * Get the number of full months between the given dates using trunc as a default rounding method.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of full months
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many full months are between 31 January 2014 and 1 September 2014?
   * const result = differenceInMonths(new Date(2014, 8, 1), new Date(2014, 0, 31))
   * //=> 7
   */

  function differenceInMonths(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var dateLeft = toDate(dirtyDateLeft);
    var dateRight = toDate(dirtyDateRight);
    var sign = compareAsc(dateLeft, dateRight);
    var difference = Math.abs(differenceInCalendarMonths(dateLeft, dateRight));
    var result; // Check for the difference of less than month

    if (difference < 1) {
      result = 0;
    } else {
      if (dateLeft.getMonth() === 1 && dateLeft.getDate() > 27) {
        // This will check if the date is end of Feb and assign a higher end of month date
        // to compare it with Jan
        dateLeft.setDate(30);
      }

      dateLeft.setMonth(dateLeft.getMonth() - sign * difference); // Math.abs(diff in full months - diff in calendar months) === 1 if last calendar month is not full
      // If so, result must be decreased by 1 in absolute value

      var isLastMonthNotFull = compareAsc(dateLeft, dateRight) === -sign; // Check for cases of one full calendar month

      if (isLastDayOfMonth(toDate(dirtyDateLeft)) && difference === 1 && compareAsc(dirtyDateLeft, dateRight) === 1) {
        isLastMonthNotFull = false;
      }

      result = sign * (difference - Number(isLastMonthNotFull));
    } // Prevent negative zero


    return result === 0 ? 0 : result;
  }

  /**
   * @name differenceInQuarters
   * @category Quarter Helpers
   * @summary Get the number of quarters between the given dates.
   *
   * @description
   * Get the number of quarters between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @param {Object} [options] - an object with options.
   * @param {String} [options.roundingMethod='trunc'] - a rounding method (`ceil`, `floor`, `round` or `trunc`)
   * @returns {Number} the number of full quarters
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many full quarters are between 31 December 2013 and 2 July 2014?
   * const result = differenceInQuarters(new Date(2014, 6, 2), new Date(2013, 11, 31))
   * //=> 2
   */

  function differenceInQuarters(dateLeft, dateRight, options) {
    requiredArgs(2, arguments);
    var diff = differenceInMonths(dateLeft, dateRight) / 3;
    return getRoundingMethod(options === null || options === void 0 ? void 0 : options.roundingMethod)(diff);
  }

  /**
   * @name differenceInSeconds
   * @category Second Helpers
   * @summary Get the number of seconds between the given dates.
   *
   * @description
   * Get the number of seconds between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @param {Object} [options] - an object with options.
   * @param {String} [options.roundingMethod='trunc'] - a rounding method (`ceil`, `floor`, `round` or `trunc`)
   * @returns {Number} the number of seconds
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many seconds are between
   * // 2 July 2014 12:30:07.999 and 2 July 2014 12:30:20.000?
   * const result = differenceInSeconds(
   *   new Date(2014, 6, 2, 12, 30, 20, 0),
   *   new Date(2014, 6, 2, 12, 30, 7, 999)
   * )
   * //=> 12
   */

  function differenceInSeconds(dateLeft, dateRight, options) {
    requiredArgs(2, arguments);
    var diff = differenceInMilliseconds(dateLeft, dateRight) / 1000;
    return getRoundingMethod(options === null || options === void 0 ? void 0 : options.roundingMethod)(diff);
  }

  /**
   * @name differenceInWeeks
   * @category Week Helpers
   * @summary Get the number of full weeks between the given dates.
   *
   * @description
   * Get the number of full weeks between two dates. Fractional weeks are
   * truncated towards zero by default.
   *
   * One "full week" is the distance between a local time in one day to the same
   * local time 7 days earlier or later. A full week can sometimes be less than
   * or more than 7*24 hours if a daylight savings change happens between two dates.
   *
   * To ignore DST and only measure exact 7*24-hour periods, use this instead:
   * `Math.floor(differenceInHours(dateLeft, dateRight)/(7*24))|0`.
   *
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @param {Object} [options] - an object with options.
   * @param {String} [options.roundingMethod='trunc'] - a rounding method (`ceil`, `floor`, `round` or `trunc`)
   * @returns {Number} the number of full weeks
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many full weeks are between 5 July 2014 and 20 July 2014?
   * const result = differenceInWeeks(new Date(2014, 6, 20), new Date(2014, 6, 5))
   * //=> 2
   *
   * // How many full weeks are between
   * // 1 March 2020 0:00 and 6 June 2020 0:00 ?
   * // Note: because local time is used, the
   * // result will always be 8 weeks (54 days),
   * // even if DST starts and the period has
   * // only 54*24-1 hours.
   * const result = differenceInWeeks(
   *   new Date(2020, 5, 1),
   *   new Date(2020, 2, 6)
   * )
   * //=> 8
   */

  function differenceInWeeks(dateLeft, dateRight, options) {
    requiredArgs(2, arguments);
    var diff = differenceInDays(dateLeft, dateRight) / 7;
    return getRoundingMethod(options === null || options === void 0 ? void 0 : options.roundingMethod)(diff);
  }

  /**
   * @name differenceInYears
   * @category Year Helpers
   * @summary Get the number of full years between the given dates.
   *
   * @description
   * Get the number of full years between the given dates.
   *
   * @param {Date|Number} dateLeft - the later date
   * @param {Date|Number} dateRight - the earlier date
   * @returns {Number} the number of full years
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // How many full years are between 31 December 2013 and 11 February 2015?
   * const result = differenceInYears(new Date(2015, 1, 11), new Date(2013, 11, 31))
   * //=> 1
   */

  function differenceInYears(dirtyDateLeft, dirtyDateRight) {
    requiredArgs(2, arguments);
    var dateLeft = toDate(dirtyDateLeft);
    var dateRight = toDate(dirtyDateRight);
    var sign = compareAsc(dateLeft, dateRight);
    var difference = Math.abs(differenceInCalendarYears(dateLeft, dateRight)); // Set both dates to a valid leap year for accurate comparison when dealing
    // with leap days

    dateLeft.setFullYear(1584);
    dateRight.setFullYear(1584); // Math.abs(diff in full years - diff in calendar years) === 1 if last calendar year is not full
    // If so, result must be decreased by 1 in absolute value

    var isLastYearNotFull = compareAsc(dateLeft, dateRight) === -sign;
    var result = sign * (difference - Number(isLastYearNotFull)); // Prevent negative zero

    return result === 0 ? 0 : result;
  }

  /**
   * @name startOfMinute
   * @category Minute Helpers
   * @summary Return the start of a minute for the given date.
   *
   * @description
   * Return the start of a minute for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of a minute
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of a minute for 1 December 2014 22:15:45.400:
   * const result = startOfMinute(new Date(2014, 11, 1, 22, 15, 45, 400))
   * //=> Mon Dec 01 2014 22:15:00
   */

  function startOfMinute(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setSeconds(0, 0);
    return date;
  }

  /**
   * @name startOfQuarter
   * @category Quarter Helpers
   * @summary Return the start of a year quarter for the given date.
   *
   * @description
   * Return the start of a year quarter for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of a quarter
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of a quarter for 2 September 2014 11:55:00:
   * const result = startOfQuarter(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Tue Jul 01 2014 00:00:00
   */

  function startOfQuarter(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var currentMonth = date.getMonth();
    var month = currentMonth - currentMonth % 3;
    date.setMonth(month, 1);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  /**
   * @name startOfMonth
   * @category Month Helpers
   * @summary Return the start of a month for the given date.
   *
   * @description
   * Return the start of a month for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of a month
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of a month for 2 September 2014 11:55:00:
   * const result = startOfMonth(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Mon Sep 01 2014 00:00:00
   */

  function startOfMonth(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setDate(1);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  /**
   * @name endOfYear
   * @category Year Helpers
   * @summary Return the end of a year for the given date.
   *
   * @description
   * Return the end of a year for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of a year
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of a year for 2 September 2014 11:55:00:
   * const result = endOfYear(new Date(2014, 8, 2, 11, 55, 00))
   * //=> Wed Dec 31 2014 23:59:59.999
   */

  function endOfYear(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var year = date.getFullYear();
    date.setFullYear(year + 1, 0, 0);
    date.setHours(23, 59, 59, 999);
    return date;
  }

  /**
   * @name startOfYear
   * @category Year Helpers
   * @summary Return the start of a year for the given date.
   *
   * @description
   * Return the start of a year for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of a year
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of a year for 2 September 2014 11:55:00:
   * const result = startOfYear(new Date(2014, 8, 2, 11, 55, 00))
   * //=> Wed Jan 01 2014 00:00:00
   */

  function startOfYear(dirtyDate) {
    requiredArgs(1, arguments);
    var cleanDate = toDate(dirtyDate);
    var date = new Date(0);
    date.setFullYear(cleanDate.getFullYear(), 0, 1);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  /**
   * @name endOfHour
   * @category Hour Helpers
   * @summary Return the end of an hour for the given date.
   *
   * @description
   * Return the end of an hour for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of an hour
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of an hour for 2 September 2014 11:55:00:
   * const result = endOfHour(new Date(2014, 8, 2, 11, 55))
   * //=> Tue Sep 02 2014 11:59:59.999
   */

  function endOfHour(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setMinutes(59, 59, 999);
    return date;
  }

  /**
   * @name endOfWeek
   * @category Week Helpers
   * @summary Return the end of a week for the given date.
   *
   * @description
   * Return the end of a week for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @param {Object} [options] - an object with options.
   * @param {Locale} [options.locale=defaultLocale] - the locale object. See [Locale]{@link https://date-fns.org/docs/Locale}
   * @param {0|1|2|3|4|5|6} [options.weekStartsOn=0] - the index of the first day of the week (0 - Sunday)
   * @returns {Date} the end of a week
   * @throws {TypeError} 1 argument required
   * @throws {RangeError} `options.weekStartsOn` must be between 0 and 6
   *
   * @example
   * // The end of a week for 2 September 2014 11:55:00:
   * const result = endOfWeek(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Sat Sep 06 2014 23:59:59.999
   *
   * @example
   * // If the week starts on Monday, the end of the week for 2 September 2014 11:55:00:
   * const result = endOfWeek(new Date(2014, 8, 2, 11, 55, 0), { weekStartsOn: 1 })
   * //=> Sun Sep 07 2014 23:59:59.999
   */

  function endOfWeek(dirtyDate, options) {
    var _ref, _ref2, _ref3, _options$weekStartsOn, _options$locale, _options$locale$optio, _defaultOptions$local, _defaultOptions$local2;

    requiredArgs(1, arguments);
    var defaultOptions = getDefaultOptions();
    var weekStartsOn = toInteger((_ref = (_ref2 = (_ref3 = (_options$weekStartsOn = options === null || options === void 0 ? void 0 : options.weekStartsOn) !== null && _options$weekStartsOn !== void 0 ? _options$weekStartsOn : options === null || options === void 0 ? void 0 : (_options$locale = options.locale) === null || _options$locale === void 0 ? void 0 : (_options$locale$optio = _options$locale.options) === null || _options$locale$optio === void 0 ? void 0 : _options$locale$optio.weekStartsOn) !== null && _ref3 !== void 0 ? _ref3 : defaultOptions.weekStartsOn) !== null && _ref2 !== void 0 ? _ref2 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.weekStartsOn) !== null && _ref !== void 0 ? _ref : 0); // Test if weekStartsOn is between 0 and 6 _and_ is not NaN

    if (!(weekStartsOn >= 0 && weekStartsOn <= 6)) {
      throw new RangeError('weekStartsOn must be between 0 and 6 inclusively');
    }

    var date = toDate(dirtyDate);
    var day = date.getDay();
    var diff = (day < weekStartsOn ? -7 : 0) + 6 - (day - weekStartsOn);
    date.setDate(date.getDate() + diff);
    date.setHours(23, 59, 59, 999);
    return date;
  }

  /**
   * @name endOfMinute
   * @category Minute Helpers
   * @summary Return the end of a minute for the given date.
   *
   * @description
   * Return the end of a minute for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of a minute
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of a minute for 1 December 2014 22:15:45.400:
   * const result = endOfMinute(new Date(2014, 11, 1, 22, 15, 45, 400))
   * //=> Mon Dec 01 2014 22:15:59.999
   */

  function endOfMinute(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setSeconds(59, 999);
    return date;
  }

  /**
   * @name endOfQuarter
   * @category Quarter Helpers
   * @summary Return the end of a year quarter for the given date.
   *
   * @description
   * Return the end of a year quarter for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of a quarter
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of a quarter for 2 September 2014 11:55:00:
   * const result = endOfQuarter(new Date(2014, 8, 2, 11, 55, 0))
   * //=> Tue Sep 30 2014 23:59:59.999
   */

  function endOfQuarter(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var currentMonth = date.getMonth();
    var month = currentMonth - currentMonth % 3 + 3;
    date.setMonth(month, 0);
    date.setHours(23, 59, 59, 999);
    return date;
  }

  /**
   * @name endOfSecond
   * @category Second Helpers
   * @summary Return the end of a second for the given date.
   *
   * @description
   * Return the end of a second for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the end of a second
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The end of a second for 1 December 2014 22:15:45.400:
   * const result = endOfSecond(new Date(2014, 11, 1, 22, 15, 45, 400))
   * //=> Mon Dec 01 2014 22:15:45.999
   */

  function endOfSecond(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setMilliseconds(999);
    return date;
  }

  /**
   * @name subMilliseconds
   * @category Millisecond Helpers
   * @summary Subtract the specified number of milliseconds from the given date.
   *
   * @description
   * Subtract the specified number of milliseconds from the given date.
   *
   * @param {Date|Number} date - the date to be changed
   * @param {Number} amount - the amount of milliseconds to be subtracted. Positive decimals will be rounded using `Math.floor`, decimals less than zero will be rounded using `Math.ceil`.
   * @returns {Date} the new date with the milliseconds subtracted
   * @throws {TypeError} 2 arguments required
   *
   * @example
   * // Subtract 750 milliseconds from 10 July 2014 12:45:30.000:
   * const result = subMilliseconds(new Date(2014, 6, 10, 12, 45, 30, 0), 750)
   * //=> Thu Jul 10 2014 12:45:29.250
   */

  function subMilliseconds(dirtyDate, dirtyAmount) {
    requiredArgs(2, arguments);
    var amount = toInteger(dirtyAmount);
    return addMilliseconds(dirtyDate, -amount);
  }

  var MILLISECONDS_IN_DAY = 86400000;
  function getUTCDayOfYear(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var timestamp = date.getTime();
    date.setUTCMonth(0, 1);
    date.setUTCHours(0, 0, 0, 0);
    var startOfYearTimestamp = date.getTime();
    var difference = timestamp - startOfYearTimestamp;
    return Math.floor(difference / MILLISECONDS_IN_DAY) + 1;
  }

  function startOfUTCISOWeek(dirtyDate) {
    requiredArgs(1, arguments);
    var weekStartsOn = 1;
    var date = toDate(dirtyDate);
    var day = date.getUTCDay();
    var diff = (day < weekStartsOn ? 7 : 0) + day - weekStartsOn;
    date.setUTCDate(date.getUTCDate() - diff);
    date.setUTCHours(0, 0, 0, 0);
    return date;
  }

  function getUTCISOWeekYear(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var year = date.getUTCFullYear();
    var fourthOfJanuaryOfNextYear = new Date(0);
    fourthOfJanuaryOfNextYear.setUTCFullYear(year + 1, 0, 4);
    fourthOfJanuaryOfNextYear.setUTCHours(0, 0, 0, 0);
    var startOfNextYear = startOfUTCISOWeek(fourthOfJanuaryOfNextYear);
    var fourthOfJanuaryOfThisYear = new Date(0);
    fourthOfJanuaryOfThisYear.setUTCFullYear(year, 0, 4);
    fourthOfJanuaryOfThisYear.setUTCHours(0, 0, 0, 0);
    var startOfThisYear = startOfUTCISOWeek(fourthOfJanuaryOfThisYear);

    if (date.getTime() >= startOfNextYear.getTime()) {
      return year + 1;
    } else if (date.getTime() >= startOfThisYear.getTime()) {
      return year;
    } else {
      return year - 1;
    }
  }

  function startOfUTCISOWeekYear(dirtyDate) {
    requiredArgs(1, arguments);
    var year = getUTCISOWeekYear(dirtyDate);
    var fourthOfJanuary = new Date(0);
    fourthOfJanuary.setUTCFullYear(year, 0, 4);
    fourthOfJanuary.setUTCHours(0, 0, 0, 0);
    var date = startOfUTCISOWeek(fourthOfJanuary);
    return date;
  }

  var MILLISECONDS_IN_WEEK$1 = 604800000;
  function getUTCISOWeek(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var diff = startOfUTCISOWeek(date).getTime() - startOfUTCISOWeekYear(date).getTime(); // Round the number of days to the nearest integer
    // because the number of milliseconds in a week is not constant
    // (e.g. it's different in the week of the daylight saving time clock shift)

    return Math.round(diff / MILLISECONDS_IN_WEEK$1) + 1;
  }

  function startOfUTCWeek(dirtyDate, options) {
    var _ref, _ref2, _ref3, _options$weekStartsOn, _options$locale, _options$locale$optio, _defaultOptions$local, _defaultOptions$local2;

    requiredArgs(1, arguments);
    var defaultOptions = getDefaultOptions();
    var weekStartsOn = toInteger((_ref = (_ref2 = (_ref3 = (_options$weekStartsOn = options === null || options === void 0 ? void 0 : options.weekStartsOn) !== null && _options$weekStartsOn !== void 0 ? _options$weekStartsOn : options === null || options === void 0 ? void 0 : (_options$locale = options.locale) === null || _options$locale === void 0 ? void 0 : (_options$locale$optio = _options$locale.options) === null || _options$locale$optio === void 0 ? void 0 : _options$locale$optio.weekStartsOn) !== null && _ref3 !== void 0 ? _ref3 : defaultOptions.weekStartsOn) !== null && _ref2 !== void 0 ? _ref2 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.weekStartsOn) !== null && _ref !== void 0 ? _ref : 0); // Test if weekStartsOn is between 0 and 6 _and_ is not NaN

    if (!(weekStartsOn >= 0 && weekStartsOn <= 6)) {
      throw new RangeError('weekStartsOn must be between 0 and 6 inclusively');
    }

    var date = toDate(dirtyDate);
    var day = date.getUTCDay();
    var diff = (day < weekStartsOn ? 7 : 0) + day - weekStartsOn;
    date.setUTCDate(date.getUTCDate() - diff);
    date.setUTCHours(0, 0, 0, 0);
    return date;
  }

  function getUTCWeekYear(dirtyDate, options) {
    var _ref, _ref2, _ref3, _options$firstWeekCon, _options$locale, _options$locale$optio, _defaultOptions$local, _defaultOptions$local2;

    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var year = date.getUTCFullYear();
    var defaultOptions = getDefaultOptions();
    var firstWeekContainsDate = toInteger((_ref = (_ref2 = (_ref3 = (_options$firstWeekCon = options === null || options === void 0 ? void 0 : options.firstWeekContainsDate) !== null && _options$firstWeekCon !== void 0 ? _options$firstWeekCon : options === null || options === void 0 ? void 0 : (_options$locale = options.locale) === null || _options$locale === void 0 ? void 0 : (_options$locale$optio = _options$locale.options) === null || _options$locale$optio === void 0 ? void 0 : _options$locale$optio.firstWeekContainsDate) !== null && _ref3 !== void 0 ? _ref3 : defaultOptions.firstWeekContainsDate) !== null && _ref2 !== void 0 ? _ref2 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.firstWeekContainsDate) !== null && _ref !== void 0 ? _ref : 1); // Test if weekStartsOn is between 1 and 7 _and_ is not NaN

    if (!(firstWeekContainsDate >= 1 && firstWeekContainsDate <= 7)) {
      throw new RangeError('firstWeekContainsDate must be between 1 and 7 inclusively');
    }

    var firstWeekOfNextYear = new Date(0);
    firstWeekOfNextYear.setUTCFullYear(year + 1, 0, firstWeekContainsDate);
    firstWeekOfNextYear.setUTCHours(0, 0, 0, 0);
    var startOfNextYear = startOfUTCWeek(firstWeekOfNextYear, options);
    var firstWeekOfThisYear = new Date(0);
    firstWeekOfThisYear.setUTCFullYear(year, 0, firstWeekContainsDate);
    firstWeekOfThisYear.setUTCHours(0, 0, 0, 0);
    var startOfThisYear = startOfUTCWeek(firstWeekOfThisYear, options);

    if (date.getTime() >= startOfNextYear.getTime()) {
      return year + 1;
    } else if (date.getTime() >= startOfThisYear.getTime()) {
      return year;
    } else {
      return year - 1;
    }
  }

  function startOfUTCWeekYear(dirtyDate, options) {
    var _ref, _ref2, _ref3, _options$firstWeekCon, _options$locale, _options$locale$optio, _defaultOptions$local, _defaultOptions$local2;

    requiredArgs(1, arguments);
    var defaultOptions = getDefaultOptions();
    var firstWeekContainsDate = toInteger((_ref = (_ref2 = (_ref3 = (_options$firstWeekCon = options === null || options === void 0 ? void 0 : options.firstWeekContainsDate) !== null && _options$firstWeekCon !== void 0 ? _options$firstWeekCon : options === null || options === void 0 ? void 0 : (_options$locale = options.locale) === null || _options$locale === void 0 ? void 0 : (_options$locale$optio = _options$locale.options) === null || _options$locale$optio === void 0 ? void 0 : _options$locale$optio.firstWeekContainsDate) !== null && _ref3 !== void 0 ? _ref3 : defaultOptions.firstWeekContainsDate) !== null && _ref2 !== void 0 ? _ref2 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.firstWeekContainsDate) !== null && _ref !== void 0 ? _ref : 1);
    var year = getUTCWeekYear(dirtyDate, options);
    var firstWeek = new Date(0);
    firstWeek.setUTCFullYear(year, 0, firstWeekContainsDate);
    firstWeek.setUTCHours(0, 0, 0, 0);
    var date = startOfUTCWeek(firstWeek, options);
    return date;
  }

  var MILLISECONDS_IN_WEEK = 604800000;
  function getUTCWeek(dirtyDate, options) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    var diff = startOfUTCWeek(date, options).getTime() - startOfUTCWeekYear(date, options).getTime(); // Round the number of days to the nearest integer
    // because the number of milliseconds in a week is not constant
    // (e.g. it's different in the week of the daylight saving time clock shift)

    return Math.round(diff / MILLISECONDS_IN_WEEK) + 1;
  }

  function addLeadingZeros(number, targetLength) {
    var sign = number < 0 ? '-' : '';
    var output = Math.abs(number).toString();

    while (output.length < targetLength) {
      output = '0' + output;
    }

    return sign + output;
  }

  /*
   * |     | Unit                           |     | Unit                           |
   * |-----|--------------------------------|-----|--------------------------------|
   * |  a  | AM, PM                         |  A* |                                |
   * |  d  | Day of month                   |  D  |                                |
   * |  h  | Hour [1-12]                    |  H  | Hour [0-23]                    |
   * |  m  | Minute                         |  M  | Month                          |
   * |  s  | Second                         |  S  | Fraction of second             |
   * |  y  | Year (abs)                     |  Y  |                                |
   *
   * Letters marked by * are not implemented but reserved by Unicode standard.
   */

  var formatters$2 = {
    // Year
    y: function y(date, token) {
      // From http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_tokens
      // | Year     |     y | yy |   yyy |  yyyy | yyyyy |
      // |----------|-------|----|-------|-------|-------|
      // | AD 1     |     1 | 01 |   001 |  0001 | 00001 |
      // | AD 12    |    12 | 12 |   012 |  0012 | 00012 |
      // | AD 123   |   123 | 23 |   123 |  0123 | 00123 |
      // | AD 1234  |  1234 | 34 |  1234 |  1234 | 01234 |
      // | AD 12345 | 12345 | 45 | 12345 | 12345 | 12345 |
      var signedYear = date.getUTCFullYear(); // Returns 1 for 1 BC (which is year 0 in JavaScript)

      var year = signedYear > 0 ? signedYear : 1 - signedYear;
      return addLeadingZeros(token === 'yy' ? year % 100 : year, token.length);
    },
    // Month
    M: function M(date, token) {
      var month = date.getUTCMonth();
      return token === 'M' ? String(month + 1) : addLeadingZeros(month + 1, 2);
    },
    // Day of the month
    d: function d(date, token) {
      return addLeadingZeros(date.getUTCDate(), token.length);
    },
    // AM or PM
    a: function a(date, token) {
      var dayPeriodEnumValue = date.getUTCHours() / 12 >= 1 ? 'pm' : 'am';

      switch (token) {
        case 'a':
        case 'aa':
          return dayPeriodEnumValue.toUpperCase();

        case 'aaa':
          return dayPeriodEnumValue;

        case 'aaaaa':
          return dayPeriodEnumValue[0];

        case 'aaaa':
        default:
          return dayPeriodEnumValue === 'am' ? 'a.m.' : 'p.m.';
      }
    },
    // Hour [1-12]
    h: function h(date, token) {
      return addLeadingZeros(date.getUTCHours() % 12 || 12, token.length);
    },
    // Hour [0-23]
    H: function H(date, token) {
      return addLeadingZeros(date.getUTCHours(), token.length);
    },
    // Minute
    m: function m(date, token) {
      return addLeadingZeros(date.getUTCMinutes(), token.length);
    },
    // Second
    s: function s(date, token) {
      return addLeadingZeros(date.getUTCSeconds(), token.length);
    },
    // Fraction of second
    S: function S(date, token) {
      var numberOfDigits = token.length;
      var milliseconds = date.getUTCMilliseconds();
      var fractionalSeconds = Math.floor(milliseconds * Math.pow(10, numberOfDigits - 3));
      return addLeadingZeros(fractionalSeconds, token.length);
    }
  };
  var formatters$3 = formatters$2;

  var dayPeriodEnum = {
    am: 'am',
    pm: 'pm',
    midnight: 'midnight',
    noon: 'noon',
    morning: 'morning',
    afternoon: 'afternoon',
    evening: 'evening',
    night: 'night'
  };
  /*
   * |     | Unit                           |     | Unit                           |
   * |-----|--------------------------------|-----|--------------------------------|
   * |  a  | AM, PM                         |  A* | Milliseconds in day            |
   * |  b  | AM, PM, noon, midnight         |  B  | Flexible day period            |
   * |  c  | Stand-alone local day of week  |  C* | Localized hour w/ day period   |
   * |  d  | Day of month                   |  D  | Day of year                    |
   * |  e  | Local day of week              |  E  | Day of week                    |
   * |  f  |                                |  F* | Day of week in month           |
   * |  g* | Modified Julian day            |  G  | Era                            |
   * |  h  | Hour [1-12]                    |  H  | Hour [0-23]                    |
   * |  i! | ISO day of week                |  I! | ISO week of year               |
   * |  j* | Localized hour w/ day period   |  J* | Localized hour w/o day period  |
   * |  k  | Hour [1-24]                    |  K  | Hour [0-11]                    |
   * |  l* | (deprecated)                   |  L  | Stand-alone month              |
   * |  m  | Minute                         |  M  | Month                          |
   * |  n  |                                |  N  |                                |
   * |  o! | Ordinal number modifier        |  O  | Timezone (GMT)                 |
   * |  p! | Long localized time            |  P! | Long localized date            |
   * |  q  | Stand-alone quarter            |  Q  | Quarter                        |
   * |  r* | Related Gregorian year         |  R! | ISO week-numbering year        |
   * |  s  | Second                         |  S  | Fraction of second             |
   * |  t! | Seconds timestamp              |  T! | Milliseconds timestamp         |
   * |  u  | Extended year                  |  U* | Cyclic year                    |
   * |  v* | Timezone (generic non-locat.)  |  V* | Timezone (location)            |
   * |  w  | Local week of year             |  W* | Week of month                  |
   * |  x  | Timezone (ISO-8601 w/o Z)      |  X  | Timezone (ISO-8601)            |
   * |  y  | Year (abs)                     |  Y  | Local week-numbering year      |
   * |  z  | Timezone (specific non-locat.) |  Z* | Timezone (aliases)             |
   *
   * Letters marked by * are not implemented but reserved by Unicode standard.
   *
   * Letters marked by ! are non-standard, but implemented by date-fns:
   * - `o` modifies the previous token to turn it into an ordinal (see `format` docs)
   * - `i` is ISO day of week. For `i` and `ii` is returns numeric ISO week days,
   *   i.e. 7 for Sunday, 1 for Monday, etc.
   * - `I` is ISO week of year, as opposed to `w` which is local week of year.
   * - `R` is ISO week-numbering year, as opposed to `Y` which is local week-numbering year.
   *   `R` is supposed to be used in conjunction with `I` and `i`
   *   for universal ISO week-numbering date, whereas
   *   `Y` is supposed to be used in conjunction with `w` and `e`
   *   for week-numbering date specific to the locale.
   * - `P` is long localized date format
   * - `p` is long localized time format
   */

  var formatters = {
    // Era
    G: function G(date, token, localize) {
      var era = date.getUTCFullYear() > 0 ? 1 : 0;

      switch (token) {
        // AD, BC
        case 'G':
        case 'GG':
        case 'GGG':
          return localize.era(era, {
            width: 'abbreviated'
          });
        // A, B

        case 'GGGGG':
          return localize.era(era, {
            width: 'narrow'
          });
        // Anno Domini, Before Christ

        case 'GGGG':
        default:
          return localize.era(era, {
            width: 'wide'
          });
      }
    },
    // Year
    y: function y(date, token, localize) {
      // Ordinal number
      if (token === 'yo') {
        var signedYear = date.getUTCFullYear(); // Returns 1 for 1 BC (which is year 0 in JavaScript)

        var year = signedYear > 0 ? signedYear : 1 - signedYear;
        return localize.ordinalNumber(year, {
          unit: 'year'
        });
      }

      return formatters$3.y(date, token);
    },
    // Local week-numbering year
    Y: function Y(date, token, localize, options) {
      var signedWeekYear = getUTCWeekYear(date, options); // Returns 1 for 1 BC (which is year 0 in JavaScript)

      var weekYear = signedWeekYear > 0 ? signedWeekYear : 1 - signedWeekYear; // Two digit year

      if (token === 'YY') {
        var twoDigitYear = weekYear % 100;
        return addLeadingZeros(twoDigitYear, 2);
      } // Ordinal number


      if (token === 'Yo') {
        return localize.ordinalNumber(weekYear, {
          unit: 'year'
        });
      } // Padding


      return addLeadingZeros(weekYear, token.length);
    },
    // ISO week-numbering year
    R: function R(date, token) {
      var isoWeekYear = getUTCISOWeekYear(date); // Padding

      return addLeadingZeros(isoWeekYear, token.length);
    },
    // Extended year. This is a single number designating the year of this calendar system.
    // The main difference between `y` and `u` localizers are B.C. years:
    // | Year | `y` | `u` |
    // |------|-----|-----|
    // | AC 1 |   1 |   1 |
    // | BC 1 |   1 |   0 |
    // | BC 2 |   2 |  -1 |
    // Also `yy` always returns the last two digits of a year,
    // while `uu` pads single digit years to 2 characters and returns other years unchanged.
    u: function u(date, token) {
      var year = date.getUTCFullYear();
      return addLeadingZeros(year, token.length);
    },
    // Quarter
    Q: function Q(date, token, localize) {
      var quarter = Math.ceil((date.getUTCMonth() + 1) / 3);

      switch (token) {
        // 1, 2, 3, 4
        case 'Q':
          return String(quarter);
        // 01, 02, 03, 04

        case 'QQ':
          return addLeadingZeros(quarter, 2);
        // 1st, 2nd, 3rd, 4th

        case 'Qo':
          return localize.ordinalNumber(quarter, {
            unit: 'quarter'
          });
        // Q1, Q2, Q3, Q4

        case 'QQQ':
          return localize.quarter(quarter, {
            width: 'abbreviated',
            context: 'formatting'
          });
        // 1, 2, 3, 4 (narrow quarter; could be not numerical)

        case 'QQQQQ':
          return localize.quarter(quarter, {
            width: 'narrow',
            context: 'formatting'
          });
        // 1st quarter, 2nd quarter, ...

        case 'QQQQ':
        default:
          return localize.quarter(quarter, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // Stand-alone quarter
    q: function q(date, token, localize) {
      var quarter = Math.ceil((date.getUTCMonth() + 1) / 3);

      switch (token) {
        // 1, 2, 3, 4
        case 'q':
          return String(quarter);
        // 01, 02, 03, 04

        case 'qq':
          return addLeadingZeros(quarter, 2);
        // 1st, 2nd, 3rd, 4th

        case 'qo':
          return localize.ordinalNumber(quarter, {
            unit: 'quarter'
          });
        // Q1, Q2, Q3, Q4

        case 'qqq':
          return localize.quarter(quarter, {
            width: 'abbreviated',
            context: 'standalone'
          });
        // 1, 2, 3, 4 (narrow quarter; could be not numerical)

        case 'qqqqq':
          return localize.quarter(quarter, {
            width: 'narrow',
            context: 'standalone'
          });
        // 1st quarter, 2nd quarter, ...

        case 'qqqq':
        default:
          return localize.quarter(quarter, {
            width: 'wide',
            context: 'standalone'
          });
      }
    },
    // Month
    M: function M(date, token, localize) {
      var month = date.getUTCMonth();

      switch (token) {
        case 'M':
        case 'MM':
          return formatters$3.M(date, token);
        // 1st, 2nd, ..., 12th

        case 'Mo':
          return localize.ordinalNumber(month + 1, {
            unit: 'month'
          });
        // Jan, Feb, ..., Dec

        case 'MMM':
          return localize.month(month, {
            width: 'abbreviated',
            context: 'formatting'
          });
        // J, F, ..., D

        case 'MMMMM':
          return localize.month(month, {
            width: 'narrow',
            context: 'formatting'
          });
        // January, February, ..., December

        case 'MMMM':
        default:
          return localize.month(month, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // Stand-alone month
    L: function L(date, token, localize) {
      var month = date.getUTCMonth();

      switch (token) {
        // 1, 2, ..., 12
        case 'L':
          return String(month + 1);
        // 01, 02, ..., 12

        case 'LL':
          return addLeadingZeros(month + 1, 2);
        // 1st, 2nd, ..., 12th

        case 'Lo':
          return localize.ordinalNumber(month + 1, {
            unit: 'month'
          });
        // Jan, Feb, ..., Dec

        case 'LLL':
          return localize.month(month, {
            width: 'abbreviated',
            context: 'standalone'
          });
        // J, F, ..., D

        case 'LLLLL':
          return localize.month(month, {
            width: 'narrow',
            context: 'standalone'
          });
        // January, February, ..., December

        case 'LLLL':
        default:
          return localize.month(month, {
            width: 'wide',
            context: 'standalone'
          });
      }
    },
    // Local week of year
    w: function w(date, token, localize, options) {
      var week = getUTCWeek(date, options);

      if (token === 'wo') {
        return localize.ordinalNumber(week, {
          unit: 'week'
        });
      }

      return addLeadingZeros(week, token.length);
    },
    // ISO week of year
    I: function I(date, token, localize) {
      var isoWeek = getUTCISOWeek(date);

      if (token === 'Io') {
        return localize.ordinalNumber(isoWeek, {
          unit: 'week'
        });
      }

      return addLeadingZeros(isoWeek, token.length);
    },
    // Day of the month
    d: function d(date, token, localize) {
      if (token === 'do') {
        return localize.ordinalNumber(date.getUTCDate(), {
          unit: 'date'
        });
      }

      return formatters$3.d(date, token);
    },
    // Day of year
    D: function D(date, token, localize) {
      var dayOfYear = getUTCDayOfYear(date);

      if (token === 'Do') {
        return localize.ordinalNumber(dayOfYear, {
          unit: 'dayOfYear'
        });
      }

      return addLeadingZeros(dayOfYear, token.length);
    },
    // Day of week
    E: function E(date, token, localize) {
      var dayOfWeek = date.getUTCDay();

      switch (token) {
        // Tue
        case 'E':
        case 'EE':
        case 'EEE':
          return localize.day(dayOfWeek, {
            width: 'abbreviated',
            context: 'formatting'
          });
        // T

        case 'EEEEE':
          return localize.day(dayOfWeek, {
            width: 'narrow',
            context: 'formatting'
          });
        // Tu

        case 'EEEEEE':
          return localize.day(dayOfWeek, {
            width: 'short',
            context: 'formatting'
          });
        // Tuesday

        case 'EEEE':
        default:
          return localize.day(dayOfWeek, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // Local day of week
    e: function e(date, token, localize, options) {
      var dayOfWeek = date.getUTCDay();
      var localDayOfWeek = (dayOfWeek - options.weekStartsOn + 8) % 7 || 7;

      switch (token) {
        // Numerical value (Nth day of week with current locale or weekStartsOn)
        case 'e':
          return String(localDayOfWeek);
        // Padded numerical value

        case 'ee':
          return addLeadingZeros(localDayOfWeek, 2);
        // 1st, 2nd, ..., 7th

        case 'eo':
          return localize.ordinalNumber(localDayOfWeek, {
            unit: 'day'
          });

        case 'eee':
          return localize.day(dayOfWeek, {
            width: 'abbreviated',
            context: 'formatting'
          });
        // T

        case 'eeeee':
          return localize.day(dayOfWeek, {
            width: 'narrow',
            context: 'formatting'
          });
        // Tu

        case 'eeeeee':
          return localize.day(dayOfWeek, {
            width: 'short',
            context: 'formatting'
          });
        // Tuesday

        case 'eeee':
        default:
          return localize.day(dayOfWeek, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // Stand-alone local day of week
    c: function c(date, token, localize, options) {
      var dayOfWeek = date.getUTCDay();
      var localDayOfWeek = (dayOfWeek - options.weekStartsOn + 8) % 7 || 7;

      switch (token) {
        // Numerical value (same as in `e`)
        case 'c':
          return String(localDayOfWeek);
        // Padded numerical value

        case 'cc':
          return addLeadingZeros(localDayOfWeek, token.length);
        // 1st, 2nd, ..., 7th

        case 'co':
          return localize.ordinalNumber(localDayOfWeek, {
            unit: 'day'
          });

        case 'ccc':
          return localize.day(dayOfWeek, {
            width: 'abbreviated',
            context: 'standalone'
          });
        // T

        case 'ccccc':
          return localize.day(dayOfWeek, {
            width: 'narrow',
            context: 'standalone'
          });
        // Tu

        case 'cccccc':
          return localize.day(dayOfWeek, {
            width: 'short',
            context: 'standalone'
          });
        // Tuesday

        case 'cccc':
        default:
          return localize.day(dayOfWeek, {
            width: 'wide',
            context: 'standalone'
          });
      }
    },
    // ISO day of week
    i: function i(date, token, localize) {
      var dayOfWeek = date.getUTCDay();
      var isoDayOfWeek = dayOfWeek === 0 ? 7 : dayOfWeek;

      switch (token) {
        // 2
        case 'i':
          return String(isoDayOfWeek);
        // 02

        case 'ii':
          return addLeadingZeros(isoDayOfWeek, token.length);
        // 2nd

        case 'io':
          return localize.ordinalNumber(isoDayOfWeek, {
            unit: 'day'
          });
        // Tue

        case 'iii':
          return localize.day(dayOfWeek, {
            width: 'abbreviated',
            context: 'formatting'
          });
        // T

        case 'iiiii':
          return localize.day(dayOfWeek, {
            width: 'narrow',
            context: 'formatting'
          });
        // Tu

        case 'iiiiii':
          return localize.day(dayOfWeek, {
            width: 'short',
            context: 'formatting'
          });
        // Tuesday

        case 'iiii':
        default:
          return localize.day(dayOfWeek, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // AM or PM
    a: function a(date, token, localize) {
      var hours = date.getUTCHours();
      var dayPeriodEnumValue = hours / 12 >= 1 ? 'pm' : 'am';

      switch (token) {
        case 'a':
        case 'aa':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'abbreviated',
            context: 'formatting'
          });

        case 'aaa':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'abbreviated',
            context: 'formatting'
          }).toLowerCase();

        case 'aaaaa':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'narrow',
            context: 'formatting'
          });

        case 'aaaa':
        default:
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // AM, PM, midnight, noon
    b: function b(date, token, localize) {
      var hours = date.getUTCHours();
      var dayPeriodEnumValue;

      if (hours === 12) {
        dayPeriodEnumValue = dayPeriodEnum.noon;
      } else if (hours === 0) {
        dayPeriodEnumValue = dayPeriodEnum.midnight;
      } else {
        dayPeriodEnumValue = hours / 12 >= 1 ? 'pm' : 'am';
      }

      switch (token) {
        case 'b':
        case 'bb':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'abbreviated',
            context: 'formatting'
          });

        case 'bbb':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'abbreviated',
            context: 'formatting'
          }).toLowerCase();

        case 'bbbbb':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'narrow',
            context: 'formatting'
          });

        case 'bbbb':
        default:
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // in the morning, in the afternoon, in the evening, at night
    B: function B(date, token, localize) {
      var hours = date.getUTCHours();
      var dayPeriodEnumValue;

      if (hours >= 17) {
        dayPeriodEnumValue = dayPeriodEnum.evening;
      } else if (hours >= 12) {
        dayPeriodEnumValue = dayPeriodEnum.afternoon;
      } else if (hours >= 4) {
        dayPeriodEnumValue = dayPeriodEnum.morning;
      } else {
        dayPeriodEnumValue = dayPeriodEnum.night;
      }

      switch (token) {
        case 'B':
        case 'BB':
        case 'BBB':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'abbreviated',
            context: 'formatting'
          });

        case 'BBBBB':
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'narrow',
            context: 'formatting'
          });

        case 'BBBB':
        default:
          return localize.dayPeriod(dayPeriodEnumValue, {
            width: 'wide',
            context: 'formatting'
          });
      }
    },
    // Hour [1-12]
    h: function h(date, token, localize) {
      if (token === 'ho') {
        var hours = date.getUTCHours() % 12;
        if (hours === 0) hours = 12;
        return localize.ordinalNumber(hours, {
          unit: 'hour'
        });
      }

      return formatters$3.h(date, token);
    },
    // Hour [0-23]
    H: function H(date, token, localize) {
      if (token === 'Ho') {
        return localize.ordinalNumber(date.getUTCHours(), {
          unit: 'hour'
        });
      }

      return formatters$3.H(date, token);
    },
    // Hour [0-11]
    K: function K(date, token, localize) {
      var hours = date.getUTCHours() % 12;

      if (token === 'Ko') {
        return localize.ordinalNumber(hours, {
          unit: 'hour'
        });
      }

      return addLeadingZeros(hours, token.length);
    },
    // Hour [1-24]
    k: function k(date, token, localize) {
      var hours = date.getUTCHours();
      if (hours === 0) hours = 24;

      if (token === 'ko') {
        return localize.ordinalNumber(hours, {
          unit: 'hour'
        });
      }

      return addLeadingZeros(hours, token.length);
    },
    // Minute
    m: function m(date, token, localize) {
      if (token === 'mo') {
        return localize.ordinalNumber(date.getUTCMinutes(), {
          unit: 'minute'
        });
      }

      return formatters$3.m(date, token);
    },
    // Second
    s: function s(date, token, localize) {
      if (token === 'so') {
        return localize.ordinalNumber(date.getUTCSeconds(), {
          unit: 'second'
        });
      }

      return formatters$3.s(date, token);
    },
    // Fraction of second
    S: function S(date, token) {
      return formatters$3.S(date, token);
    },
    // Timezone (ISO-8601. If offset is 0, output is always `'Z'`)
    X: function X(date, token, _localize, options) {
      var originalDate = options._originalDate || date;
      var timezoneOffset = originalDate.getTimezoneOffset();

      if (timezoneOffset === 0) {
        return 'Z';
      }

      switch (token) {
        // Hours and optional minutes
        case 'X':
          return formatTimezoneWithOptionalMinutes(timezoneOffset);
        // Hours, minutes and optional seconds without `:` delimiter
        // Note: neither ISO-8601 nor JavaScript supports seconds in timezone offsets
        // so this token always has the same output as `XX`

        case 'XXXX':
        case 'XX':
          // Hours and minutes without `:` delimiter
          return formatTimezone(timezoneOffset);
        // Hours, minutes and optional seconds with `:` delimiter
        // Note: neither ISO-8601 nor JavaScript supports seconds in timezone offsets
        // so this token always has the same output as `XXX`

        case 'XXXXX':
        case 'XXX': // Hours and minutes with `:` delimiter

        default:
          return formatTimezone(timezoneOffset, ':');
      }
    },
    // Timezone (ISO-8601. If offset is 0, output is `'+00:00'` or equivalent)
    x: function x(date, token, _localize, options) {
      var originalDate = options._originalDate || date;
      var timezoneOffset = originalDate.getTimezoneOffset();

      switch (token) {
        // Hours and optional minutes
        case 'x':
          return formatTimezoneWithOptionalMinutes(timezoneOffset);
        // Hours, minutes and optional seconds without `:` delimiter
        // Note: neither ISO-8601 nor JavaScript supports seconds in timezone offsets
        // so this token always has the same output as `xx`

        case 'xxxx':
        case 'xx':
          // Hours and minutes without `:` delimiter
          return formatTimezone(timezoneOffset);
        // Hours, minutes and optional seconds with `:` delimiter
        // Note: neither ISO-8601 nor JavaScript supports seconds in timezone offsets
        // so this token always has the same output as `xxx`

        case 'xxxxx':
        case 'xxx': // Hours and minutes with `:` delimiter

        default:
          return formatTimezone(timezoneOffset, ':');
      }
    },
    // Timezone (GMT)
    O: function O(date, token, _localize, options) {
      var originalDate = options._originalDate || date;
      var timezoneOffset = originalDate.getTimezoneOffset();

      switch (token) {
        // Short
        case 'O':
        case 'OO':
        case 'OOO':
          return 'GMT' + formatTimezoneShort(timezoneOffset, ':');
        // Long

        case 'OOOO':
        default:
          return 'GMT' + formatTimezone(timezoneOffset, ':');
      }
    },
    // Timezone (specific non-location)
    z: function z(date, token, _localize, options) {
      var originalDate = options._originalDate || date;
      var timezoneOffset = originalDate.getTimezoneOffset();

      switch (token) {
        // Short
        case 'z':
        case 'zz':
        case 'zzz':
          return 'GMT' + formatTimezoneShort(timezoneOffset, ':');
        // Long

        case 'zzzz':
        default:
          return 'GMT' + formatTimezone(timezoneOffset, ':');
      }
    },
    // Seconds timestamp
    t: function t(date, token, _localize, options) {
      var originalDate = options._originalDate || date;
      var timestamp = Math.floor(originalDate.getTime() / 1000);
      return addLeadingZeros(timestamp, token.length);
    },
    // Milliseconds timestamp
    T: function T(date, token, _localize, options) {
      var originalDate = options._originalDate || date;
      var timestamp = originalDate.getTime();
      return addLeadingZeros(timestamp, token.length);
    }
  };

  function formatTimezoneShort(offset, dirtyDelimiter) {
    var sign = offset > 0 ? '-' : '+';
    var absOffset = Math.abs(offset);
    var hours = Math.floor(absOffset / 60);
    var minutes = absOffset % 60;

    if (minutes === 0) {
      return sign + String(hours);
    }

    var delimiter = dirtyDelimiter || '';
    return sign + String(hours) + delimiter + addLeadingZeros(minutes, 2);
  }

  function formatTimezoneWithOptionalMinutes(offset, dirtyDelimiter) {
    if (offset % 60 === 0) {
      var sign = offset > 0 ? '-' : '+';
      return sign + addLeadingZeros(Math.abs(offset) / 60, 2);
    }

    return formatTimezone(offset, dirtyDelimiter);
  }

  function formatTimezone(offset, dirtyDelimiter) {
    var delimiter = dirtyDelimiter || '';
    var sign = offset > 0 ? '-' : '+';
    var absOffset = Math.abs(offset);
    var hours = addLeadingZeros(Math.floor(absOffset / 60), 2);
    var minutes = addLeadingZeros(absOffset % 60, 2);
    return sign + hours + delimiter + minutes;
  }

  var formatters$1 = formatters;

  var dateLongFormatter = function dateLongFormatter(pattern, formatLong) {
    switch (pattern) {
      case 'P':
        return formatLong.date({
          width: 'short'
        });

      case 'PP':
        return formatLong.date({
          width: 'medium'
        });

      case 'PPP':
        return formatLong.date({
          width: 'long'
        });

      case 'PPPP':
      default:
        return formatLong.date({
          width: 'full'
        });
    }
  };

  var timeLongFormatter = function timeLongFormatter(pattern, formatLong) {
    switch (pattern) {
      case 'p':
        return formatLong.time({
          width: 'short'
        });

      case 'pp':
        return formatLong.time({
          width: 'medium'
        });

      case 'ppp':
        return formatLong.time({
          width: 'long'
        });

      case 'pppp':
      default:
        return formatLong.time({
          width: 'full'
        });
    }
  };

  var dateTimeLongFormatter = function dateTimeLongFormatter(pattern, formatLong) {
    var matchResult = pattern.match(/(P+)(p+)?/) || [];
    var datePattern = matchResult[1];
    var timePattern = matchResult[2];

    if (!timePattern) {
      return dateLongFormatter(pattern, formatLong);
    }

    var dateTimeFormat;

    switch (datePattern) {
      case 'P':
        dateTimeFormat = formatLong.dateTime({
          width: 'short'
        });
        break;

      case 'PP':
        dateTimeFormat = formatLong.dateTime({
          width: 'medium'
        });
        break;

      case 'PPP':
        dateTimeFormat = formatLong.dateTime({
          width: 'long'
        });
        break;

      case 'PPPP':
      default:
        dateTimeFormat = formatLong.dateTime({
          width: 'full'
        });
        break;
    }

    return dateTimeFormat.replace('{{date}}', dateLongFormatter(datePattern, formatLong)).replace('{{time}}', timeLongFormatter(timePattern, formatLong));
  };

  var longFormatters = {
    p: timeLongFormatter,
    P: dateTimeLongFormatter
  };
  var longFormatters$1 = longFormatters;

  var protectedDayOfYearTokens = ['D', 'DD'];
  var protectedWeekYearTokens = ['YY', 'YYYY'];
  function isProtectedDayOfYearToken(token) {
    return protectedDayOfYearTokens.indexOf(token) !== -1;
  }
  function isProtectedWeekYearToken(token) {
    return protectedWeekYearTokens.indexOf(token) !== -1;
  }
  function throwProtectedError(token, format, input) {
    if (token === 'YYYY') {
      throw new RangeError("Use `yyyy` instead of `YYYY` (in `".concat(format, "`) for formatting years to the input `").concat(input, "`; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md"));
    } else if (token === 'YY') {
      throw new RangeError("Use `yy` instead of `YY` (in `".concat(format, "`) for formatting years to the input `").concat(input, "`; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md"));
    } else if (token === 'D') {
      throw new RangeError("Use `d` instead of `D` (in `".concat(format, "`) for formatting days of the month to the input `").concat(input, "`; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md"));
    } else if (token === 'DD') {
      throw new RangeError("Use `dd` instead of `DD` (in `".concat(format, "`) for formatting days of the month to the input `").concat(input, "`; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md"));
    }
  }

  var formatDistanceLocale = {
    lessThanXSeconds: {
      one: 'less than a second',
      other: 'less than {{count}} seconds'
    },
    xSeconds: {
      one: '1 second',
      other: '{{count}} seconds'
    },
    halfAMinute: 'half a minute',
    lessThanXMinutes: {
      one: 'less than a minute',
      other: 'less than {{count}} minutes'
    },
    xMinutes: {
      one: '1 minute',
      other: '{{count}} minutes'
    },
    aboutXHours: {
      one: 'about 1 hour',
      other: 'about {{count}} hours'
    },
    xHours: {
      one: '1 hour',
      other: '{{count}} hours'
    },
    xDays: {
      one: '1 day',
      other: '{{count}} days'
    },
    aboutXWeeks: {
      one: 'about 1 week',
      other: 'about {{count}} weeks'
    },
    xWeeks: {
      one: '1 week',
      other: '{{count}} weeks'
    },
    aboutXMonths: {
      one: 'about 1 month',
      other: 'about {{count}} months'
    },
    xMonths: {
      one: '1 month',
      other: '{{count}} months'
    },
    aboutXYears: {
      one: 'about 1 year',
      other: 'about {{count}} years'
    },
    xYears: {
      one: '1 year',
      other: '{{count}} years'
    },
    overXYears: {
      one: 'over 1 year',
      other: 'over {{count}} years'
    },
    almostXYears: {
      one: 'almost 1 year',
      other: 'almost {{count}} years'
    }
  };

  var formatDistance = function formatDistance(token, count, options) {
    var result;
    var tokenValue = formatDistanceLocale[token];

    if (typeof tokenValue === 'string') {
      result = tokenValue;
    } else if (count === 1) {
      result = tokenValue.one;
    } else {
      result = tokenValue.other.replace('{{count}}', count.toString());
    }

    if (options !== null && options !== void 0 && options.addSuffix) {
      if (options.comparison && options.comparison > 0) {
        return 'in ' + result;
      } else {
        return result + ' ago';
      }
    }

    return result;
  };

  var formatDistance$1 = formatDistance;

  function buildFormatLongFn(args) {
    return function () {
      var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {}; // TODO: Remove String()

      var width = options.width ? String(options.width) : args.defaultWidth;
      var format = args.formats[width] || args.formats[args.defaultWidth];
      return format;
    };
  }

  var dateFormats = {
    full: 'EEEE, MMMM do, y',
    long: 'MMMM do, y',
    medium: 'MMM d, y',
    short: 'MM/dd/yyyy'
  };
  var timeFormats = {
    full: 'h:mm:ss a zzzz',
    long: 'h:mm:ss a z',
    medium: 'h:mm:ss a',
    short: 'h:mm a'
  };
  var dateTimeFormats = {
    full: "{{date}} 'at' {{time}}",
    long: "{{date}} 'at' {{time}}",
    medium: '{{date}}, {{time}}',
    short: '{{date}}, {{time}}'
  };
  var formatLong = {
    date: buildFormatLongFn({
      formats: dateFormats,
      defaultWidth: 'full'
    }),
    time: buildFormatLongFn({
      formats: timeFormats,
      defaultWidth: 'full'
    }),
    dateTime: buildFormatLongFn({
      formats: dateTimeFormats,
      defaultWidth: 'full'
    })
  };
  var formatLong$1 = formatLong;

  var formatRelativeLocale = {
    lastWeek: "'last' eeee 'at' p",
    yesterday: "'yesterday at' p",
    today: "'today at' p",
    tomorrow: "'tomorrow at' p",
    nextWeek: "eeee 'at' p",
    other: 'P'
  };

  var formatRelative = function formatRelative(token, _date, _baseDate, _options) {
    return formatRelativeLocale[token];
  };

  var formatRelative$1 = formatRelative;

  function buildLocalizeFn(args) {
    return function (dirtyIndex, options) {
      var context = options !== null && options !== void 0 && options.context ? String(options.context) : 'standalone';
      var valuesArray;

      if (context === 'formatting' && args.formattingValues) {
        var defaultWidth = args.defaultFormattingWidth || args.defaultWidth;
        var width = options !== null && options !== void 0 && options.width ? String(options.width) : defaultWidth;
        valuesArray = args.formattingValues[width] || args.formattingValues[defaultWidth];
      } else {
        var _defaultWidth = args.defaultWidth;

        var _width = options !== null && options !== void 0 && options.width ? String(options.width) : args.defaultWidth;

        valuesArray = args.values[_width] || args.values[_defaultWidth];
      }

      var index = args.argumentCallback ? args.argumentCallback(dirtyIndex) : dirtyIndex; // @ts-ignore: For some reason TypeScript just don't want to match it, no matter how hard we try. I challenge you to try to remove it!

      return valuesArray[index];
    };
  }

  var eraValues = {
    narrow: ['B', 'A'],
    abbreviated: ['BC', 'AD'],
    wide: ['Before Christ', 'Anno Domini']
  };
  var quarterValues = {
    narrow: ['1', '2', '3', '4'],
    abbreviated: ['Q1', 'Q2', 'Q3', 'Q4'],
    wide: ['1st quarter', '2nd quarter', '3rd quarter', '4th quarter']
  }; // Note: in English, the names of days of the week and months are capitalized.
  // If you are making a new locale based on this one, check if the same is true for the language you're working on.
  // Generally, formatted dates should look like they are in the middle of a sentence,
  // e.g. in Spanish language the weekdays and months should be in the lowercase.

  var monthValues = {
    narrow: ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'],
    abbreviated: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    wide: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
  };
  var dayValues = {
    narrow: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    short: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
    abbreviated: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    wide: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  };
  var dayPeriodValues = {
    narrow: {
      am: 'a',
      pm: 'p',
      midnight: 'mi',
      noon: 'n',
      morning: 'morning',
      afternoon: 'afternoon',
      evening: 'evening',
      night: 'night'
    },
    abbreviated: {
      am: 'AM',
      pm: 'PM',
      midnight: 'midnight',
      noon: 'noon',
      morning: 'morning',
      afternoon: 'afternoon',
      evening: 'evening',
      night: 'night'
    },
    wide: {
      am: 'a.m.',
      pm: 'p.m.',
      midnight: 'midnight',
      noon: 'noon',
      morning: 'morning',
      afternoon: 'afternoon',
      evening: 'evening',
      night: 'night'
    }
  };
  var formattingDayPeriodValues = {
    narrow: {
      am: 'a',
      pm: 'p',
      midnight: 'mi',
      noon: 'n',
      morning: 'in the morning',
      afternoon: 'in the afternoon',
      evening: 'in the evening',
      night: 'at night'
    },
    abbreviated: {
      am: 'AM',
      pm: 'PM',
      midnight: 'midnight',
      noon: 'noon',
      morning: 'in the morning',
      afternoon: 'in the afternoon',
      evening: 'in the evening',
      night: 'at night'
    },
    wide: {
      am: 'a.m.',
      pm: 'p.m.',
      midnight: 'midnight',
      noon: 'noon',
      morning: 'in the morning',
      afternoon: 'in the afternoon',
      evening: 'in the evening',
      night: 'at night'
    }
  };

  var ordinalNumber = function ordinalNumber(dirtyNumber, _options) {
    var number = Number(dirtyNumber); // If ordinal numbers depend on context, for example,
    // if they are different for different grammatical genders,
    // use `options.unit`.
    //
    // `unit` can be 'year', 'quarter', 'month', 'week', 'date', 'dayOfYear',
    // 'day', 'hour', 'minute', 'second'.

    var rem100 = number % 100;

    if (rem100 > 20 || rem100 < 10) {
      switch (rem100 % 10) {
        case 1:
          return number + 'st';

        case 2:
          return number + 'nd';

        case 3:
          return number + 'rd';
      }
    }

    return number + 'th';
  };

  var localize = {
    ordinalNumber: ordinalNumber,
    era: buildLocalizeFn({
      values: eraValues,
      defaultWidth: 'wide'
    }),
    quarter: buildLocalizeFn({
      values: quarterValues,
      defaultWidth: 'wide',
      argumentCallback: function argumentCallback(quarter) {
        return quarter - 1;
      }
    }),
    month: buildLocalizeFn({
      values: monthValues,
      defaultWidth: 'wide'
    }),
    day: buildLocalizeFn({
      values: dayValues,
      defaultWidth: 'wide'
    }),
    dayPeriod: buildLocalizeFn({
      values: dayPeriodValues,
      defaultWidth: 'wide',
      formattingValues: formattingDayPeriodValues,
      defaultFormattingWidth: 'wide'
    })
  };
  var localize$1 = localize;

  function buildMatchFn(args) {
    return function (string) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var width = options.width;
      var matchPattern = width && args.matchPatterns[width] || args.matchPatterns[args.defaultMatchWidth];
      var matchResult = string.match(matchPattern);

      if (!matchResult) {
        return null;
      }

      var matchedString = matchResult[0];
      var parsePatterns = width && args.parsePatterns[width] || args.parsePatterns[args.defaultParseWidth];
      var key = Array.isArray(parsePatterns) ? findIndex(parsePatterns, function (pattern) {
        return pattern.test(matchedString);
      }) : findKey(parsePatterns, function (pattern) {
        return pattern.test(matchedString);
      });
      var value;
      value = args.valueCallback ? args.valueCallback(key) : key;
      value = options.valueCallback ? options.valueCallback(value) : value;
      var rest = string.slice(matchedString.length);
      return {
        value: value,
        rest: rest
      };
    };
  }

  function findKey(object, predicate) {
    for (var key in object) {
      if (object.hasOwnProperty(key) && predicate(object[key])) {
        return key;
      }
    }

    return undefined;
  }

  function findIndex(array, predicate) {
    for (var key = 0; key < array.length; key++) {
      if (predicate(array[key])) {
        return key;
      }
    }

    return undefined;
  }

  function buildMatchPatternFn(args) {
    return function (string) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var matchResult = string.match(args.matchPattern);
      if (!matchResult) return null;
      var matchedString = matchResult[0];
      var parseResult = string.match(args.parsePattern);
      if (!parseResult) return null;
      var value = args.valueCallback ? args.valueCallback(parseResult[0]) : parseResult[0];
      value = options.valueCallback ? options.valueCallback(value) : value;
      var rest = string.slice(matchedString.length);
      return {
        value: value,
        rest: rest
      };
    };
  }

  var matchOrdinalNumberPattern = /^(\d+)(th|st|nd|rd)?/i;
  var parseOrdinalNumberPattern = /\d+/i;
  var matchEraPatterns = {
    narrow: /^(b|a)/i,
    abbreviated: /^(b\.?\s?c\.?|b\.?\s?c\.?\s?e\.?|a\.?\s?d\.?|c\.?\s?e\.?)/i,
    wide: /^(before christ|before common era|anno domini|common era)/i
  };
  var parseEraPatterns = {
    any: [/^b/i, /^(a|c)/i]
  };
  var matchQuarterPatterns = {
    narrow: /^[1234]/i,
    abbreviated: /^q[1234]/i,
    wide: /^[1234](th|st|nd|rd)? quarter/i
  };
  var parseQuarterPatterns = {
    any: [/1/i, /2/i, /3/i, /4/i]
  };
  var matchMonthPatterns = {
    narrow: /^[jfmasond]/i,
    abbreviated: /^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i,
    wide: /^(january|february|march|april|may|june|july|august|september|october|november|december)/i
  };
  var parseMonthPatterns = {
    narrow: [/^j/i, /^f/i, /^m/i, /^a/i, /^m/i, /^j/i, /^j/i, /^a/i, /^s/i, /^o/i, /^n/i, /^d/i],
    any: [/^ja/i, /^f/i, /^mar/i, /^ap/i, /^may/i, /^jun/i, /^jul/i, /^au/i, /^s/i, /^o/i, /^n/i, /^d/i]
  };
  var matchDayPatterns = {
    narrow: /^[smtwf]/i,
    short: /^(su|mo|tu|we|th|fr|sa)/i,
    abbreviated: /^(sun|mon|tue|wed|thu|fri|sat)/i,
    wide: /^(sunday|monday|tuesday|wednesday|thursday|friday|saturday)/i
  };
  var parseDayPatterns = {
    narrow: [/^s/i, /^m/i, /^t/i, /^w/i, /^t/i, /^f/i, /^s/i],
    any: [/^su/i, /^m/i, /^tu/i, /^w/i, /^th/i, /^f/i, /^sa/i]
  };
  var matchDayPeriodPatterns = {
    narrow: /^(a|p|mi|n|(in the|at) (morning|afternoon|evening|night))/i,
    any: /^([ap]\.?\s?m\.?|midnight|noon|(in the|at) (morning|afternoon|evening|night))/i
  };
  var parseDayPeriodPatterns = {
    any: {
      am: /^a/i,
      pm: /^p/i,
      midnight: /^mi/i,
      noon: /^no/i,
      morning: /morning/i,
      afternoon: /afternoon/i,
      evening: /evening/i,
      night: /night/i
    }
  };
  var match = {
    ordinalNumber: buildMatchPatternFn({
      matchPattern: matchOrdinalNumberPattern,
      parsePattern: parseOrdinalNumberPattern,
      valueCallback: function valueCallback(value) {
        return parseInt(value, 10);
      }
    }),
    era: buildMatchFn({
      matchPatterns: matchEraPatterns,
      defaultMatchWidth: 'wide',
      parsePatterns: parseEraPatterns,
      defaultParseWidth: 'any'
    }),
    quarter: buildMatchFn({
      matchPatterns: matchQuarterPatterns,
      defaultMatchWidth: 'wide',
      parsePatterns: parseQuarterPatterns,
      defaultParseWidth: 'any',
      valueCallback: function valueCallback(index) {
        return index + 1;
      }
    }),
    month: buildMatchFn({
      matchPatterns: matchMonthPatterns,
      defaultMatchWidth: 'wide',
      parsePatterns: parseMonthPatterns,
      defaultParseWidth: 'any'
    }),
    day: buildMatchFn({
      matchPatterns: matchDayPatterns,
      defaultMatchWidth: 'wide',
      parsePatterns: parseDayPatterns,
      defaultParseWidth: 'any'
    }),
    dayPeriod: buildMatchFn({
      matchPatterns: matchDayPeriodPatterns,
      defaultMatchWidth: 'any',
      parsePatterns: parseDayPeriodPatterns,
      defaultParseWidth: 'any'
    })
  };
  var match$1 = match;

  /**
   * @type {Locale}
   * @category Locales
   * @summary English locale (United States).
   * @language English
   * @iso-639-2 eng
   * @author Sasha Koss [@kossnocorp]{@link https://github.com/kossnocorp}
   * @author Lesha Koss [@leshakoss]{@link https://github.com/leshakoss}
   */

  var locale = {
    code: 'en-US',
    formatDistance: formatDistance$1,
    formatLong: formatLong$1,
    formatRelative: formatRelative$1,
    localize: localize$1,
    match: match$1,
    options: {
      weekStartsOn: 0
      /* Sunday */
      ,
      firstWeekContainsDate: 1
    }
  };
  var defaultLocale = locale;

  // - [yYQqMLwIdDecihHKkms]o matches any available ordinal number token
  //   (one of the certain letters followed by `o`)
  // - (\w)\1* matches any sequences of the same letter
  // - '' matches two quote characters in a row
  // - '(''|[^'])+('|$) matches anything surrounded by two quote characters ('),
  //   except a single quote symbol, which ends the sequence.
  //   Two quote characters do not end the sequence.
  //   If there is no matching single quote
  //   then the sequence will continue until the end of the string.
  // - . matches any single character unmatched by previous parts of the RegExps

  var formattingTokensRegExp$1 = /[yYQqMLwIdDecihHKkms]o|(\w)\1*|''|'(''|[^'])+('|$)|./g; // This RegExp catches symbols escaped by quotes, and also
  // sequences of symbols P, p, and the combinations like `PPPPPPPppppp`

  var longFormattingTokensRegExp$1 = /P+p+|P+|p+|''|'(''|[^'])+('|$)|./g;
  var escapedStringRegExp$1 = /^'([^]*?)'?$/;
  var doubleQuoteRegExp$1 = /''/g;
  var unescapedLatinCharacterRegExp$1 = /[a-zA-Z]/;
  /**
   * @name format
   * @category Common Helpers
   * @summary Format the date.
   *
   * @description
   * Return the formatted date string in the given format. The result may vary by locale.
   *
   * > ⚠️ Please note that the `format` tokens differ from Moment.js and other libraries.
   * > See: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   *
   * The characters wrapped between two single quotes characters (') are escaped.
   * Two single quotes in a row, whether inside or outside a quoted sequence, represent a 'real' single quote.
   * (see the last example)
   *
   * Format of the string is based on Unicode Technical Standard #35:
   * https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
   * with a few additions (see note 7 below the table).
   *
   * Accepted patterns:
   * | Unit                            | Pattern | Result examples                   | Notes |
   * |---------------------------------|---------|-----------------------------------|-------|
   * | Era                             | G..GGG  | AD, BC                            |       |
   * |                                 | GGGG    | Anno Domini, Before Christ        | 2     |
   * |                                 | GGGGG   | A, B                              |       |
   * | Calendar year                   | y       | 44, 1, 1900, 2017                 | 5     |
   * |                                 | yo      | 44th, 1st, 0th, 17th              | 5,7   |
   * |                                 | yy      | 44, 01, 00, 17                    | 5     |
   * |                                 | yyy     | 044, 001, 1900, 2017              | 5     |
   * |                                 | yyyy    | 0044, 0001, 1900, 2017            | 5     |
   * |                                 | yyyyy   | ...                               | 3,5   |
   * | Local week-numbering year       | Y       | 44, 1, 1900, 2017                 | 5     |
   * |                                 | Yo      | 44th, 1st, 1900th, 2017th         | 5,7   |
   * |                                 | YY      | 44, 01, 00, 17                    | 5,8   |
   * |                                 | YYY     | 044, 001, 1900, 2017              | 5     |
   * |                                 | YYYY    | 0044, 0001, 1900, 2017            | 5,8   |
   * |                                 | YYYYY   | ...                               | 3,5   |
   * | ISO week-numbering year         | R       | -43, 0, 1, 1900, 2017             | 5,7   |
   * |                                 | RR      | -43, 00, 01, 1900, 2017           | 5,7   |
   * |                                 | RRR     | -043, 000, 001, 1900, 2017        | 5,7   |
   * |                                 | RRRR    | -0043, 0000, 0001, 1900, 2017     | 5,7   |
   * |                                 | RRRRR   | ...                               | 3,5,7 |
   * | Extended year                   | u       | -43, 0, 1, 1900, 2017             | 5     |
   * |                                 | uu      | -43, 01, 1900, 2017               | 5     |
   * |                                 | uuu     | -043, 001, 1900, 2017             | 5     |
   * |                                 | uuuu    | -0043, 0001, 1900, 2017           | 5     |
   * |                                 | uuuuu   | ...                               | 3,5   |
   * | Quarter (formatting)            | Q       | 1, 2, 3, 4                        |       |
   * |                                 | Qo      | 1st, 2nd, 3rd, 4th                | 7     |
   * |                                 | QQ      | 01, 02, 03, 04                    |       |
   * |                                 | QQQ     | Q1, Q2, Q3, Q4                    |       |
   * |                                 | QQQQ    | 1st quarter, 2nd quarter, ...     | 2     |
   * |                                 | QQQQQ   | 1, 2, 3, 4                        | 4     |
   * | Quarter (stand-alone)           | q       | 1, 2, 3, 4                        |       |
   * |                                 | qo      | 1st, 2nd, 3rd, 4th                | 7     |
   * |                                 | qq      | 01, 02, 03, 04                    |       |
   * |                                 | qqq     | Q1, Q2, Q3, Q4                    |       |
   * |                                 | qqqq    | 1st quarter, 2nd quarter, ...     | 2     |
   * |                                 | qqqqq   | 1, 2, 3, 4                        | 4     |
   * | Month (formatting)              | M       | 1, 2, ..., 12                     |       |
   * |                                 | Mo      | 1st, 2nd, ..., 12th               | 7     |
   * |                                 | MM      | 01, 02, ..., 12                   |       |
   * |                                 | MMM     | Jan, Feb, ..., Dec                |       |
   * |                                 | MMMM    | January, February, ..., December  | 2     |
   * |                                 | MMMMM   | J, F, ..., D                      |       |
   * | Month (stand-alone)             | L       | 1, 2, ..., 12                     |       |
   * |                                 | Lo      | 1st, 2nd, ..., 12th               | 7     |
   * |                                 | LL      | 01, 02, ..., 12                   |       |
   * |                                 | LLL     | Jan, Feb, ..., Dec                |       |
   * |                                 | LLLL    | January, February, ..., December  | 2     |
   * |                                 | LLLLL   | J, F, ..., D                      |       |
   * | Local week of year              | w       | 1, 2, ..., 53                     |       |
   * |                                 | wo      | 1st, 2nd, ..., 53th               | 7     |
   * |                                 | ww      | 01, 02, ..., 53                   |       |
   * | ISO week of year                | I       | 1, 2, ..., 53                     | 7     |
   * |                                 | Io      | 1st, 2nd, ..., 53th               | 7     |
   * |                                 | II      | 01, 02, ..., 53                   | 7     |
   * | Day of month                    | d       | 1, 2, ..., 31                     |       |
   * |                                 | do      | 1st, 2nd, ..., 31st               | 7     |
   * |                                 | dd      | 01, 02, ..., 31                   |       |
   * | Day of year                     | D       | 1, 2, ..., 365, 366               | 9     |
   * |                                 | Do      | 1st, 2nd, ..., 365th, 366th       | 7     |
   * |                                 | DD      | 01, 02, ..., 365, 366             | 9     |
   * |                                 | DDD     | 001, 002, ..., 365, 366           |       |
   * |                                 | DDDD    | ...                               | 3     |
   * | Day of week (formatting)        | E..EEE  | Mon, Tue, Wed, ..., Sun           |       |
   * |                                 | EEEE    | Monday, Tuesday, ..., Sunday      | 2     |
   * |                                 | EEEEE   | M, T, W, T, F, S, S               |       |
   * |                                 | EEEEEE  | Mo, Tu, We, Th, Fr, Sa, Su        |       |
   * | ISO day of week (formatting)    | i       | 1, 2, 3, ..., 7                   | 7     |
   * |                                 | io      | 1st, 2nd, ..., 7th                | 7     |
   * |                                 | ii      | 01, 02, ..., 07                   | 7     |
   * |                                 | iii     | Mon, Tue, Wed, ..., Sun           | 7     |
   * |                                 | iiii    | Monday, Tuesday, ..., Sunday      | 2,7   |
   * |                                 | iiiii   | M, T, W, T, F, S, S               | 7     |
   * |                                 | iiiiii  | Mo, Tu, We, Th, Fr, Sa, Su        | 7     |
   * | Local day of week (formatting)  | e       | 2, 3, 4, ..., 1                   |       |
   * |                                 | eo      | 2nd, 3rd, ..., 1st                | 7     |
   * |                                 | ee      | 02, 03, ..., 01                   |       |
   * |                                 | eee     | Mon, Tue, Wed, ..., Sun           |       |
   * |                                 | eeee    | Monday, Tuesday, ..., Sunday      | 2     |
   * |                                 | eeeee   | M, T, W, T, F, S, S               |       |
   * |                                 | eeeeee  | Mo, Tu, We, Th, Fr, Sa, Su        |       |
   * | Local day of week (stand-alone) | c       | 2, 3, 4, ..., 1                   |       |
   * |                                 | co      | 2nd, 3rd, ..., 1st                | 7     |
   * |                                 | cc      | 02, 03, ..., 01                   |       |
   * |                                 | ccc     | Mon, Tue, Wed, ..., Sun           |       |
   * |                                 | cccc    | Monday, Tuesday, ..., Sunday      | 2     |
   * |                                 | ccccc   | M, T, W, T, F, S, S               |       |
   * |                                 | cccccc  | Mo, Tu, We, Th, Fr, Sa, Su        |       |
   * | AM, PM                          | a..aa   | AM, PM                            |       |
   * |                                 | aaa     | am, pm                            |       |
   * |                                 | aaaa    | a.m., p.m.                        | 2     |
   * |                                 | aaaaa   | a, p                              |       |
   * | AM, PM, noon, midnight          | b..bb   | AM, PM, noon, midnight            |       |
   * |                                 | bbb     | am, pm, noon, midnight            |       |
   * |                                 | bbbb    | a.m., p.m., noon, midnight        | 2     |
   * |                                 | bbbbb   | a, p, n, mi                       |       |
   * | Flexible day period             | B..BBB  | at night, in the morning, ...     |       |
   * |                                 | BBBB    | at night, in the morning, ...     | 2     |
   * |                                 | BBBBB   | at night, in the morning, ...     |       |
   * | Hour [1-12]                     | h       | 1, 2, ..., 11, 12                 |       |
   * |                                 | ho      | 1st, 2nd, ..., 11th, 12th         | 7     |
   * |                                 | hh      | 01, 02, ..., 11, 12               |       |
   * | Hour [0-23]                     | H       | 0, 1, 2, ..., 23                  |       |
   * |                                 | Ho      | 0th, 1st, 2nd, ..., 23rd          | 7     |
   * |                                 | HH      | 00, 01, 02, ..., 23               |       |
   * | Hour [0-11]                     | K       | 1, 2, ..., 11, 0                  |       |
   * |                                 | Ko      | 1st, 2nd, ..., 11th, 0th          | 7     |
   * |                                 | KK      | 01, 02, ..., 11, 00               |       |
   * | Hour [1-24]                     | k       | 24, 1, 2, ..., 23                 |       |
   * |                                 | ko      | 24th, 1st, 2nd, ..., 23rd         | 7     |
   * |                                 | kk      | 24, 01, 02, ..., 23               |       |
   * | Minute                          | m       | 0, 1, ..., 59                     |       |
   * |                                 | mo      | 0th, 1st, ..., 59th               | 7     |
   * |                                 | mm      | 00, 01, ..., 59                   |       |
   * | Second                          | s       | 0, 1, ..., 59                     |       |
   * |                                 | so      | 0th, 1st, ..., 59th               | 7     |
   * |                                 | ss      | 00, 01, ..., 59                   |       |
   * | Fraction of second              | S       | 0, 1, ..., 9                      |       |
   * |                                 | SS      | 00, 01, ..., 99                   |       |
   * |                                 | SSS     | 000, 001, ..., 999                |       |
   * |                                 | SSSS    | ...                               | 3     |
   * | Timezone (ISO-8601 w/ Z)        | X       | -08, +0530, Z                     |       |
   * |                                 | XX      | -0800, +0530, Z                   |       |
   * |                                 | XXX     | -08:00, +05:30, Z                 |       |
   * |                                 | XXXX    | -0800, +0530, Z, +123456          | 2     |
   * |                                 | XXXXX   | -08:00, +05:30, Z, +12:34:56      |       |
   * | Timezone (ISO-8601 w/o Z)       | x       | -08, +0530, +00                   |       |
   * |                                 | xx      | -0800, +0530, +0000               |       |
   * |                                 | xxx     | -08:00, +05:30, +00:00            | 2     |
   * |                                 | xxxx    | -0800, +0530, +0000, +123456      |       |
   * |                                 | xxxxx   | -08:00, +05:30, +00:00, +12:34:56 |       |
   * | Timezone (GMT)                  | O...OOO | GMT-8, GMT+5:30, GMT+0            |       |
   * |                                 | OOOO    | GMT-08:00, GMT+05:30, GMT+00:00   | 2     |
   * | Timezone (specific non-locat.)  | z...zzz | GMT-8, GMT+5:30, GMT+0            | 6     |
   * |                                 | zzzz    | GMT-08:00, GMT+05:30, GMT+00:00   | 2,6   |
   * | Seconds timestamp               | t       | 512969520                         | 7     |
   * |                                 | tt      | ...                               | 3,7   |
   * | Milliseconds timestamp          | T       | 512969520900                      | 7     |
   * |                                 | TT      | ...                               | 3,7   |
   * | Long localized date             | P       | 04/29/1453                        | 7     |
   * |                                 | PP      | Apr 29, 1453                      | 7     |
   * |                                 | PPP     | April 29th, 1453                  | 7     |
   * |                                 | PPPP    | Friday, April 29th, 1453          | 2,7   |
   * | Long localized time             | p       | 12:00 AM                          | 7     |
   * |                                 | pp      | 12:00:00 AM                       | 7     |
   * |                                 | ppp     | 12:00:00 AM GMT+2                 | 7     |
   * |                                 | pppp    | 12:00:00 AM GMT+02:00             | 2,7   |
   * | Combination of date and time    | Pp      | 04/29/1453, 12:00 AM              | 7     |
   * |                                 | PPpp    | Apr 29, 1453, 12:00:00 AM         | 7     |
   * |                                 | PPPppp  | April 29th, 1453 at ...           | 7     |
   * |                                 | PPPPpppp| Friday, April 29th, 1453 at ...   | 2,7   |
   * Notes:
   * 1. "Formatting" units (e.g. formatting quarter) in the default en-US locale
   *    are the same as "stand-alone" units, but are different in some languages.
   *    "Formatting" units are declined according to the rules of the language
   *    in the context of a date. "Stand-alone" units are always nominative singular:
   *
   *    `format(new Date(2017, 10, 6), 'do LLLL', {locale: cs}) //=> '6. listopad'`
   *
   *    `format(new Date(2017, 10, 6), 'do MMMM', {locale: cs}) //=> '6. listopadu'`
   *
   * 2. Any sequence of the identical letters is a pattern, unless it is escaped by
   *    the single quote characters (see below).
   *    If the sequence is longer than listed in table (e.g. `EEEEEEEEEEE`)
   *    the output will be the same as default pattern for this unit, usually
   *    the longest one (in case of ISO weekdays, `EEEE`). Default patterns for units
   *    are marked with "2" in the last column of the table.
   *
   *    `format(new Date(2017, 10, 6), 'MMM') //=> 'Nov'`
   *
   *    `format(new Date(2017, 10, 6), 'MMMM') //=> 'November'`
   *
   *    `format(new Date(2017, 10, 6), 'MMMMM') //=> 'N'`
   *
   *    `format(new Date(2017, 10, 6), 'MMMMMM') //=> 'November'`
   *
   *    `format(new Date(2017, 10, 6), 'MMMMMMM') //=> 'November'`
   *
   * 3. Some patterns could be unlimited length (such as `yyyyyyyy`).
   *    The output will be padded with zeros to match the length of the pattern.
   *
   *    `format(new Date(2017, 10, 6), 'yyyyyyyy') //=> '00002017'`
   *
   * 4. `QQQQQ` and `qqqqq` could be not strictly numerical in some locales.
   *    These tokens represent the shortest form of the quarter.
   *
   * 5. The main difference between `y` and `u` patterns are B.C. years:
   *
   *    | Year | `y` | `u` |
   *    |------|-----|-----|
   *    | AC 1 |   1 |   1 |
   *    | BC 1 |   1 |   0 |
   *    | BC 2 |   2 |  -1 |
   *
   *    Also `yy` always returns the last two digits of a year,
   *    while `uu` pads single digit years to 2 characters and returns other years unchanged:
   *
   *    | Year | `yy` | `uu` |
   *    |------|------|------|
   *    | 1    |   01 |   01 |
   *    | 14   |   14 |   14 |
   *    | 376  |   76 |  376 |
   *    | 1453 |   53 | 1453 |
   *
   *    The same difference is true for local and ISO week-numbering years (`Y` and `R`),
   *    except local week-numbering years are dependent on `options.weekStartsOn`
   *    and `options.firstWeekContainsDate` (compare [getISOWeekYear]{@link https://date-fns.org/docs/getISOWeekYear}
   *    and [getWeekYear]{@link https://date-fns.org/docs/getWeekYear}).
   *
   * 6. Specific non-location timezones are currently unavailable in `date-fns`,
   *    so right now these tokens fall back to GMT timezones.
   *
   * 7. These patterns are not in the Unicode Technical Standard #35:
   *    - `i`: ISO day of week
   *    - `I`: ISO week of year
   *    - `R`: ISO week-numbering year
   *    - `t`: seconds timestamp
   *    - `T`: milliseconds timestamp
   *    - `o`: ordinal number modifier
   *    - `P`: long localized date
   *    - `p`: long localized time
   *
   * 8. `YY` and `YYYY` tokens represent week-numbering years but they are often confused with years.
   *    You should enable `options.useAdditionalWeekYearTokens` to use them. See: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   *
   * 9. `D` and `DD` tokens represent days of the year but they are often confused with days of the month.
   *    You should enable `options.useAdditionalDayOfYearTokens` to use them. See: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   *
   * @param {Date|Number} date - the original date
   * @param {String} format - the string of tokens
   * @param {Object} [options] - an object with options.
   * @param {Locale} [options.locale=defaultLocale] - the locale object. See [Locale]{@link https://date-fns.org/docs/Locale}
   * @param {0|1|2|3|4|5|6} [options.weekStartsOn=0] - the index of the first day of the week (0 - Sunday)
   * @param {Number} [options.firstWeekContainsDate=1] - the day of January, which is
   * @param {Boolean} [options.useAdditionalWeekYearTokens=false] - if true, allows usage of the week-numbering year tokens `YY` and `YYYY`;
   *   see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @param {Boolean} [options.useAdditionalDayOfYearTokens=false] - if true, allows usage of the day of year tokens `D` and `DD`;
   *   see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @returns {String} the formatted date string
   * @throws {TypeError} 2 arguments required
   * @throws {RangeError} `date` must not be Invalid Date
   * @throws {RangeError} `options.locale` must contain `localize` property
   * @throws {RangeError} `options.locale` must contain `formatLong` property
   * @throws {RangeError} `options.weekStartsOn` must be between 0 and 6
   * @throws {RangeError} `options.firstWeekContainsDate` must be between 1 and 7
   * @throws {RangeError} use `yyyy` instead of `YYYY` for formatting years using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} use `yy` instead of `YY` for formatting years using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} use `d` instead of `D` for formatting days of the month using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} use `dd` instead of `DD` for formatting days of the month using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} format string contains an unescaped latin alphabet character
   *
   * @example
   * // Represent 11 February 2014 in middle-endian format:
   * const result = format(new Date(2014, 1, 11), 'MM/dd/yyyy')
   * //=> '02/11/2014'
   *
   * @example
   * // Represent 2 July 2014 in Esperanto:
   * import { eoLocale } from 'date-fns/locale/eo'
   * const result = format(new Date(2014, 6, 2), "do 'de' MMMM yyyy", {
   *   locale: eoLocale
   * })
   * //=> '2-a de julio 2014'
   *
   * @example
   * // Escape string by single quote characters:
   * const result = format(new Date(2014, 6, 2, 15), "h 'o''clock'")
   * //=> "3 o'clock"
   */

  function format(dirtyDate, dirtyFormatStr, options) {
    var _ref, _options$locale, _ref2, _ref3, _ref4, _options$firstWeekCon, _options$locale2, _options$locale2$opti, _defaultOptions$local, _defaultOptions$local2, _ref5, _ref6, _ref7, _options$weekStartsOn, _options$locale3, _options$locale3$opti, _defaultOptions$local3, _defaultOptions$local4;

    requiredArgs(2, arguments);
    var formatStr = String(dirtyFormatStr);
    var defaultOptions = getDefaultOptions();
    var locale = (_ref = (_options$locale = options === null || options === void 0 ? void 0 : options.locale) !== null && _options$locale !== void 0 ? _options$locale : defaultOptions.locale) !== null && _ref !== void 0 ? _ref : defaultLocale;
    var firstWeekContainsDate = toInteger((_ref2 = (_ref3 = (_ref4 = (_options$firstWeekCon = options === null || options === void 0 ? void 0 : options.firstWeekContainsDate) !== null && _options$firstWeekCon !== void 0 ? _options$firstWeekCon : options === null || options === void 0 ? void 0 : (_options$locale2 = options.locale) === null || _options$locale2 === void 0 ? void 0 : (_options$locale2$opti = _options$locale2.options) === null || _options$locale2$opti === void 0 ? void 0 : _options$locale2$opti.firstWeekContainsDate) !== null && _ref4 !== void 0 ? _ref4 : defaultOptions.firstWeekContainsDate) !== null && _ref3 !== void 0 ? _ref3 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.firstWeekContainsDate) !== null && _ref2 !== void 0 ? _ref2 : 1); // Test if weekStartsOn is between 1 and 7 _and_ is not NaN

    if (!(firstWeekContainsDate >= 1 && firstWeekContainsDate <= 7)) {
      throw new RangeError('firstWeekContainsDate must be between 1 and 7 inclusively');
    }

    var weekStartsOn = toInteger((_ref5 = (_ref6 = (_ref7 = (_options$weekStartsOn = options === null || options === void 0 ? void 0 : options.weekStartsOn) !== null && _options$weekStartsOn !== void 0 ? _options$weekStartsOn : options === null || options === void 0 ? void 0 : (_options$locale3 = options.locale) === null || _options$locale3 === void 0 ? void 0 : (_options$locale3$opti = _options$locale3.options) === null || _options$locale3$opti === void 0 ? void 0 : _options$locale3$opti.weekStartsOn) !== null && _ref7 !== void 0 ? _ref7 : defaultOptions.weekStartsOn) !== null && _ref6 !== void 0 ? _ref6 : (_defaultOptions$local3 = defaultOptions.locale) === null || _defaultOptions$local3 === void 0 ? void 0 : (_defaultOptions$local4 = _defaultOptions$local3.options) === null || _defaultOptions$local4 === void 0 ? void 0 : _defaultOptions$local4.weekStartsOn) !== null && _ref5 !== void 0 ? _ref5 : 0); // Test if weekStartsOn is between 0 and 6 _and_ is not NaN

    if (!(weekStartsOn >= 0 && weekStartsOn <= 6)) {
      throw new RangeError('weekStartsOn must be between 0 and 6 inclusively');
    }

    if (!locale.localize) {
      throw new RangeError('locale must contain localize property');
    }

    if (!locale.formatLong) {
      throw new RangeError('locale must contain formatLong property');
    }

    var originalDate = toDate(dirtyDate);

    if (!isValid(originalDate)) {
      throw new RangeError('Invalid time value');
    } // Convert the date in system timezone to the same date in UTC+00:00 timezone.
    // This ensures that when UTC functions will be implemented, locales will be compatible with them.
    // See an issue about UTC functions: https://github.com/date-fns/date-fns/issues/376


    var timezoneOffset = getTimezoneOffsetInMilliseconds(originalDate);
    var utcDate = subMilliseconds(originalDate, timezoneOffset);
    var formatterOptions = {
      firstWeekContainsDate: firstWeekContainsDate,
      weekStartsOn: weekStartsOn,
      locale: locale,
      _originalDate: originalDate
    };
    var result = formatStr.match(longFormattingTokensRegExp$1).map(function (substring) {
      var firstCharacter = substring[0];

      if (firstCharacter === 'p' || firstCharacter === 'P') {
        var longFormatter = longFormatters$1[firstCharacter];
        return longFormatter(substring, locale.formatLong);
      }

      return substring;
    }).join('').match(formattingTokensRegExp$1).map(function (substring) {
      // Replace two single quote characters with one single quote character
      if (substring === "''") {
        return "'";
      }

      var firstCharacter = substring[0];

      if (firstCharacter === "'") {
        return cleanEscapedString$1(substring);
      }

      var formatter = formatters$1[firstCharacter];

      if (formatter) {
        if (!(options !== null && options !== void 0 && options.useAdditionalWeekYearTokens) && isProtectedWeekYearToken(substring)) {
          throwProtectedError(substring, dirtyFormatStr, String(dirtyDate));
        }

        if (!(options !== null && options !== void 0 && options.useAdditionalDayOfYearTokens) && isProtectedDayOfYearToken(substring)) {
          throwProtectedError(substring, dirtyFormatStr, String(dirtyDate));
        }

        return formatter(utcDate, substring, locale.localize, formatterOptions);
      }

      if (firstCharacter.match(unescapedLatinCharacterRegExp$1)) {
        throw new RangeError('Format string contains an unescaped latin alphabet character `' + firstCharacter + '`');
      }

      return substring;
    }).join('');
    return result;
  }

  function cleanEscapedString$1(input) {
    var matched = input.match(escapedStringRegExp$1);

    if (!matched) {
      return input;
    }

    return matched[1].replace(doubleQuoteRegExp$1, "'");
  }

  function assign(target, object) {
    if (target == null) {
      throw new TypeError('assign requires that input parameter not be null or undefined');
    }

    for (var property in object) {
      if (Object.prototype.hasOwnProperty.call(object, property)) {
        target[property] = object[property];
      }
    }

    return target;
  }

  function _defineProperty$w(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var TIMEZONE_UNIT_PRIORITY = 10;
  var Setter = /*#__PURE__*/function () {
    function Setter() {
      _classCallCheck(this, Setter);

      _defineProperty$w(this, "priority", void 0);

      _defineProperty$w(this, "subPriority", 0);
    }

    _createClass(Setter, [{
      key: "validate",
      value: function validate(_utcDate, _options) {
        return true;
      }
    }]);

    return Setter;
  }();
  var ValueSetter = /*#__PURE__*/function (_Setter) {
    _inherits(ValueSetter, _Setter);

    var _super = _createSuper(ValueSetter);

    function ValueSetter(value, validateValue, setValue, priority, subPriority) {
      var _this;

      _classCallCheck(this, ValueSetter);

      _this = _super.call(this);
      _this.value = value;
      _this.validateValue = validateValue;
      _this.setValue = setValue;
      _this.priority = priority;

      if (subPriority) {
        _this.subPriority = subPriority;
      }

      return _this;
    }

    _createClass(ValueSetter, [{
      key: "validate",
      value: function validate(utcDate, options) {
        return this.validateValue(utcDate, this.value, options);
      }
    }, {
      key: "set",
      value: function set(utcDate, flags, options) {
        return this.setValue(utcDate, flags, this.value, options);
      }
    }]);

    return ValueSetter;
  }(Setter);
  var DateToSystemTimezoneSetter = /*#__PURE__*/function (_Setter2) {
    _inherits(DateToSystemTimezoneSetter, _Setter2);

    var _super2 = _createSuper(DateToSystemTimezoneSetter);

    function DateToSystemTimezoneSetter() {
      var _this2;

      _classCallCheck(this, DateToSystemTimezoneSetter);

      _this2 = _super2.apply(this, arguments);

      _defineProperty$w(_assertThisInitialized(_this2), "priority", TIMEZONE_UNIT_PRIORITY);

      _defineProperty$w(_assertThisInitialized(_this2), "subPriority", -1);

      return _this2;
    }

    _createClass(DateToSystemTimezoneSetter, [{
      key: "set",
      value: function set(date, flags) {
        if (flags.timestampIsSet) {
          return date;
        }

        var convertedDate = new Date(0);
        convertedDate.setFullYear(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
        convertedDate.setHours(date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds(), date.getUTCMilliseconds());
        return convertedDate;
      }
    }]);

    return DateToSystemTimezoneSetter;
  }(Setter);

  function _defineProperty$v(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var Parser = /*#__PURE__*/function () {
    function Parser() {
      _classCallCheck(this, Parser);

      _defineProperty$v(this, "incompatibleTokens", void 0);

      _defineProperty$v(this, "priority", void 0);

      _defineProperty$v(this, "subPriority", void 0);
    }

    _createClass(Parser, [{
      key: "run",
      value: function run(dateString, token, match, options) {
        var result = this.parse(dateString, token, match, options);

        if (!result) {
          return null;
        }

        return {
          setter: new ValueSetter(result.value, this.validate, this.set, this.priority, this.subPriority),
          rest: result.rest
        };
      }
    }, {
      key: "validate",
      value: function validate(_utcDate, _value, _options) {
        return true;
      }
    }]);

    return Parser;
  }();

  function _defineProperty$u(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var EraParser = /*#__PURE__*/function (_Parser) {
    _inherits(EraParser, _Parser);

    var _super = _createSuper(EraParser);

    function EraParser() {
      var _this;

      _classCallCheck(this, EraParser);

      _this = _super.apply(this, arguments);

      _defineProperty$u(_assertThisInitialized(_this), "priority", 140);

      _defineProperty$u(_assertThisInitialized(_this), "incompatibleTokens", ['R', 'u', 't', 'T']);

      return _this;
    }

    _createClass(EraParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          // AD, BC
          case 'G':
          case 'GG':
          case 'GGG':
            return match.era(dateString, {
              width: 'abbreviated'
            }) || match.era(dateString, {
              width: 'narrow'
            });
          // A, B

          case 'GGGGG':
            return match.era(dateString, {
              width: 'narrow'
            });
          // Anno Domini, Before Christ

          case 'GGGG':
          default:
            return match.era(dateString, {
              width: 'wide'
            }) || match.era(dateString, {
              width: 'abbreviated'
            }) || match.era(dateString, {
              width: 'narrow'
            });
        }
      }
    }, {
      key: "set",
      value: function set(date, flags, value) {
        flags.era = value;
        date.setUTCFullYear(value, 0, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return EraParser;
  }(Parser);

  var numericPatterns = {
    month: /^(1[0-2]|0?\d)/,
    // 0 to 12
    date: /^(3[0-1]|[0-2]?\d)/,
    // 0 to 31
    dayOfYear: /^(36[0-6]|3[0-5]\d|[0-2]?\d?\d)/,
    // 0 to 366
    week: /^(5[0-3]|[0-4]?\d)/,
    // 0 to 53
    hour23h: /^(2[0-3]|[0-1]?\d)/,
    // 0 to 23
    hour24h: /^(2[0-4]|[0-1]?\d)/,
    // 0 to 24
    hour11h: /^(1[0-1]|0?\d)/,
    // 0 to 11
    hour12h: /^(1[0-2]|0?\d)/,
    // 0 to 12
    minute: /^[0-5]?\d/,
    // 0 to 59
    second: /^[0-5]?\d/,
    // 0 to 59
    singleDigit: /^\d/,
    // 0 to 9
    twoDigits: /^\d{1,2}/,
    // 0 to 99
    threeDigits: /^\d{1,3}/,
    // 0 to 999
    fourDigits: /^\d{1,4}/,
    // 0 to 9999
    anyDigitsSigned: /^-?\d+/,
    singleDigitSigned: /^-?\d/,
    // 0 to 9, -0 to -9
    twoDigitsSigned: /^-?\d{1,2}/,
    // 0 to 99, -0 to -99
    threeDigitsSigned: /^-?\d{1,3}/,
    // 0 to 999, -0 to -999
    fourDigitsSigned: /^-?\d{1,4}/ // 0 to 9999, -0 to -9999

  };
  var timezonePatterns = {
    basicOptionalMinutes: /^([+-])(\d{2})(\d{2})?|Z/,
    basic: /^([+-])(\d{2})(\d{2})|Z/,
    basicOptionalSeconds: /^([+-])(\d{2})(\d{2})((\d{2}))?|Z/,
    extended: /^([+-])(\d{2}):(\d{2})|Z/,
    extendedOptionalSeconds: /^([+-])(\d{2}):(\d{2})(:(\d{2}))?|Z/
  };

  function mapValue(parseFnResult, mapFn) {
    if (!parseFnResult) {
      return parseFnResult;
    }

    return {
      value: mapFn(parseFnResult.value),
      rest: parseFnResult.rest
    };
  }
  function parseNumericPattern(pattern, dateString) {
    var matchResult = dateString.match(pattern);

    if (!matchResult) {
      return null;
    }

    return {
      value: parseInt(matchResult[0], 10),
      rest: dateString.slice(matchResult[0].length)
    };
  }
  function parseTimezonePattern(pattern, dateString) {
    var matchResult = dateString.match(pattern);

    if (!matchResult) {
      return null;
    } // Input is 'Z'


    if (matchResult[0] === 'Z') {
      return {
        value: 0,
        rest: dateString.slice(1)
      };
    }

    var sign = matchResult[1] === '+' ? 1 : -1;
    var hours = matchResult[2] ? parseInt(matchResult[2], 10) : 0;
    var minutes = matchResult[3] ? parseInt(matchResult[3], 10) : 0;
    var seconds = matchResult[5] ? parseInt(matchResult[5], 10) : 0;
    return {
      value: sign * (hours * millisecondsInHour + minutes * millisecondsInMinute + seconds * millisecondsInSecond),
      rest: dateString.slice(matchResult[0].length)
    };
  }
  function parseAnyDigitsSigned(dateString) {
    return parseNumericPattern(numericPatterns.anyDigitsSigned, dateString);
  }
  function parseNDigits(n, dateString) {
    switch (n) {
      case 1:
        return parseNumericPattern(numericPatterns.singleDigit, dateString);

      case 2:
        return parseNumericPattern(numericPatterns.twoDigits, dateString);

      case 3:
        return parseNumericPattern(numericPatterns.threeDigits, dateString);

      case 4:
        return parseNumericPattern(numericPatterns.fourDigits, dateString);

      default:
        return parseNumericPattern(new RegExp('^\\d{1,' + n + '}'), dateString);
    }
  }
  function parseNDigitsSigned(n, dateString) {
    switch (n) {
      case 1:
        return parseNumericPattern(numericPatterns.singleDigitSigned, dateString);

      case 2:
        return parseNumericPattern(numericPatterns.twoDigitsSigned, dateString);

      case 3:
        return parseNumericPattern(numericPatterns.threeDigitsSigned, dateString);

      case 4:
        return parseNumericPattern(numericPatterns.fourDigitsSigned, dateString);

      default:
        return parseNumericPattern(new RegExp('^-?\\d{1,' + n + '}'), dateString);
    }
  }
  function dayPeriodEnumToHours(dayPeriod) {
    switch (dayPeriod) {
      case 'morning':
        return 4;

      case 'evening':
        return 17;

      case 'pm':
      case 'noon':
      case 'afternoon':
        return 12;

      case 'am':
      case 'midnight':
      case 'night':
      default:
        return 0;
    }
  }
  function normalizeTwoDigitYear(twoDigitYear, currentYear) {
    var isCommonEra = currentYear > 0; // Absolute number of the current year:
    // 1 -> 1 AC
    // 0 -> 1 BC
    // -1 -> 2 BC

    var absCurrentYear = isCommonEra ? currentYear : 1 - currentYear;
    var result;

    if (absCurrentYear <= 50) {
      result = twoDigitYear || 100;
    } else {
      var rangeEnd = absCurrentYear + 50;
      var rangeEndCentury = Math.floor(rangeEnd / 100) * 100;
      var isPreviousCentury = twoDigitYear >= rangeEnd % 100;
      result = twoDigitYear + rangeEndCentury - (isPreviousCentury ? 100 : 0);
    }

    return isCommonEra ? result : 1 - result;
  }
  function isLeapYearIndex$1(year) {
    return year % 400 === 0 || year % 4 === 0 && year % 100 !== 0;
  }

  function _defineProperty$t(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  // | Year     |     y | yy |   yyy |  yyyy | yyyyy |
  // |----------|-------|----|-------|-------|-------|
  // | AD 1     |     1 | 01 |   001 |  0001 | 00001 |
  // | AD 12    |    12 | 12 |   012 |  0012 | 00012 |
  // | AD 123   |   123 | 23 |   123 |  0123 | 00123 |
  // | AD 1234  |  1234 | 34 |  1234 |  1234 | 01234 |
  // | AD 12345 | 12345 | 45 | 12345 | 12345 | 12345 |

  var YearParser = /*#__PURE__*/function (_Parser) {
    _inherits(YearParser, _Parser);

    var _super = _createSuper(YearParser);

    function YearParser() {
      var _this;

      _classCallCheck(this, YearParser);

      _this = _super.apply(this, arguments);

      _defineProperty$t(_assertThisInitialized(_this), "priority", 130);

      _defineProperty$t(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'u', 'w', 'I', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(YearParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        var valueCallback = function valueCallback(year) {
          return {
            year: year,
            isTwoDigitYear: token === 'yy'
          };
        };

        switch (token) {
          case 'y':
            return mapValue(parseNDigits(4, dateString), valueCallback);

          case 'yo':
            return mapValue(match.ordinalNumber(dateString, {
              unit: 'year'
            }), valueCallback);

          default:
            return mapValue(parseNDigits(token.length, dateString), valueCallback);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value.isTwoDigitYear || value.year > 0;
      }
    }, {
      key: "set",
      value: function set(date, flags, value) {
        var currentYear = date.getUTCFullYear();

        if (value.isTwoDigitYear) {
          var normalizedTwoDigitYear = normalizeTwoDigitYear(value.year, currentYear);
          date.setUTCFullYear(normalizedTwoDigitYear, 0, 1);
          date.setUTCHours(0, 0, 0, 0);
          return date;
        }

        var year = !('era' in flags) || flags.era === 1 ? value.year : 1 - value.year;
        date.setUTCFullYear(year, 0, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return YearParser;
  }(Parser);

  function _defineProperty$s(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var LocalWeekYearParser = /*#__PURE__*/function (_Parser) {
    _inherits(LocalWeekYearParser, _Parser);

    var _super = _createSuper(LocalWeekYearParser);

    function LocalWeekYearParser() {
      var _this;

      _classCallCheck(this, LocalWeekYearParser);

      _this = _super.apply(this, arguments);

      _defineProperty$s(_assertThisInitialized(_this), "priority", 130);

      _defineProperty$s(_assertThisInitialized(_this), "incompatibleTokens", ['y', 'R', 'u', 'Q', 'q', 'M', 'L', 'I', 'd', 'D', 'i', 't', 'T']);

      return _this;
    }

    _createClass(LocalWeekYearParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        var valueCallback = function valueCallback(year) {
          return {
            year: year,
            isTwoDigitYear: token === 'YY'
          };
        };

        switch (token) {
          case 'Y':
            return mapValue(parseNDigits(4, dateString), valueCallback);

          case 'Yo':
            return mapValue(match.ordinalNumber(dateString, {
              unit: 'year'
            }), valueCallback);

          default:
            return mapValue(parseNDigits(token.length, dateString), valueCallback);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value.isTwoDigitYear || value.year > 0;
      }
    }, {
      key: "set",
      value: function set(date, flags, value, options) {
        var currentYear = getUTCWeekYear(date, options);

        if (value.isTwoDigitYear) {
          var normalizedTwoDigitYear = normalizeTwoDigitYear(value.year, currentYear);
          date.setUTCFullYear(normalizedTwoDigitYear, 0, options.firstWeekContainsDate);
          date.setUTCHours(0, 0, 0, 0);
          return startOfUTCWeek(date, options);
        }

        var year = !('era' in flags) || flags.era === 1 ? value.year : 1 - value.year;
        date.setUTCFullYear(year, 0, options.firstWeekContainsDate);
        date.setUTCHours(0, 0, 0, 0);
        return startOfUTCWeek(date, options);
      }
    }]);

    return LocalWeekYearParser;
  }(Parser);

  function _defineProperty$r(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var ISOWeekYearParser = /*#__PURE__*/function (_Parser) {
    _inherits(ISOWeekYearParser, _Parser);

    var _super = _createSuper(ISOWeekYearParser);

    function ISOWeekYearParser() {
      var _this;

      _classCallCheck(this, ISOWeekYearParser);

      _this = _super.apply(this, arguments);

      _defineProperty$r(_assertThisInitialized(_this), "priority", 130);

      _defineProperty$r(_assertThisInitialized(_this), "incompatibleTokens", ['G', 'y', 'Y', 'u', 'Q', 'q', 'M', 'L', 'w', 'd', 'D', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(ISOWeekYearParser, [{
      key: "parse",
      value: function parse(dateString, token) {
        if (token === 'R') {
          return parseNDigitsSigned(4, dateString);
        }

        return parseNDigitsSigned(token.length, dateString);
      }
    }, {
      key: "set",
      value: function set(_date, _flags, value) {
        var firstWeekOfYear = new Date(0);
        firstWeekOfYear.setUTCFullYear(value, 0, 4);
        firstWeekOfYear.setUTCHours(0, 0, 0, 0);
        return startOfUTCISOWeek(firstWeekOfYear);
      }
    }]);

    return ISOWeekYearParser;
  }(Parser);

  function _defineProperty$q(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var ExtendedYearParser = /*#__PURE__*/function (_Parser) {
    _inherits(ExtendedYearParser, _Parser);

    var _super = _createSuper(ExtendedYearParser);

    function ExtendedYearParser() {
      var _this;

      _classCallCheck(this, ExtendedYearParser);

      _this = _super.apply(this, arguments);

      _defineProperty$q(_assertThisInitialized(_this), "priority", 130);

      _defineProperty$q(_assertThisInitialized(_this), "incompatibleTokens", ['G', 'y', 'Y', 'R', 'w', 'I', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(ExtendedYearParser, [{
      key: "parse",
      value: function parse(dateString, token) {
        if (token === 'u') {
          return parseNDigitsSigned(4, dateString);
        }

        return parseNDigitsSigned(token.length, dateString);
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCFullYear(value, 0, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return ExtendedYearParser;
  }(Parser);

  function _defineProperty$p(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var QuarterParser = /*#__PURE__*/function (_Parser) {
    _inherits(QuarterParser, _Parser);

    var _super = _createSuper(QuarterParser);

    function QuarterParser() {
      var _this;

      _classCallCheck(this, QuarterParser);

      _this = _super.apply(this, arguments);

      _defineProperty$p(_assertThisInitialized(_this), "priority", 120);

      _defineProperty$p(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'q', 'M', 'L', 'w', 'I', 'd', 'D', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(QuarterParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          // 1, 2, 3, 4
          case 'Q':
          case 'QQ':
            // 01, 02, 03, 04
            return parseNDigits(token.length, dateString);
          // 1st, 2nd, 3rd, 4th

          case 'Qo':
            return match.ordinalNumber(dateString, {
              unit: 'quarter'
            });
          // Q1, Q2, Q3, Q4

          case 'QQQ':
            return match.quarter(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.quarter(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // 1, 2, 3, 4 (narrow quarter; could be not numerical)

          case 'QQQQQ':
            return match.quarter(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // 1st quarter, 2nd quarter, ...

          case 'QQQQ':
          default:
            return match.quarter(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.quarter(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.quarter(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 4;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMonth((value - 1) * 3, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return QuarterParser;
  }(Parser);

  function _defineProperty$o(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var StandAloneQuarterParser = /*#__PURE__*/function (_Parser) {
    _inherits(StandAloneQuarterParser, _Parser);

    var _super = _createSuper(StandAloneQuarterParser);

    function StandAloneQuarterParser() {
      var _this;

      _classCallCheck(this, StandAloneQuarterParser);

      _this = _super.apply(this, arguments);

      _defineProperty$o(_assertThisInitialized(_this), "priority", 120);

      _defineProperty$o(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'Q', 'M', 'L', 'w', 'I', 'd', 'D', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(StandAloneQuarterParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          // 1, 2, 3, 4
          case 'q':
          case 'qq':
            // 01, 02, 03, 04
            return parseNDigits(token.length, dateString);
          // 1st, 2nd, 3rd, 4th

          case 'qo':
            return match.ordinalNumber(dateString, {
              unit: 'quarter'
            });
          // Q1, Q2, Q3, Q4

          case 'qqq':
            return match.quarter(dateString, {
              width: 'abbreviated',
              context: 'standalone'
            }) || match.quarter(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // 1, 2, 3, 4 (narrow quarter; could be not numerical)

          case 'qqqqq':
            return match.quarter(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // 1st quarter, 2nd quarter, ...

          case 'qqqq':
          default:
            return match.quarter(dateString, {
              width: 'wide',
              context: 'standalone'
            }) || match.quarter(dateString, {
              width: 'abbreviated',
              context: 'standalone'
            }) || match.quarter(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 4;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMonth((value - 1) * 3, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return StandAloneQuarterParser;
  }(Parser);

  function _defineProperty$n(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var MonthParser = /*#__PURE__*/function (_Parser) {
    _inherits(MonthParser, _Parser);

    var _super = _createSuper(MonthParser);

    function MonthParser() {
      var _this;

      _classCallCheck(this, MonthParser);

      _this = _super.apply(this, arguments);

      _defineProperty$n(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'q', 'Q', 'L', 'w', 'I', 'D', 'i', 'e', 'c', 't', 'T']);

      _defineProperty$n(_assertThisInitialized(_this), "priority", 110);

      return _this;
    }

    _createClass(MonthParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        var valueCallback = function valueCallback(value) {
          return value - 1;
        };

        switch (token) {
          // 1, 2, ..., 12
          case 'M':
            return mapValue(parseNumericPattern(numericPatterns.month, dateString), valueCallback);
          // 01, 02, ..., 12

          case 'MM':
            return mapValue(parseNDigits(2, dateString), valueCallback);
          // 1st, 2nd, ..., 12th

          case 'Mo':
            return mapValue(match.ordinalNumber(dateString, {
              unit: 'month'
            }), valueCallback);
          // Jan, Feb, ..., Dec

          case 'MMM':
            return match.month(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.month(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // J, F, ..., D

          case 'MMMMM':
            return match.month(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // January, February, ..., December

          case 'MMMM':
          default:
            return match.month(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.month(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.month(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 11;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMonth(value, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return MonthParser;
  }(Parser);

  function _defineProperty$m(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var StandAloneMonthParser = /*#__PURE__*/function (_Parser) {
    _inherits(StandAloneMonthParser, _Parser);

    var _super = _createSuper(StandAloneMonthParser);

    function StandAloneMonthParser() {
      var _this;

      _classCallCheck(this, StandAloneMonthParser);

      _this = _super.apply(this, arguments);

      _defineProperty$m(_assertThisInitialized(_this), "priority", 110);

      _defineProperty$m(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'q', 'Q', 'M', 'w', 'I', 'D', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(StandAloneMonthParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        var valueCallback = function valueCallback(value) {
          return value - 1;
        };

        switch (token) {
          // 1, 2, ..., 12
          case 'L':
            return mapValue(parseNumericPattern(numericPatterns.month, dateString), valueCallback);
          // 01, 02, ..., 12

          case 'LL':
            return mapValue(parseNDigits(2, dateString), valueCallback);
          // 1st, 2nd, ..., 12th

          case 'Lo':
            return mapValue(match.ordinalNumber(dateString, {
              unit: 'month'
            }), valueCallback);
          // Jan, Feb, ..., Dec

          case 'LLL':
            return match.month(dateString, {
              width: 'abbreviated',
              context: 'standalone'
            }) || match.month(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // J, F, ..., D

          case 'LLLLL':
            return match.month(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // January, February, ..., December

          case 'LLLL':
          default:
            return match.month(dateString, {
              width: 'wide',
              context: 'standalone'
            }) || match.month(dateString, {
              width: 'abbreviated',
              context: 'standalone'
            }) || match.month(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 11;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMonth(value, 1);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return StandAloneMonthParser;
  }(Parser);

  function setUTCWeek(dirtyDate, dirtyWeek, options) {
    requiredArgs(2, arguments);
    var date = toDate(dirtyDate);
    var week = toInteger(dirtyWeek);
    var diff = getUTCWeek(date, options) - week;
    date.setUTCDate(date.getUTCDate() - diff * 7);
    return date;
  }

  function _defineProperty$l(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var LocalWeekParser = /*#__PURE__*/function (_Parser) {
    _inherits(LocalWeekParser, _Parser);

    var _super = _createSuper(LocalWeekParser);

    function LocalWeekParser() {
      var _this;

      _classCallCheck(this, LocalWeekParser);

      _this = _super.apply(this, arguments);

      _defineProperty$l(_assertThisInitialized(_this), "priority", 100);

      _defineProperty$l(_assertThisInitialized(_this), "incompatibleTokens", ['y', 'R', 'u', 'q', 'Q', 'M', 'L', 'I', 'd', 'D', 'i', 't', 'T']);

      return _this;
    }

    _createClass(LocalWeekParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'w':
            return parseNumericPattern(numericPatterns.week, dateString);

          case 'wo':
            return match.ordinalNumber(dateString, {
              unit: 'week'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 53;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value, options) {
        return startOfUTCWeek(setUTCWeek(date, value, options), options);
      }
    }]);

    return LocalWeekParser;
  }(Parser);

  function setUTCISOWeek(dirtyDate, dirtyISOWeek) {
    requiredArgs(2, arguments);
    var date = toDate(dirtyDate);
    var isoWeek = toInteger(dirtyISOWeek);
    var diff = getUTCISOWeek(date) - isoWeek;
    date.setUTCDate(date.getUTCDate() - diff * 7);
    return date;
  }

  function _defineProperty$k(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var ISOWeekParser = /*#__PURE__*/function (_Parser) {
    _inherits(ISOWeekParser, _Parser);

    var _super = _createSuper(ISOWeekParser);

    function ISOWeekParser() {
      var _this;

      _classCallCheck(this, ISOWeekParser);

      _this = _super.apply(this, arguments);

      _defineProperty$k(_assertThisInitialized(_this), "priority", 100);

      _defineProperty$k(_assertThisInitialized(_this), "incompatibleTokens", ['y', 'Y', 'u', 'q', 'Q', 'M', 'L', 'w', 'd', 'D', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(ISOWeekParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'I':
            return parseNumericPattern(numericPatterns.week, dateString);

          case 'Io':
            return match.ordinalNumber(dateString, {
              unit: 'week'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 53;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        return startOfUTCISOWeek(setUTCISOWeek(date, value));
      }
    }]);

    return ISOWeekParser;
  }(Parser);

  function _defineProperty$j(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var DAYS_IN_MONTH_LEAP_YEAR = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; // Day of the month

  var DateParser = /*#__PURE__*/function (_Parser) {
    _inherits(DateParser, _Parser);

    var _super = _createSuper(DateParser);

    function DateParser() {
      var _this;

      _classCallCheck(this, DateParser);

      _this = _super.apply(this, arguments);

      _defineProperty$j(_assertThisInitialized(_this), "priority", 90);

      _defineProperty$j(_assertThisInitialized(_this), "subPriority", 1);

      _defineProperty$j(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'q', 'Q', 'w', 'I', 'D', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(DateParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'd':
            return parseNumericPattern(numericPatterns.date, dateString);

          case 'do':
            return match.ordinalNumber(dateString, {
              unit: 'date'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(date, value) {
        var year = date.getUTCFullYear();
        var isLeapYear = isLeapYearIndex$1(year);
        var month = date.getUTCMonth();

        if (isLeapYear) {
          return value >= 1 && value <= DAYS_IN_MONTH_LEAP_YEAR[month];
        } else {
          return value >= 1 && value <= DAYS_IN_MONTH[month];
        }
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCDate(value);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return DateParser;
  }(Parser);

  function _defineProperty$i(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var DayOfYearParser = /*#__PURE__*/function (_Parser) {
    _inherits(DayOfYearParser, _Parser);

    var _super = _createSuper(DayOfYearParser);

    function DayOfYearParser() {
      var _this;

      _classCallCheck(this, DayOfYearParser);

      _this = _super.apply(this, arguments);

      _defineProperty$i(_assertThisInitialized(_this), "priority", 90);

      _defineProperty$i(_assertThisInitialized(_this), "subpriority", 1);

      _defineProperty$i(_assertThisInitialized(_this), "incompatibleTokens", ['Y', 'R', 'q', 'Q', 'M', 'L', 'w', 'I', 'd', 'E', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(DayOfYearParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'D':
          case 'DD':
            return parseNumericPattern(numericPatterns.dayOfYear, dateString);

          case 'Do':
            return match.ordinalNumber(dateString, {
              unit: 'date'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(date, value) {
        var year = date.getUTCFullYear();
        var isLeapYear = isLeapYearIndex$1(year);

        if (isLeapYear) {
          return value >= 1 && value <= 366;
        } else {
          return value >= 1 && value <= 365;
        }
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMonth(0, value);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return DayOfYearParser;
  }(Parser);

  function setUTCDay(dirtyDate, dirtyDay, options) {
    var _ref, _ref2, _ref3, _options$weekStartsOn, _options$locale, _options$locale$optio, _defaultOptions$local, _defaultOptions$local2;

    requiredArgs(2, arguments);
    var defaultOptions = getDefaultOptions();
    var weekStartsOn = toInteger((_ref = (_ref2 = (_ref3 = (_options$weekStartsOn = options === null || options === void 0 ? void 0 : options.weekStartsOn) !== null && _options$weekStartsOn !== void 0 ? _options$weekStartsOn : options === null || options === void 0 ? void 0 : (_options$locale = options.locale) === null || _options$locale === void 0 ? void 0 : (_options$locale$optio = _options$locale.options) === null || _options$locale$optio === void 0 ? void 0 : _options$locale$optio.weekStartsOn) !== null && _ref3 !== void 0 ? _ref3 : defaultOptions.weekStartsOn) !== null && _ref2 !== void 0 ? _ref2 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.weekStartsOn) !== null && _ref !== void 0 ? _ref : 0); // Test if weekStartsOn is between 0 and 6 _and_ is not NaN

    if (!(weekStartsOn >= 0 && weekStartsOn <= 6)) {
      throw new RangeError('weekStartsOn must be between 0 and 6 inclusively');
    }

    var date = toDate(dirtyDate);
    var day = toInteger(dirtyDay);
    var currentDay = date.getUTCDay();
    var remainder = day % 7;
    var dayIndex = (remainder + 7) % 7;
    var diff = (dayIndex < weekStartsOn ? 7 : 0) + day - currentDay;
    date.setUTCDate(date.getUTCDate() + diff);
    return date;
  }

  function _defineProperty$h(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var DayParser = /*#__PURE__*/function (_Parser) {
    _inherits(DayParser, _Parser);

    var _super = _createSuper(DayParser);

    function DayParser() {
      var _this;

      _classCallCheck(this, DayParser);

      _this = _super.apply(this, arguments);

      _defineProperty$h(_assertThisInitialized(_this), "priority", 90);

      _defineProperty$h(_assertThisInitialized(_this), "incompatibleTokens", ['D', 'i', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(DayParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          // Tue
          case 'E':
          case 'EE':
          case 'EEE':
            return match.day(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // T

          case 'EEEEE':
            return match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // Tu

          case 'EEEEEE':
            return match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // Tuesday

          case 'EEEE':
          default:
            return match.day(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 6;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value, options) {
        date = setUTCDay(date, value, options);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return DayParser;
  }(Parser);

  function _defineProperty$g(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var LocalDayParser = /*#__PURE__*/function (_Parser) {
    _inherits(LocalDayParser, _Parser);

    var _super = _createSuper(LocalDayParser);

    function LocalDayParser() {
      var _this;

      _classCallCheck(this, LocalDayParser);

      _this = _super.apply(this, arguments);

      _defineProperty$g(_assertThisInitialized(_this), "priority", 90);

      _defineProperty$g(_assertThisInitialized(_this), "incompatibleTokens", ['y', 'R', 'u', 'q', 'Q', 'M', 'L', 'I', 'd', 'D', 'E', 'i', 'c', 't', 'T']);

      return _this;
    }

    _createClass(LocalDayParser, [{
      key: "parse",
      value: function parse(dateString, token, match, options) {
        var valueCallback = function valueCallback(value) {
          var wholeWeekDays = Math.floor((value - 1) / 7) * 7;
          return (value + options.weekStartsOn + 6) % 7 + wholeWeekDays;
        };

        switch (token) {
          // 3
          case 'e':
          case 'ee':
            // 03
            return mapValue(parseNDigits(token.length, dateString), valueCallback);
          // 3rd

          case 'eo':
            return mapValue(match.ordinalNumber(dateString, {
              unit: 'day'
            }), valueCallback);
          // Tue

          case 'eee':
            return match.day(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // T

          case 'eeeee':
            return match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // Tu

          case 'eeeeee':
            return match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
          // Tuesday

          case 'eeee':
          default:
            return match.day(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 6;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value, options) {
        date = setUTCDay(date, value, options);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return LocalDayParser;
  }(Parser);

  function _defineProperty$f(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var StandAloneLocalDayParser = /*#__PURE__*/function (_Parser) {
    _inherits(StandAloneLocalDayParser, _Parser);

    var _super = _createSuper(StandAloneLocalDayParser);

    function StandAloneLocalDayParser() {
      var _this;

      _classCallCheck(this, StandAloneLocalDayParser);

      _this = _super.apply(this, arguments);

      _defineProperty$f(_assertThisInitialized(_this), "priority", 90);

      _defineProperty$f(_assertThisInitialized(_this), "incompatibleTokens", ['y', 'R', 'u', 'q', 'Q', 'M', 'L', 'I', 'd', 'D', 'E', 'i', 'e', 't', 'T']);

      return _this;
    }

    _createClass(StandAloneLocalDayParser, [{
      key: "parse",
      value: function parse(dateString, token, match, options) {
        var valueCallback = function valueCallback(value) {
          var wholeWeekDays = Math.floor((value - 1) / 7) * 7;
          return (value + options.weekStartsOn + 6) % 7 + wholeWeekDays;
        };

        switch (token) {
          // 3
          case 'c':
          case 'cc':
            // 03
            return mapValue(parseNDigits(token.length, dateString), valueCallback);
          // 3rd

          case 'co':
            return mapValue(match.ordinalNumber(dateString, {
              unit: 'day'
            }), valueCallback);
          // Tue

          case 'ccc':
            return match.day(dateString, {
              width: 'abbreviated',
              context: 'standalone'
            }) || match.day(dateString, {
              width: 'short',
              context: 'standalone'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // T

          case 'ccccc':
            return match.day(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // Tu

          case 'cccccc':
            return match.day(dateString, {
              width: 'short',
              context: 'standalone'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
          // Tuesday

          case 'cccc':
          default:
            return match.day(dateString, {
              width: 'wide',
              context: 'standalone'
            }) || match.day(dateString, {
              width: 'abbreviated',
              context: 'standalone'
            }) || match.day(dateString, {
              width: 'short',
              context: 'standalone'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'standalone'
            });
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 6;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value, options) {
        date = setUTCDay(date, value, options);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return StandAloneLocalDayParser;
  }(Parser);

  function setUTCISODay(dirtyDate, dirtyDay) {
    requiredArgs(2, arguments);
    var day = toInteger(dirtyDay);

    if (day % 7 === 0) {
      day = day - 7;
    }

    var weekStartsOn = 1;
    var date = toDate(dirtyDate);
    var currentDay = date.getUTCDay();
    var remainder = day % 7;
    var dayIndex = (remainder + 7) % 7;
    var diff = (dayIndex < weekStartsOn ? 7 : 0) + day - currentDay;
    date.setUTCDate(date.getUTCDate() + diff);
    return date;
  }

  function _defineProperty$e(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var ISODayParser = /*#__PURE__*/function (_Parser) {
    _inherits(ISODayParser, _Parser);

    var _super = _createSuper(ISODayParser);

    function ISODayParser() {
      var _this;

      _classCallCheck(this, ISODayParser);

      _this = _super.apply(this, arguments);

      _defineProperty$e(_assertThisInitialized(_this), "priority", 90);

      _defineProperty$e(_assertThisInitialized(_this), "incompatibleTokens", ['y', 'Y', 'u', 'q', 'Q', 'M', 'L', 'w', 'd', 'D', 'E', 'e', 'c', 't', 'T']);

      return _this;
    }

    _createClass(ISODayParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        var valueCallback = function valueCallback(value) {
          if (value === 0) {
            return 7;
          }

          return value;
        };

        switch (token) {
          // 2
          case 'i':
          case 'ii':
            // 02
            return parseNDigits(token.length, dateString);
          // 2nd

          case 'io':
            return match.ordinalNumber(dateString, {
              unit: 'day'
            });
          // Tue

          case 'iii':
            return mapValue(match.day(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            }), valueCallback);
          // T

          case 'iiiii':
            return mapValue(match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            }), valueCallback);
          // Tu

          case 'iiiiii':
            return mapValue(match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            }), valueCallback);
          // Tuesday

          case 'iiii':
          default:
            return mapValue(match.day(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'short',
              context: 'formatting'
            }) || match.day(dateString, {
              width: 'narrow',
              context: 'formatting'
            }), valueCallback);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 7;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date = setUTCISODay(date, value);
        date.setUTCHours(0, 0, 0, 0);
        return date;
      }
    }]);

    return ISODayParser;
  }(Parser);

  function _defineProperty$d(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var AMPMParser = /*#__PURE__*/function (_Parser) {
    _inherits(AMPMParser, _Parser);

    var _super = _createSuper(AMPMParser);

    function AMPMParser() {
      var _this;

      _classCallCheck(this, AMPMParser);

      _this = _super.apply(this, arguments);

      _defineProperty$d(_assertThisInitialized(_this), "priority", 80);

      _defineProperty$d(_assertThisInitialized(_this), "incompatibleTokens", ['b', 'B', 'H', 'k', 't', 'T']);

      return _this;
    }

    _createClass(AMPMParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'a':
          case 'aa':
          case 'aaa':
            return match.dayPeriod(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });

          case 'aaaaa':
            return match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });

          case 'aaaa':
          default:
            return match.dayPeriod(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCHours(dayPeriodEnumToHours(value), 0, 0, 0);
        return date;
      }
    }]);

    return AMPMParser;
  }(Parser);

  function _defineProperty$c(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var AMPMMidnightParser = /*#__PURE__*/function (_Parser) {
    _inherits(AMPMMidnightParser, _Parser);

    var _super = _createSuper(AMPMMidnightParser);

    function AMPMMidnightParser() {
      var _this;

      _classCallCheck(this, AMPMMidnightParser);

      _this = _super.apply(this, arguments);

      _defineProperty$c(_assertThisInitialized(_this), "priority", 80);

      _defineProperty$c(_assertThisInitialized(_this), "incompatibleTokens", ['a', 'B', 'H', 'k', 't', 'T']);

      return _this;
    }

    _createClass(AMPMMidnightParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'b':
          case 'bb':
          case 'bbb':
            return match.dayPeriod(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });

          case 'bbbbb':
            return match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });

          case 'bbbb':
          default:
            return match.dayPeriod(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCHours(dayPeriodEnumToHours(value), 0, 0, 0);
        return date;
      }
    }]);

    return AMPMMidnightParser;
  }(Parser);

  function _defineProperty$b(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var DayPeriodParser = /*#__PURE__*/function (_Parser) {
    _inherits(DayPeriodParser, _Parser);

    var _super = _createSuper(DayPeriodParser);

    function DayPeriodParser() {
      var _this;

      _classCallCheck(this, DayPeriodParser);

      _this = _super.apply(this, arguments);

      _defineProperty$b(_assertThisInitialized(_this), "priority", 80);

      _defineProperty$b(_assertThisInitialized(_this), "incompatibleTokens", ['a', 'b', 't', 'T']);

      return _this;
    }

    _createClass(DayPeriodParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'B':
          case 'BB':
          case 'BBB':
            return match.dayPeriod(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });

          case 'BBBBB':
            return match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });

          case 'BBBB':
          default:
            return match.dayPeriod(dateString, {
              width: 'wide',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'abbreviated',
              context: 'formatting'
            }) || match.dayPeriod(dateString, {
              width: 'narrow',
              context: 'formatting'
            });
        }
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCHours(dayPeriodEnumToHours(value), 0, 0, 0);
        return date;
      }
    }]);

    return DayPeriodParser;
  }(Parser);

  function _defineProperty$a(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var Hour1to12Parser = /*#__PURE__*/function (_Parser) {
    _inherits(Hour1to12Parser, _Parser);

    var _super = _createSuper(Hour1to12Parser);

    function Hour1to12Parser() {
      var _this;

      _classCallCheck(this, Hour1to12Parser);

      _this = _super.apply(this, arguments);

      _defineProperty$a(_assertThisInitialized(_this), "priority", 70);

      _defineProperty$a(_assertThisInitialized(_this), "incompatibleTokens", ['H', 'K', 'k', 't', 'T']);

      return _this;
    }

    _createClass(Hour1to12Parser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'h':
            return parseNumericPattern(numericPatterns.hour12h, dateString);

          case 'ho':
            return match.ordinalNumber(dateString, {
              unit: 'hour'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 12;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        var isPM = date.getUTCHours() >= 12;

        if (isPM && value < 12) {
          date.setUTCHours(value + 12, 0, 0, 0);
        } else if (!isPM && value === 12) {
          date.setUTCHours(0, 0, 0, 0);
        } else {
          date.setUTCHours(value, 0, 0, 0);
        }

        return date;
      }
    }]);

    return Hour1to12Parser;
  }(Parser);

  function _defineProperty$9(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var Hour0to23Parser = /*#__PURE__*/function (_Parser) {
    _inherits(Hour0to23Parser, _Parser);

    var _super = _createSuper(Hour0to23Parser);

    function Hour0to23Parser() {
      var _this;

      _classCallCheck(this, Hour0to23Parser);

      _this = _super.apply(this, arguments);

      _defineProperty$9(_assertThisInitialized(_this), "priority", 70);

      _defineProperty$9(_assertThisInitialized(_this), "incompatibleTokens", ['a', 'b', 'h', 'K', 'k', 't', 'T']);

      return _this;
    }

    _createClass(Hour0to23Parser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'H':
            return parseNumericPattern(numericPatterns.hour23h, dateString);

          case 'Ho':
            return match.ordinalNumber(dateString, {
              unit: 'hour'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 23;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCHours(value, 0, 0, 0);
        return date;
      }
    }]);

    return Hour0to23Parser;
  }(Parser);

  function _defineProperty$8(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var Hour0To11Parser = /*#__PURE__*/function (_Parser) {
    _inherits(Hour0To11Parser, _Parser);

    var _super = _createSuper(Hour0To11Parser);

    function Hour0To11Parser() {
      var _this;

      _classCallCheck(this, Hour0To11Parser);

      _this = _super.apply(this, arguments);

      _defineProperty$8(_assertThisInitialized(_this), "priority", 70);

      _defineProperty$8(_assertThisInitialized(_this), "incompatibleTokens", ['h', 'H', 'k', 't', 'T']);

      return _this;
    }

    _createClass(Hour0To11Parser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'K':
            return parseNumericPattern(numericPatterns.hour11h, dateString);

          case 'Ko':
            return match.ordinalNumber(dateString, {
              unit: 'hour'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 11;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        var isPM = date.getUTCHours() >= 12;

        if (isPM && value < 12) {
          date.setUTCHours(value + 12, 0, 0, 0);
        } else {
          date.setUTCHours(value, 0, 0, 0);
        }

        return date;
      }
    }]);

    return Hour0To11Parser;
  }(Parser);

  function _defineProperty$7(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var Hour1To24Parser = /*#__PURE__*/function (_Parser) {
    _inherits(Hour1To24Parser, _Parser);

    var _super = _createSuper(Hour1To24Parser);

    function Hour1To24Parser() {
      var _this;

      _classCallCheck(this, Hour1To24Parser);

      _this = _super.apply(this, arguments);

      _defineProperty$7(_assertThisInitialized(_this), "priority", 70);

      _defineProperty$7(_assertThisInitialized(_this), "incompatibleTokens", ['a', 'b', 'h', 'H', 'K', 't', 'T']);

      return _this;
    }

    _createClass(Hour1To24Parser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'k':
            return parseNumericPattern(numericPatterns.hour24h, dateString);

          case 'ko':
            return match.ordinalNumber(dateString, {
              unit: 'hour'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 1 && value <= 24;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        var hours = value <= 24 ? value % 24 : value;
        date.setUTCHours(hours, 0, 0, 0);
        return date;
      }
    }]);

    return Hour1To24Parser;
  }(Parser);

  function _defineProperty$6(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var MinuteParser = /*#__PURE__*/function (_Parser) {
    _inherits(MinuteParser, _Parser);

    var _super = _createSuper(MinuteParser);

    function MinuteParser() {
      var _this;

      _classCallCheck(this, MinuteParser);

      _this = _super.apply(this, arguments);

      _defineProperty$6(_assertThisInitialized(_this), "priority", 60);

      _defineProperty$6(_assertThisInitialized(_this), "incompatibleTokens", ['t', 'T']);

      return _this;
    }

    _createClass(MinuteParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 'm':
            return parseNumericPattern(numericPatterns.minute, dateString);

          case 'mo':
            return match.ordinalNumber(dateString, {
              unit: 'minute'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 59;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMinutes(value, 0, 0);
        return date;
      }
    }]);

    return MinuteParser;
  }(Parser);

  function _defineProperty$5(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var SecondParser = /*#__PURE__*/function (_Parser) {
    _inherits(SecondParser, _Parser);

    var _super = _createSuper(SecondParser);

    function SecondParser() {
      var _this;

      _classCallCheck(this, SecondParser);

      _this = _super.apply(this, arguments);

      _defineProperty$5(_assertThisInitialized(_this), "priority", 50);

      _defineProperty$5(_assertThisInitialized(_this), "incompatibleTokens", ['t', 'T']);

      return _this;
    }

    _createClass(SecondParser, [{
      key: "parse",
      value: function parse(dateString, token, match) {
        switch (token) {
          case 's':
            return parseNumericPattern(numericPatterns.second, dateString);

          case 'so':
            return match.ordinalNumber(dateString, {
              unit: 'second'
            });

          default:
            return parseNDigits(token.length, dateString);
        }
      }
    }, {
      key: "validate",
      value: function validate(_date, value) {
        return value >= 0 && value <= 59;
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCSeconds(value, 0);
        return date;
      }
    }]);

    return SecondParser;
  }(Parser);

  function _defineProperty$4(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var FractionOfSecondParser = /*#__PURE__*/function (_Parser) {
    _inherits(FractionOfSecondParser, _Parser);

    var _super = _createSuper(FractionOfSecondParser);

    function FractionOfSecondParser() {
      var _this;

      _classCallCheck(this, FractionOfSecondParser);

      _this = _super.apply(this, arguments);

      _defineProperty$4(_assertThisInitialized(_this), "priority", 30);

      _defineProperty$4(_assertThisInitialized(_this), "incompatibleTokens", ['t', 'T']);

      return _this;
    }

    _createClass(FractionOfSecondParser, [{
      key: "parse",
      value: function parse(dateString, token) {
        var valueCallback = function valueCallback(value) {
          return Math.floor(value * Math.pow(10, -token.length + 3));
        };

        return mapValue(parseNDigits(token.length, dateString), valueCallback);
      }
    }, {
      key: "set",
      value: function set(date, _flags, value) {
        date.setUTCMilliseconds(value);
        return date;
      }
    }]);

    return FractionOfSecondParser;
  }(Parser);

  function _defineProperty$3(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var ISOTimezoneWithZParser = /*#__PURE__*/function (_Parser) {
    _inherits(ISOTimezoneWithZParser, _Parser);

    var _super = _createSuper(ISOTimezoneWithZParser);

    function ISOTimezoneWithZParser() {
      var _this;

      _classCallCheck(this, ISOTimezoneWithZParser);

      _this = _super.apply(this, arguments);

      _defineProperty$3(_assertThisInitialized(_this), "priority", 10);

      _defineProperty$3(_assertThisInitialized(_this), "incompatibleTokens", ['t', 'T', 'x']);

      return _this;
    }

    _createClass(ISOTimezoneWithZParser, [{
      key: "parse",
      value: function parse(dateString, token) {
        switch (token) {
          case 'X':
            return parseTimezonePattern(timezonePatterns.basicOptionalMinutes, dateString);

          case 'XX':
            return parseTimezonePattern(timezonePatterns.basic, dateString);

          case 'XXXX':
            return parseTimezonePattern(timezonePatterns.basicOptionalSeconds, dateString);

          case 'XXXXX':
            return parseTimezonePattern(timezonePatterns.extendedOptionalSeconds, dateString);

          case 'XXX':
          default:
            return parseTimezonePattern(timezonePatterns.extended, dateString);
        }
      }
    }, {
      key: "set",
      value: function set(date, flags, value) {
        if (flags.timestampIsSet) {
          return date;
        }

        return new Date(date.getTime() - value);
      }
    }]);

    return ISOTimezoneWithZParser;
  }(Parser);

  function _defineProperty$2(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  var ISOTimezoneParser = /*#__PURE__*/function (_Parser) {
    _inherits(ISOTimezoneParser, _Parser);

    var _super = _createSuper(ISOTimezoneParser);

    function ISOTimezoneParser() {
      var _this;

      _classCallCheck(this, ISOTimezoneParser);

      _this = _super.apply(this, arguments);

      _defineProperty$2(_assertThisInitialized(_this), "priority", 10);

      _defineProperty$2(_assertThisInitialized(_this), "incompatibleTokens", ['t', 'T', 'X']);

      return _this;
    }

    _createClass(ISOTimezoneParser, [{
      key: "parse",
      value: function parse(dateString, token) {
        switch (token) {
          case 'x':
            return parseTimezonePattern(timezonePatterns.basicOptionalMinutes, dateString);

          case 'xx':
            return parseTimezonePattern(timezonePatterns.basic, dateString);

          case 'xxxx':
            return parseTimezonePattern(timezonePatterns.basicOptionalSeconds, dateString);

          case 'xxxxx':
            return parseTimezonePattern(timezonePatterns.extendedOptionalSeconds, dateString);

          case 'xxx':
          default:
            return parseTimezonePattern(timezonePatterns.extended, dateString);
        }
      }
    }, {
      key: "set",
      value: function set(date, flags, value) {
        if (flags.timestampIsSet) {
          return date;
        }

        return new Date(date.getTime() - value);
      }
    }]);

    return ISOTimezoneParser;
  }(Parser);

  function _defineProperty$1(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var TimestampSecondsParser = /*#__PURE__*/function (_Parser) {
    _inherits(TimestampSecondsParser, _Parser);

    var _super = _createSuper(TimestampSecondsParser);

    function TimestampSecondsParser() {
      var _this;

      _classCallCheck(this, TimestampSecondsParser);

      _this = _super.apply(this, arguments);

      _defineProperty$1(_assertThisInitialized(_this), "priority", 40);

      _defineProperty$1(_assertThisInitialized(_this), "incompatibleTokens", '*');

      return _this;
    }

    _createClass(TimestampSecondsParser, [{
      key: "parse",
      value: function parse(dateString) {
        return parseAnyDigitsSigned(dateString);
      }
    }, {
      key: "set",
      value: function set(_date, _flags, value) {
        return [new Date(value * 1000), {
          timestampIsSet: true
        }];
      }
    }]);

    return TimestampSecondsParser;
  }(Parser);

  function _defineProperty(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }
  var TimestampMillisecondsParser = /*#__PURE__*/function (_Parser) {
    _inherits(TimestampMillisecondsParser, _Parser);

    var _super = _createSuper(TimestampMillisecondsParser);

    function TimestampMillisecondsParser() {
      var _this;

      _classCallCheck(this, TimestampMillisecondsParser);

      _this = _super.apply(this, arguments);

      _defineProperty(_assertThisInitialized(_this), "priority", 20);

      _defineProperty(_assertThisInitialized(_this), "incompatibleTokens", '*');

      return _this;
    }

    _createClass(TimestampMillisecondsParser, [{
      key: "parse",
      value: function parse(dateString) {
        return parseAnyDigitsSigned(dateString);
      }
    }, {
      key: "set",
      value: function set(_date, _flags, value) {
        return [new Date(value), {
          timestampIsSet: true
        }];
      }
    }]);

    return TimestampMillisecondsParser;
  }(Parser);

  /*
   * |     | Unit                           |     | Unit                           |
   * |-----|--------------------------------|-----|--------------------------------|
   * |  a  | AM, PM                         |  A* | Milliseconds in day            |
   * |  b  | AM, PM, noon, midnight         |  B  | Flexible day period            |
   * |  c  | Stand-alone local day of week  |  C* | Localized hour w/ day period   |
   * |  d  | Day of month                   |  D  | Day of year                    |
   * |  e  | Local day of week              |  E  | Day of week                    |
   * |  f  |                                |  F* | Day of week in month           |
   * |  g* | Modified Julian day            |  G  | Era                            |
   * |  h  | Hour [1-12]                    |  H  | Hour [0-23]                    |
   * |  i! | ISO day of week                |  I! | ISO week of year               |
   * |  j* | Localized hour w/ day period   |  J* | Localized hour w/o day period  |
   * |  k  | Hour [1-24]                    |  K  | Hour [0-11]                    |
   * |  l* | (deprecated)                   |  L  | Stand-alone month              |
   * |  m  | Minute                         |  M  | Month                          |
   * |  n  |                                |  N  |                                |
   * |  o! | Ordinal number modifier        |  O* | Timezone (GMT)                 |
   * |  p  |                                |  P  |                                |
   * |  q  | Stand-alone quarter            |  Q  | Quarter                        |
   * |  r* | Related Gregorian year         |  R! | ISO week-numbering year        |
   * |  s  | Second                         |  S  | Fraction of second             |
   * |  t! | Seconds timestamp              |  T! | Milliseconds timestamp         |
   * |  u  | Extended year                  |  U* | Cyclic year                    |
   * |  v* | Timezone (generic non-locat.)  |  V* | Timezone (location)            |
   * |  w  | Local week of year             |  W* | Week of month                  |
   * |  x  | Timezone (ISO-8601 w/o Z)      |  X  | Timezone (ISO-8601)            |
   * |  y  | Year (abs)                     |  Y  | Local week-numbering year      |
   * |  z* | Timezone (specific non-locat.) |  Z* | Timezone (aliases)             |
   *
   * Letters marked by * are not implemented but reserved by Unicode standard.
   *
   * Letters marked by ! are non-standard, but implemented by date-fns:
   * - `o` modifies the previous token to turn it into an ordinal (see `parse` docs)
   * - `i` is ISO day of week. For `i` and `ii` is returns numeric ISO week days,
   *   i.e. 7 for Sunday, 1 for Monday, etc.
   * - `I` is ISO week of year, as opposed to `w` which is local week of year.
   * - `R` is ISO week-numbering year, as opposed to `Y` which is local week-numbering year.
   *   `R` is supposed to be used in conjunction with `I` and `i`
   *   for universal ISO week-numbering date, whereas
   *   `Y` is supposed to be used in conjunction with `w` and `e`
   *   for week-numbering date specific to the locale.
   */

  var parsers = {
    G: new EraParser(),
    y: new YearParser(),
    Y: new LocalWeekYearParser(),
    R: new ISOWeekYearParser(),
    u: new ExtendedYearParser(),
    Q: new QuarterParser(),
    q: new StandAloneQuarterParser(),
    M: new MonthParser(),
    L: new StandAloneMonthParser(),
    w: new LocalWeekParser(),
    I: new ISOWeekParser(),
    d: new DateParser(),
    D: new DayOfYearParser(),
    E: new DayParser(),
    e: new LocalDayParser(),
    c: new StandAloneLocalDayParser(),
    i: new ISODayParser(),
    a: new AMPMParser(),
    b: new AMPMMidnightParser(),
    B: new DayPeriodParser(),
    h: new Hour1to12Parser(),
    H: new Hour0to23Parser(),
    K: new Hour0To11Parser(),
    k: new Hour1To24Parser(),
    m: new MinuteParser(),
    s: new SecondParser(),
    S: new FractionOfSecondParser(),
    X: new ISOTimezoneWithZParser(),
    x: new ISOTimezoneParser(),
    t: new TimestampSecondsParser(),
    T: new TimestampMillisecondsParser()
  };

  // - [yYQqMLwIdDecihHKkms]o matches any available ordinal number token
  //   (one of the certain letters followed by `o`)
  // - (\w)\1* matches any sequences of the same letter
  // - '' matches two quote characters in a row
  // - '(''|[^'])+('|$) matches anything surrounded by two quote characters ('),
  //   except a single quote symbol, which ends the sequence.
  //   Two quote characters do not end the sequence.
  //   If there is no matching single quote
  //   then the sequence will continue until the end of the string.
  // - . matches any single character unmatched by previous parts of the RegExps

  var formattingTokensRegExp = /[yYQqMLwIdDecihHKkms]o|(\w)\1*|''|'(''|[^'])+('|$)|./g; // This RegExp catches symbols escaped by quotes, and also
  // sequences of symbols P, p, and the combinations like `PPPPPPPppppp`

  var longFormattingTokensRegExp = /P+p+|P+|p+|''|'(''|[^'])+('|$)|./g;
  var escapedStringRegExp = /^'([^]*?)'?$/;
  var doubleQuoteRegExp = /''/g;
  var notWhitespaceRegExp = /\S/;
  var unescapedLatinCharacterRegExp = /[a-zA-Z]/;
  /**
   * @name parse
   * @category Common Helpers
   * @summary Parse the date.
   *
   * @description
   * Return the date parsed from string using the given format string.
   *
   * > ⚠️ Please note that the `format` tokens differ from Moment.js and other libraries.
   * > See: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   *
   * The characters in the format string wrapped between two single quotes characters (') are escaped.
   * Two single quotes in a row, whether inside or outside a quoted sequence, represent a 'real' single quote.
   *
   * Format of the format string is based on Unicode Technical Standard #35:
   * https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
   * with a few additions (see note 5 below the table).
   *
   * Not all tokens are compatible. Combinations that don't make sense or could lead to bugs are prohibited
   * and will throw `RangeError`. For example usage of 24-hour format token with AM/PM token will throw an exception:
   *
   * ```javascript
   * parse('23 AM', 'HH a', new Date())
   * //=> RangeError: The format string mustn't contain `HH` and `a` at the same time
   * ```
   *
   * See the compatibility table: https://docs.google.com/spreadsheets/d/e/2PACX-1vQOPU3xUhplll6dyoMmVUXHKl_8CRDs6_ueLmex3SoqwhuolkuN3O05l4rqx5h1dKX8eb46Ul-CCSrq/pubhtml?gid=0&single=true
   *
   * Accepted format string patterns:
   * | Unit                            |Prior| Pattern | Result examples                   | Notes |
   * |---------------------------------|-----|---------|-----------------------------------|-------|
   * | Era                             | 140 | G..GGG  | AD, BC                            |       |
   * |                                 |     | GGGG    | Anno Domini, Before Christ        | 2     |
   * |                                 |     | GGGGG   | A, B                              |       |
   * | Calendar year                   | 130 | y       | 44, 1, 1900, 2017, 9999           | 4     |
   * |                                 |     | yo      | 44th, 1st, 1900th, 9999999th      | 4,5   |
   * |                                 |     | yy      | 44, 01, 00, 17                    | 4     |
   * |                                 |     | yyy     | 044, 001, 123, 999                | 4     |
   * |                                 |     | yyyy    | 0044, 0001, 1900, 2017            | 4     |
   * |                                 |     | yyyyy   | ...                               | 2,4   |
   * | Local week-numbering year       | 130 | Y       | 44, 1, 1900, 2017, 9000           | 4     |
   * |                                 |     | Yo      | 44th, 1st, 1900th, 9999999th      | 4,5   |
   * |                                 |     | YY      | 44, 01, 00, 17                    | 4,6   |
   * |                                 |     | YYY     | 044, 001, 123, 999                | 4     |
   * |                                 |     | YYYY    | 0044, 0001, 1900, 2017            | 4,6   |
   * |                                 |     | YYYYY   | ...                               | 2,4   |
   * | ISO week-numbering year         | 130 | R       | -43, 1, 1900, 2017, 9999, -9999   | 4,5   |
   * |                                 |     | RR      | -43, 01, 00, 17                   | 4,5   |
   * |                                 |     | RRR     | -043, 001, 123, 999, -999         | 4,5   |
   * |                                 |     | RRRR    | -0043, 0001, 2017, 9999, -9999    | 4,5   |
   * |                                 |     | RRRRR   | ...                               | 2,4,5 |
   * | Extended year                   | 130 | u       | -43, 1, 1900, 2017, 9999, -999    | 4     |
   * |                                 |     | uu      | -43, 01, 99, -99                  | 4     |
   * |                                 |     | uuu     | -043, 001, 123, 999, -999         | 4     |
   * |                                 |     | uuuu    | -0043, 0001, 2017, 9999, -9999    | 4     |
   * |                                 |     | uuuuu   | ...                               | 2,4   |
   * | Quarter (formatting)            | 120 | Q       | 1, 2, 3, 4                        |       |
   * |                                 |     | Qo      | 1st, 2nd, 3rd, 4th                | 5     |
   * |                                 |     | QQ      | 01, 02, 03, 04                    |       |
   * |                                 |     | QQQ     | Q1, Q2, Q3, Q4                    |       |
   * |                                 |     | QQQQ    | 1st quarter, 2nd quarter, ...     | 2     |
   * |                                 |     | QQQQQ   | 1, 2, 3, 4                        | 4     |
   * | Quarter (stand-alone)           | 120 | q       | 1, 2, 3, 4                        |       |
   * |                                 |     | qo      | 1st, 2nd, 3rd, 4th                | 5     |
   * |                                 |     | qq      | 01, 02, 03, 04                    |       |
   * |                                 |     | qqq     | Q1, Q2, Q3, Q4                    |       |
   * |                                 |     | qqqq    | 1st quarter, 2nd quarter, ...     | 2     |
   * |                                 |     | qqqqq   | 1, 2, 3, 4                        | 3     |
   * | Month (formatting)              | 110 | M       | 1, 2, ..., 12                     |       |
   * |                                 |     | Mo      | 1st, 2nd, ..., 12th               | 5     |
   * |                                 |     | MM      | 01, 02, ..., 12                   |       |
   * |                                 |     | MMM     | Jan, Feb, ..., Dec                |       |
   * |                                 |     | MMMM    | January, February, ..., December  | 2     |
   * |                                 |     | MMMMM   | J, F, ..., D                      |       |
   * | Month (stand-alone)             | 110 | L       | 1, 2, ..., 12                     |       |
   * |                                 |     | Lo      | 1st, 2nd, ..., 12th               | 5     |
   * |                                 |     | LL      | 01, 02, ..., 12                   |       |
   * |                                 |     | LLL     | Jan, Feb, ..., Dec                |       |
   * |                                 |     | LLLL    | January, February, ..., December  | 2     |
   * |                                 |     | LLLLL   | J, F, ..., D                      |       |
   * | Local week of year              | 100 | w       | 1, 2, ..., 53                     |       |
   * |                                 |     | wo      | 1st, 2nd, ..., 53th               | 5     |
   * |                                 |     | ww      | 01, 02, ..., 53                   |       |
   * | ISO week of year                | 100 | I       | 1, 2, ..., 53                     | 5     |
   * |                                 |     | Io      | 1st, 2nd, ..., 53th               | 5     |
   * |                                 |     | II      | 01, 02, ..., 53                   | 5     |
   * | Day of month                    |  90 | d       | 1, 2, ..., 31                     |       |
   * |                                 |     | do      | 1st, 2nd, ..., 31st               | 5     |
   * |                                 |     | dd      | 01, 02, ..., 31                   |       |
   * | Day of year                     |  90 | D       | 1, 2, ..., 365, 366               | 7     |
   * |                                 |     | Do      | 1st, 2nd, ..., 365th, 366th       | 5     |
   * |                                 |     | DD      | 01, 02, ..., 365, 366             | 7     |
   * |                                 |     | DDD     | 001, 002, ..., 365, 366           |       |
   * |                                 |     | DDDD    | ...                               | 2     |
   * | Day of week (formatting)        |  90 | E..EEE  | Mon, Tue, Wed, ..., Sun           |       |
   * |                                 |     | EEEE    | Monday, Tuesday, ..., Sunday      | 2     |
   * |                                 |     | EEEEE   | M, T, W, T, F, S, S               |       |
   * |                                 |     | EEEEEE  | Mo, Tu, We, Th, Fr, Sa, Su        |       |
   * | ISO day of week (formatting)    |  90 | i       | 1, 2, 3, ..., 7                   | 5     |
   * |                                 |     | io      | 1st, 2nd, ..., 7th                | 5     |
   * |                                 |     | ii      | 01, 02, ..., 07                   | 5     |
   * |                                 |     | iii     | Mon, Tue, Wed, ..., Sun           | 5     |
   * |                                 |     | iiii    | Monday, Tuesday, ..., Sunday      | 2,5   |
   * |                                 |     | iiiii   | M, T, W, T, F, S, S               | 5     |
   * |                                 |     | iiiiii  | Mo, Tu, We, Th, Fr, Sa, Su        | 5     |
   * | Local day of week (formatting)  |  90 | e       | 2, 3, 4, ..., 1                   |       |
   * |                                 |     | eo      | 2nd, 3rd, ..., 1st                | 5     |
   * |                                 |     | ee      | 02, 03, ..., 01                   |       |
   * |                                 |     | eee     | Mon, Tue, Wed, ..., Sun           |       |
   * |                                 |     | eeee    | Monday, Tuesday, ..., Sunday      | 2     |
   * |                                 |     | eeeee   | M, T, W, T, F, S, S               |       |
   * |                                 |     | eeeeee  | Mo, Tu, We, Th, Fr, Sa, Su        |       |
   * | Local day of week (stand-alone) |  90 | c       | 2, 3, 4, ..., 1                   |       |
   * |                                 |     | co      | 2nd, 3rd, ..., 1st                | 5     |
   * |                                 |     | cc      | 02, 03, ..., 01                   |       |
   * |                                 |     | ccc     | Mon, Tue, Wed, ..., Sun           |       |
   * |                                 |     | cccc    | Monday, Tuesday, ..., Sunday      | 2     |
   * |                                 |     | ccccc   | M, T, W, T, F, S, S               |       |
   * |                                 |     | cccccc  | Mo, Tu, We, Th, Fr, Sa, Su        |       |
   * | AM, PM                          |  80 | a..aaa  | AM, PM                            |       |
   * |                                 |     | aaaa    | a.m., p.m.                        | 2     |
   * |                                 |     | aaaaa   | a, p                              |       |
   * | AM, PM, noon, midnight          |  80 | b..bbb  | AM, PM, noon, midnight            |       |
   * |                                 |     | bbbb    | a.m., p.m., noon, midnight        | 2     |
   * |                                 |     | bbbbb   | a, p, n, mi                       |       |
   * | Flexible day period             |  80 | B..BBB  | at night, in the morning, ...     |       |
   * |                                 |     | BBBB    | at night, in the morning, ...     | 2     |
   * |                                 |     | BBBBB   | at night, in the morning, ...     |       |
   * | Hour [1-12]                     |  70 | h       | 1, 2, ..., 11, 12                 |       |
   * |                                 |     | ho      | 1st, 2nd, ..., 11th, 12th         | 5     |
   * |                                 |     | hh      | 01, 02, ..., 11, 12               |       |
   * | Hour [0-23]                     |  70 | H       | 0, 1, 2, ..., 23                  |       |
   * |                                 |     | Ho      | 0th, 1st, 2nd, ..., 23rd          | 5     |
   * |                                 |     | HH      | 00, 01, 02, ..., 23               |       |
   * | Hour [0-11]                     |  70 | K       | 1, 2, ..., 11, 0                  |       |
   * |                                 |     | Ko      | 1st, 2nd, ..., 11th, 0th          | 5     |
   * |                                 |     | KK      | 01, 02, ..., 11, 00               |       |
   * | Hour [1-24]                     |  70 | k       | 24, 1, 2, ..., 23                 |       |
   * |                                 |     | ko      | 24th, 1st, 2nd, ..., 23rd         | 5     |
   * |                                 |     | kk      | 24, 01, 02, ..., 23               |       |
   * | Minute                          |  60 | m       | 0, 1, ..., 59                     |       |
   * |                                 |     | mo      | 0th, 1st, ..., 59th               | 5     |
   * |                                 |     | mm      | 00, 01, ..., 59                   |       |
   * | Second                          |  50 | s       | 0, 1, ..., 59                     |       |
   * |                                 |     | so      | 0th, 1st, ..., 59th               | 5     |
   * |                                 |     | ss      | 00, 01, ..., 59                   |       |
   * | Seconds timestamp               |  40 | t       | 512969520                         |       |
   * |                                 |     | tt      | ...                               | 2     |
   * | Fraction of second              |  30 | S       | 0, 1, ..., 9                      |       |
   * |                                 |     | SS      | 00, 01, ..., 99                   |       |
   * |                                 |     | SSS     | 000, 001, ..., 999                |       |
   * |                                 |     | SSSS    | ...                               | 2     |
   * | Milliseconds timestamp          |  20 | T       | 512969520900                      |       |
   * |                                 |     | TT      | ...                               | 2     |
   * | Timezone (ISO-8601 w/ Z)        |  10 | X       | -08, +0530, Z                     |       |
   * |                                 |     | XX      | -0800, +0530, Z                   |       |
   * |                                 |     | XXX     | -08:00, +05:30, Z                 |       |
   * |                                 |     | XXXX    | -0800, +0530, Z, +123456          | 2     |
   * |                                 |     | XXXXX   | -08:00, +05:30, Z, +12:34:56      |       |
   * | Timezone (ISO-8601 w/o Z)       |  10 | x       | -08, +0530, +00                   |       |
   * |                                 |     | xx      | -0800, +0530, +0000               |       |
   * |                                 |     | xxx     | -08:00, +05:30, +00:00            | 2     |
   * |                                 |     | xxxx    | -0800, +0530, +0000, +123456      |       |
   * |                                 |     | xxxxx   | -08:00, +05:30, +00:00, +12:34:56 |       |
   * | Long localized date             |  NA | P       | 05/29/1453                        | 5,8   |
   * |                                 |     | PP      | May 29, 1453                      |       |
   * |                                 |     | PPP     | May 29th, 1453                    |       |
   * |                                 |     | PPPP    | Sunday, May 29th, 1453            | 2,5,8 |
   * | Long localized time             |  NA | p       | 12:00 AM                          | 5,8   |
   * |                                 |     | pp      | 12:00:00 AM                       |       |
   * | Combination of date and time    |  NA | Pp      | 05/29/1453, 12:00 AM              |       |
   * |                                 |     | PPpp    | May 29, 1453, 12:00:00 AM         |       |
   * |                                 |     | PPPpp   | May 29th, 1453 at ...             |       |
   * |                                 |     | PPPPpp  | Sunday, May 29th, 1453 at ...     | 2,5,8 |
   * Notes:
   * 1. "Formatting" units (e.g. formatting quarter) in the default en-US locale
   *    are the same as "stand-alone" units, but are different in some languages.
   *    "Formatting" units are declined according to the rules of the language
   *    in the context of a date. "Stand-alone" units are always nominative singular.
   *    In `format` function, they will produce different result:
   *
   *    `format(new Date(2017, 10, 6), 'do LLLL', {locale: cs}) //=> '6. listopad'`
   *
   *    `format(new Date(2017, 10, 6), 'do MMMM', {locale: cs}) //=> '6. listopadu'`
   *
   *    `parse` will try to match both formatting and stand-alone units interchangably.
   *
   * 2. Any sequence of the identical letters is a pattern, unless it is escaped by
   *    the single quote characters (see below).
   *    If the sequence is longer than listed in table:
   *    - for numerical units (`yyyyyyyy`) `parse` will try to match a number
   *      as wide as the sequence
   *    - for text units (`MMMMMMMM`) `parse` will try to match the widest variation of the unit.
   *      These variations are marked with "2" in the last column of the table.
   *
   * 3. `QQQQQ` and `qqqqq` could be not strictly numerical in some locales.
   *    These tokens represent the shortest form of the quarter.
   *
   * 4. The main difference between `y` and `u` patterns are B.C. years:
   *
   *    | Year | `y` | `u` |
   *    |------|-----|-----|
   *    | AC 1 |   1 |   1 |
   *    | BC 1 |   1 |   0 |
   *    | BC 2 |   2 |  -1 |
   *
   *    Also `yy` will try to guess the century of two digit year by proximity with `referenceDate`:
   *
   *    `parse('50', 'yy', new Date(2018, 0, 1)) //=> Sat Jan 01 2050 00:00:00`
   *
   *    `parse('75', 'yy', new Date(2018, 0, 1)) //=> Wed Jan 01 1975 00:00:00`
   *
   *    while `uu` will just assign the year as is:
   *
   *    `parse('50', 'uu', new Date(2018, 0, 1)) //=> Sat Jan 01 0050 00:00:00`
   *
   *    `parse('75', 'uu', new Date(2018, 0, 1)) //=> Tue Jan 01 0075 00:00:00`
   *
   *    The same difference is true for local and ISO week-numbering years (`Y` and `R`),
   *    except local week-numbering years are dependent on `options.weekStartsOn`
   *    and `options.firstWeekContainsDate` (compare [setISOWeekYear]{@link https://date-fns.org/docs/setISOWeekYear}
   *    and [setWeekYear]{@link https://date-fns.org/docs/setWeekYear}).
   *
   * 5. These patterns are not in the Unicode Technical Standard #35:
   *    - `i`: ISO day of week
   *    - `I`: ISO week of year
   *    - `R`: ISO week-numbering year
   *    - `o`: ordinal number modifier
   *    - `P`: long localized date
   *    - `p`: long localized time
   *
   * 6. `YY` and `YYYY` tokens represent week-numbering years but they are often confused with years.
   *    You should enable `options.useAdditionalWeekYearTokens` to use them. See: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   *
   * 7. `D` and `DD` tokens represent days of the year but they are ofthen confused with days of the month.
   *    You should enable `options.useAdditionalDayOfYearTokens` to use them. See: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   *
   * 8. `P+` tokens do not have a defined priority since they are merely aliases to other tokens based
   *    on the given locale.
   *
   *    using `en-US` locale: `P` => `MM/dd/yyyy`
   *    using `en-US` locale: `p` => `hh:mm a`
   *    using `pt-BR` locale: `P` => `dd/MM/yyyy`
   *    using `pt-BR` locale: `p` => `HH:mm`
   *
   * Values will be assigned to the date in the descending order of its unit's priority.
   * Units of an equal priority overwrite each other in the order of appearance.
   *
   * If no values of higher priority are parsed (e.g. when parsing string 'January 1st' without a year),
   * the values will be taken from 3rd argument `referenceDate` which works as a context of parsing.
   *
   * `referenceDate` must be passed for correct work of the function.
   * If you're not sure which `referenceDate` to supply, create a new instance of Date:
   * `parse('02/11/2014', 'MM/dd/yyyy', new Date())`
   * In this case parsing will be done in the context of the current date.
   * If `referenceDate` is `Invalid Date` or a value not convertible to valid `Date`,
   * then `Invalid Date` will be returned.
   *
   * The result may vary by locale.
   *
   * If `formatString` matches with `dateString` but does not provides tokens, `referenceDate` will be returned.
   *
   * If parsing failed, `Invalid Date` will be returned.
   * Invalid Date is a Date, whose time value is NaN.
   * Time value of Date: http://es5.github.io/#x15.9.1.1
   *
   * @param {String} dateString - the string to parse
   * @param {String} formatString - the string of tokens
   * @param {Date|Number} referenceDate - defines values missing from the parsed dateString
   * @param {Object} [options] - an object with options.
   * @param {Locale} [options.locale=defaultLocale] - the locale object. See [Locale]{@link https://date-fns.org/docs/Locale}
   * @param {0|1|2|3|4|5|6} [options.weekStartsOn=0] - the index of the first day of the week (0 - Sunday)
   * @param {1|2|3|4|5|6|7} [options.firstWeekContainsDate=1] - the day of January, which is always in the first week of the year
   * @param {Boolean} [options.useAdditionalWeekYearTokens=false] - if true, allows usage of the week-numbering year tokens `YY` and `YYYY`;
   *   see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @param {Boolean} [options.useAdditionalDayOfYearTokens=false] - if true, allows usage of the day of year tokens `D` and `DD`;
   *   see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @returns {Date} the parsed date
   * @throws {TypeError} 3 arguments required
   * @throws {RangeError} `options.weekStartsOn` must be between 0 and 6
   * @throws {RangeError} `options.firstWeekContainsDate` must be between 1 and 7
   * @throws {RangeError} `options.locale` must contain `match` property
   * @throws {RangeError} use `yyyy` instead of `YYYY` for formatting years using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} use `yy` instead of `YY` for formatting years using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} use `d` instead of `D` for formatting days of the month using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} use `dd` instead of `DD` for formatting days of the month using [format provided] to the input [input provided]; see: https://github.com/date-fns/date-fns/blob/master/docs/unicodeTokens.md
   * @throws {RangeError} format string contains an unescaped latin alphabet character
   *
   * @example
   * // Parse 11 February 2014 from middle-endian format:
   * var result = parse('02/11/2014', 'MM/dd/yyyy', new Date())
   * //=> Tue Feb 11 2014 00:00:00
   *
   * @example
   * // Parse 28th of February in Esperanto locale in the context of 2010 year:
   * import eo from 'date-fns/locale/eo'
   * var result = parse('28-a de februaro', "do 'de' MMMM", new Date(2010, 0, 1), {
   *   locale: eo
   * })
   * //=> Sun Feb 28 2010 00:00:00
   */

  function parse(dirtyDateString, dirtyFormatString, dirtyReferenceDate, options) {
    var _ref, _options$locale, _ref2, _ref3, _ref4, _options$firstWeekCon, _options$locale2, _options$locale2$opti, _defaultOptions$local, _defaultOptions$local2, _ref5, _ref6, _ref7, _options$weekStartsOn, _options$locale3, _options$locale3$opti, _defaultOptions$local3, _defaultOptions$local4;

    requiredArgs(3, arguments);
    var dateString = String(dirtyDateString);
    var formatString = String(dirtyFormatString);
    var defaultOptions = getDefaultOptions();
    var locale = (_ref = (_options$locale = options === null || options === void 0 ? void 0 : options.locale) !== null && _options$locale !== void 0 ? _options$locale : defaultOptions.locale) !== null && _ref !== void 0 ? _ref : defaultLocale;

    if (!locale.match) {
      throw new RangeError('locale must contain match property');
    }

    var firstWeekContainsDate = toInteger((_ref2 = (_ref3 = (_ref4 = (_options$firstWeekCon = options === null || options === void 0 ? void 0 : options.firstWeekContainsDate) !== null && _options$firstWeekCon !== void 0 ? _options$firstWeekCon : options === null || options === void 0 ? void 0 : (_options$locale2 = options.locale) === null || _options$locale2 === void 0 ? void 0 : (_options$locale2$opti = _options$locale2.options) === null || _options$locale2$opti === void 0 ? void 0 : _options$locale2$opti.firstWeekContainsDate) !== null && _ref4 !== void 0 ? _ref4 : defaultOptions.firstWeekContainsDate) !== null && _ref3 !== void 0 ? _ref3 : (_defaultOptions$local = defaultOptions.locale) === null || _defaultOptions$local === void 0 ? void 0 : (_defaultOptions$local2 = _defaultOptions$local.options) === null || _defaultOptions$local2 === void 0 ? void 0 : _defaultOptions$local2.firstWeekContainsDate) !== null && _ref2 !== void 0 ? _ref2 : 1); // Test if weekStartsOn is between 1 and 7 _and_ is not NaN

    if (!(firstWeekContainsDate >= 1 && firstWeekContainsDate <= 7)) {
      throw new RangeError('firstWeekContainsDate must be between 1 and 7 inclusively');
    }

    var weekStartsOn = toInteger((_ref5 = (_ref6 = (_ref7 = (_options$weekStartsOn = options === null || options === void 0 ? void 0 : options.weekStartsOn) !== null && _options$weekStartsOn !== void 0 ? _options$weekStartsOn : options === null || options === void 0 ? void 0 : (_options$locale3 = options.locale) === null || _options$locale3 === void 0 ? void 0 : (_options$locale3$opti = _options$locale3.options) === null || _options$locale3$opti === void 0 ? void 0 : _options$locale3$opti.weekStartsOn) !== null && _ref7 !== void 0 ? _ref7 : defaultOptions.weekStartsOn) !== null && _ref6 !== void 0 ? _ref6 : (_defaultOptions$local3 = defaultOptions.locale) === null || _defaultOptions$local3 === void 0 ? void 0 : (_defaultOptions$local4 = _defaultOptions$local3.options) === null || _defaultOptions$local4 === void 0 ? void 0 : _defaultOptions$local4.weekStartsOn) !== null && _ref5 !== void 0 ? _ref5 : 0); // Test if weekStartsOn is between 0 and 6 _and_ is not NaN

    if (!(weekStartsOn >= 0 && weekStartsOn <= 6)) {
      throw new RangeError('weekStartsOn must be between 0 and 6 inclusively');
    }

    if (formatString === '') {
      if (dateString === '') {
        return toDate(dirtyReferenceDate);
      } else {
        return new Date(NaN);
      }
    }

    var subFnOptions = {
      firstWeekContainsDate: firstWeekContainsDate,
      weekStartsOn: weekStartsOn,
      locale: locale
    }; // If timezone isn't specified, it will be set to the system timezone

    var setters = [new DateToSystemTimezoneSetter()];
    var tokens = formatString.match(longFormattingTokensRegExp).map(function (substring) {
      var firstCharacter = substring[0];

      if (firstCharacter in longFormatters$1) {
        var longFormatter = longFormatters$1[firstCharacter];
        return longFormatter(substring, locale.formatLong);
      }

      return substring;
    }).join('').match(formattingTokensRegExp);
    var usedTokens = [];

    var _loop = function _loop(_token) {
      if (!(options !== null && options !== void 0 && options.useAdditionalWeekYearTokens) && isProtectedWeekYearToken(_token)) {
        throwProtectedError(_token, formatString, dirtyDateString);
      }

      if (!(options !== null && options !== void 0 && options.useAdditionalDayOfYearTokens) && isProtectedDayOfYearToken(_token)) {
        throwProtectedError(_token, formatString, dirtyDateString);
      }

      var firstCharacter = _token[0];
      var parser = parsers[firstCharacter];

      if (parser) {
        var incompatibleTokens = parser.incompatibleTokens;

        if (Array.isArray(incompatibleTokens)) {
          var incompatibleToken = usedTokens.find(function (usedToken) {
            return incompatibleTokens.includes(usedToken.token) || usedToken.token === firstCharacter;
          });

          if (incompatibleToken) {
            throw new RangeError("The format string mustn't contain `".concat(incompatibleToken.fullToken, "` and `").concat(_token, "` at the same time"));
          }
        } else if (parser.incompatibleTokens === '*' && usedTokens.length > 0) {
          throw new RangeError("The format string mustn't contain `".concat(_token, "` and any other token at the same time"));
        }

        usedTokens.push({
          token: firstCharacter,
          fullToken: _token
        });
        var parseResult = parser.run(dateString, _token, locale.match, subFnOptions);

        if (!parseResult) {
          token = _token;
          return {
            v: new Date(NaN)
          };
        }

        setters.push(parseResult.setter);
        dateString = parseResult.rest;
      } else {
        if (firstCharacter.match(unescapedLatinCharacterRegExp)) {
          throw new RangeError('Format string contains an unescaped latin alphabet character `' + firstCharacter + '`');
        } // Replace two single quote characters with one single quote character


        if (_token === "''") {
          _token = "'";
        } else if (firstCharacter === "'") {
          _token = cleanEscapedString(_token);
        } // Cut token from string, or, if string doesn't match the token, return Invalid Date


        if (dateString.indexOf(_token) === 0) {
          dateString = dateString.slice(_token.length);
        } else {
          token = _token;
          return {
            v: new Date(NaN)
          };
        }
      }

      token = _token;
    };

    var _iterator = _createForOfIteratorHelper(tokens),
        _step;

    try {
      for (_iterator.s(); !(_step = _iterator.n()).done;) {
        var token = _step.value;

        var _ret = _loop(token);

        if (_typeof(_ret) === "object") return _ret.v;
      } // Check if the remaining input contains something other than whitespace

    } catch (err) {
      _iterator.e(err);
    } finally {
      _iterator.f();
    }

    if (dateString.length > 0 && notWhitespaceRegExp.test(dateString)) {
      return new Date(NaN);
    }

    var uniquePrioritySetters = setters.map(function (setter) {
      return setter.priority;
    }).sort(function (a, b) {
      return b - a;
    }).filter(function (priority, index, array) {
      return array.indexOf(priority) === index;
    }).map(function (priority) {
      return setters.filter(function (setter) {
        return setter.priority === priority;
      }).sort(function (a, b) {
        return b.subPriority - a.subPriority;
      });
    }).map(function (setterArray) {
      return setterArray[0];
    });
    var date = toDate(dirtyReferenceDate);

    if (isNaN(date.getTime())) {
      return new Date(NaN);
    } // Convert the date in system timezone to the same date in UTC+00:00 timezone.


    var utcDate = subMilliseconds(date, getTimezoneOffsetInMilliseconds(date));
    var flags = {};

    var _iterator2 = _createForOfIteratorHelper(uniquePrioritySetters),
        _step2;

    try {
      for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
        var setter = _step2.value;

        if (!setter.validate(utcDate, subFnOptions)) {
          return new Date(NaN);
        }

        var result = setter.set(utcDate, flags, subFnOptions); // Result is tuple (date, flags)

        if (Array.isArray(result)) {
          utcDate = result[0];
          assign(flags, result[1]); // Result is date
        } else {
          utcDate = result;
        }
      }
    } catch (err) {
      _iterator2.e(err);
    } finally {
      _iterator2.f();
    }

    return utcDate;
  }

  function cleanEscapedString(input) {
    return input.match(escapedStringRegExp)[1].replace(doubleQuoteRegExp, "'");
  }

  /**
   * @name startOfHour
   * @category Hour Helpers
   * @summary Return the start of an hour for the given date.
   *
   * @description
   * Return the start of an hour for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of an hour
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of an hour for 2 September 2014 11:55:00:
   * const result = startOfHour(new Date(2014, 8, 2, 11, 55))
   * //=> Tue Sep 02 2014 11:00:00
   */

  function startOfHour(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setMinutes(0, 0, 0);
    return date;
  }

  /**
   * @name startOfSecond
   * @category Second Helpers
   * @summary Return the start of a second for the given date.
   *
   * @description
   * Return the start of a second for the given date.
   * The result will be in the local timezone.
   *
   * @param {Date|Number} date - the original date
   * @returns {Date} the start of a second
   * @throws {TypeError} 1 argument required
   *
   * @example
   * // The start of a second for 1 December 2014 22:15:45.400:
   * const result = startOfSecond(new Date(2014, 11, 1, 22, 15, 45, 400))
   * //=> Mon Dec 01 2014 22:15:45.000
   */

  function startOfSecond(dirtyDate) {
    requiredArgs(1, arguments);
    var date = toDate(dirtyDate);
    date.setMilliseconds(0);
    return date;
  }

  /**
   * @name parseISO
   * @category Common Helpers
   * @summary Parse ISO string
   *
   * @description
   * Parse the given string in ISO 8601 format and return an instance of Date.
   *
   * Function accepts complete ISO 8601 formats as well as partial implementations.
   * ISO 8601: http://en.wikipedia.org/wiki/ISO_8601
   *
   * If the argument isn't a string, the function cannot parse the string or
   * the values are invalid, it returns Invalid Date.
   *
   * @param {String} argument - the value to convert
   * @param {Object} [options] - an object with options.
   * @param {0|1|2} [options.additionalDigits=2] - the additional number of digits in the extended year format
   * @returns {Date} the parsed date in the local time zone
   * @throws {TypeError} 1 argument required
   * @throws {RangeError} `options.additionalDigits` must be 0, 1 or 2
   *
   * @example
   * // Convert string '2014-02-11T11:30:30' to date:
   * const result = parseISO('2014-02-11T11:30:30')
   * //=> Tue Feb 11 2014 11:30:30
   *
   * @example
   * // Convert string '+02014101' to date,
   * // if the additional number of digits in the extended year format is 1:
   * const result = parseISO('+02014101', { additionalDigits: 1 })
   * //=> Fri Apr 11 2014 00:00:00
   */

  function parseISO(argument, options) {
    var _options$additionalDi;

    requiredArgs(1, arguments);
    var additionalDigits = toInteger((_options$additionalDi = options === null || options === void 0 ? void 0 : options.additionalDigits) !== null && _options$additionalDi !== void 0 ? _options$additionalDi : 2);

    if (additionalDigits !== 2 && additionalDigits !== 1 && additionalDigits !== 0) {
      throw new RangeError('additionalDigits must be 0, 1 or 2');
    }

    if (!(typeof argument === 'string' || Object.prototype.toString.call(argument) === '[object String]')) {
      return new Date(NaN);
    }

    var dateStrings = splitDateString(argument);
    var date;

    if (dateStrings.date) {
      var parseYearResult = parseYear(dateStrings.date, additionalDigits);
      date = parseDate(parseYearResult.restDateString, parseYearResult.year);
    }

    if (!date || isNaN(date.getTime())) {
      return new Date(NaN);
    }

    var timestamp = date.getTime();
    var time = 0;
    var offset;

    if (dateStrings.time) {
      time = parseTime(dateStrings.time);

      if (isNaN(time)) {
        return new Date(NaN);
      }
    }

    if (dateStrings.timezone) {
      offset = parseTimezone(dateStrings.timezone);

      if (isNaN(offset)) {
        return new Date(NaN);
      }
    } else {
      var dirtyDate = new Date(timestamp + time); // js parsed string assuming it's in UTC timezone
      // but we need it to be parsed in our timezone
      // so we use utc values to build date in our timezone.
      // Year values from 0 to 99 map to the years 1900 to 1999
      // so set year explicitly with setFullYear.

      var result = new Date(0);
      result.setFullYear(dirtyDate.getUTCFullYear(), dirtyDate.getUTCMonth(), dirtyDate.getUTCDate());
      result.setHours(dirtyDate.getUTCHours(), dirtyDate.getUTCMinutes(), dirtyDate.getUTCSeconds(), dirtyDate.getUTCMilliseconds());
      return result;
    }

    return new Date(timestamp + time + offset);
  }
  var patterns = {
    dateTimeDelimiter: /[T ]/,
    timeZoneDelimiter: /[Z ]/i,
    timezone: /([Z+-].*)$/
  };
  var dateRegex = /^-?(?:(\d{3})|(\d{2})(?:-?(\d{2}))?|W(\d{2})(?:-?(\d{1}))?|)$/;
  var timeRegex = /^(\d{2}(?:[.,]\d*)?)(?::?(\d{2}(?:[.,]\d*)?))?(?::?(\d{2}(?:[.,]\d*)?))?$/;
  var timezoneRegex = /^([+-])(\d{2})(?::?(\d{2}))?$/;

  function splitDateString(dateString) {
    var dateStrings = {};
    var array = dateString.split(patterns.dateTimeDelimiter);
    var timeString; // The regex match should only return at maximum two array elements.
    // [date], [time], or [date, time].

    if (array.length > 2) {
      return dateStrings;
    }

    if (/:/.test(array[0])) {
      timeString = array[0];
    } else {
      dateStrings.date = array[0];
      timeString = array[1];

      if (patterns.timeZoneDelimiter.test(dateStrings.date)) {
        dateStrings.date = dateString.split(patterns.timeZoneDelimiter)[0];
        timeString = dateString.substr(dateStrings.date.length, dateString.length);
      }
    }

    if (timeString) {
      var token = patterns.timezone.exec(timeString);

      if (token) {
        dateStrings.time = timeString.replace(token[1], '');
        dateStrings.timezone = token[1];
      } else {
        dateStrings.time = timeString;
      }
    }

    return dateStrings;
  }

  function parseYear(dateString, additionalDigits) {
    var regex = new RegExp('^(?:(\\d{4}|[+-]\\d{' + (4 + additionalDigits) + '})|(\\d{2}|[+-]\\d{' + (2 + additionalDigits) + '})$)');
    var captures = dateString.match(regex); // Invalid ISO-formatted year

    if (!captures) return {
      year: NaN,
      restDateString: ''
    };
    var year = captures[1] ? parseInt(captures[1]) : null;
    var century = captures[2] ? parseInt(captures[2]) : null; // either year or century is null, not both

    return {
      year: century === null ? year : century * 100,
      restDateString: dateString.slice((captures[1] || captures[2]).length)
    };
  }

  function parseDate(dateString, year) {
    // Invalid ISO-formatted year
    if (year === null) return new Date(NaN);
    var captures = dateString.match(dateRegex); // Invalid ISO-formatted string

    if (!captures) return new Date(NaN);
    var isWeekDate = !!captures[4];
    var dayOfYear = parseDateUnit(captures[1]);
    var month = parseDateUnit(captures[2]) - 1;
    var day = parseDateUnit(captures[3]);
    var week = parseDateUnit(captures[4]);
    var dayOfWeek = parseDateUnit(captures[5]) - 1;

    if (isWeekDate) {
      if (!validateWeekDate(year, week, dayOfWeek)) {
        return new Date(NaN);
      }

      return dayOfISOWeekYear(year, week, dayOfWeek);
    } else {
      var date = new Date(0);

      if (!validateDate(year, month, day) || !validateDayOfYearDate(year, dayOfYear)) {
        return new Date(NaN);
      }

      date.setUTCFullYear(year, month, Math.max(dayOfYear, day));
      return date;
    }
  }

  function parseDateUnit(value) {
    return value ? parseInt(value) : 1;
  }

  function parseTime(timeString) {
    var captures = timeString.match(timeRegex);
    if (!captures) return NaN; // Invalid ISO-formatted time

    var hours = parseTimeUnit(captures[1]);
    var minutes = parseTimeUnit(captures[2]);
    var seconds = parseTimeUnit(captures[3]);

    if (!validateTime(hours, minutes, seconds)) {
      return NaN;
    }

    return hours * millisecondsInHour + minutes * millisecondsInMinute + seconds * 1000;
  }

  function parseTimeUnit(value) {
    return value && parseFloat(value.replace(',', '.')) || 0;
  }

  function parseTimezone(timezoneString) {
    if (timezoneString === 'Z') return 0;
    var captures = timezoneString.match(timezoneRegex);
    if (!captures) return 0;
    var sign = captures[1] === '+' ? -1 : 1;
    var hours = parseInt(captures[2]);
    var minutes = captures[3] && parseInt(captures[3]) || 0;

    if (!validateTimezone(hours, minutes)) {
      return NaN;
    }

    return sign * (hours * millisecondsInHour + minutes * millisecondsInMinute);
  }

  function dayOfISOWeekYear(isoWeekYear, week, day) {
    var date = new Date(0);
    date.setUTCFullYear(isoWeekYear, 0, 4);
    var fourthOfJanuaryDay = date.getUTCDay() || 7;
    var diff = (week - 1) * 7 + day + 1 - fourthOfJanuaryDay;
    date.setUTCDate(date.getUTCDate() + diff);
    return date;
  } // Validation functions
  // February is null to handle the leap year (using ||)


  var daysInMonths = [31, null, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  function isLeapYearIndex(year) {
    return year % 400 === 0 || year % 4 === 0 && year % 100 !== 0;
  }

  function validateDate(year, month, date) {
    return month >= 0 && month <= 11 && date >= 1 && date <= (daysInMonths[month] || (isLeapYearIndex(year) ? 29 : 28));
  }

  function validateDayOfYearDate(year, dayOfYear) {
    return dayOfYear >= 1 && dayOfYear <= (isLeapYearIndex(year) ? 366 : 365);
  }

  function validateWeekDate(_year, week, day) {
    return week >= 1 && week <= 53 && day >= 0 && day <= 6;
  }

  function validateTime(hours, minutes, seconds) {
    if (hours === 24) {
      return minutes === 0 && seconds === 0;
    }

    return seconds >= 0 && seconds < 60 && minutes >= 0 && minutes < 60 && hours >= 0 && hours < 25;
  }

  function validateTimezone(_hours, minutes) {
    return minutes >= 0 && minutes <= 59;
  }

  var FORMATS = {
    datetime: 'MMM d, yyyy, h:mm:ss aaaa',
    millisecond: 'h:mm:ss.SSS aaaa',
    second: 'h:mm:ss aaaa',
    minute: 'h:mm aaaa',
    hour: 'ha',
    day: 'MMM d',
    week: 'PP',
    month: 'MMM yyyy',
    quarter: 'qqq - yyyy',
    year: 'yyyy'
  };

  adapters._date.override({
    _id: 'date-fns',
    // DEBUG
    formats: function formats() {
      return FORMATS;
    },
    parse: function parse$1(value, fmt) {
      if (value === null || typeof value === 'undefined') {
        return null;
      }

      var type = _typeof(value);

      if (type === 'number' || value instanceof Date) {
        value = toDate(value);
      } else if (type === 'string') {
        if (typeof fmt === 'string') {
          value = parse(value, fmt, new Date(), this.options);
        } else {
          value = parseISO(value, this.options);
        }
      }

      return isValid(value) ? value.getTime() : null;
    },
    format: function format$1(time, fmt) {
      return format(time, fmt, this.options);
    },
    add: function add(time, amount, unit) {
      switch (unit) {
        case 'millisecond':
          return addMilliseconds(time, amount);

        case 'second':
          return addSeconds(time, amount);

        case 'minute':
          return addMinutes(time, amount);

        case 'hour':
          return addHours(time, amount);

        case 'day':
          return addDays(time, amount);

        case 'week':
          return addWeeks(time, amount);

        case 'month':
          return addMonths(time, amount);

        case 'quarter':
          return addQuarters(time, amount);

        case 'year':
          return addYears(time, amount);

        default:
          return time;
      }
    },
    diff: function diff(max, min, unit) {
      switch (unit) {
        case 'millisecond':
          return differenceInMilliseconds(max, min);

        case 'second':
          return differenceInSeconds(max, min);

        case 'minute':
          return differenceInMinutes(max, min);

        case 'hour':
          return differenceInHours(max, min);

        case 'day':
          return differenceInDays(max, min);

        case 'week':
          return differenceInWeeks(max, min);

        case 'month':
          return differenceInMonths(max, min);

        case 'quarter':
          return differenceInQuarters(max, min);

        case 'year':
          return differenceInYears(max, min);

        default:
          return 0;
      }
    },
    startOf: function startOf(time, unit, weekday) {
      switch (unit) {
        case 'second':
          return startOfSecond(time);

        case 'minute':
          return startOfMinute(time);

        case 'hour':
          return startOfHour(time);

        case 'day':
          return startOfDay(time);

        case 'week':
          return startOfWeek(time);

        case 'isoWeek':
          return startOfWeek(time, {
            weekStartsOn: +weekday
          });

        case 'month':
          return startOfMonth(time);

        case 'quarter':
          return startOfQuarter(time);

        case 'year':
          return startOfYear(time);

        default:
          return time;
      }
    },
    endOf: function endOf(time, unit) {
      switch (unit) {
        case 'second':
          return endOfSecond(time);

        case 'minute':
          return endOfMinute(time);

        case 'hour':
          return endOfHour(time);

        case 'day':
          return endOfDay(time);

        case 'week':
          return endOfWeek(time);

        case 'month':
          return endOfMonth(time);

        case 'quarter':
          return endOfQuarter(time);

        case 'year':
          return endOfYear(time);

        default:
          return time;
      }
    }
  });

  return Chart;

}));
