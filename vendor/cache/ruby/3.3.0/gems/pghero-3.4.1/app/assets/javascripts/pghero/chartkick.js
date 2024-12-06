/*!
 * Chartkick.js v5.0.1
 * Create beautiful charts with one line of JavaScript
 * https://github.com/ankane/chartkick.js
 * MIT License
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.Chartkick = factory());
})(this, (function () { 'use strict';

  function isArray(variable) {
    return Object.prototype.toString.call(variable) === "[object Array]";
  }

  function isFunction(variable) {
    return variable instanceof Function;
  }

  function isPlainObject(variable) {
    // protect against prototype pollution, defense 2
    return Object.prototype.toString.call(variable) === "[object Object]" && !isFunction(variable) && variable instanceof Object;
  }

  // https://github.com/madrobby/zepto/blob/master/src/zepto.js
  function extend(target, source) {
    for (var key in source) {
      // protect against prototype pollution, defense 1
      if (key === "__proto__") { continue; }

      if (isPlainObject(source[key]) || isArray(source[key])) {
        if (isPlainObject(source[key]) && !isPlainObject(target[key])) {
          target[key] = {};
        }
        if (isArray(source[key]) && !isArray(target[key])) {
          target[key] = [];
        }
        extend(target[key], source[key]);
      } else if (source[key] !== undefined) {
        target[key] = source[key];
      }
    }
  }

  function merge(obj1, obj2) {
    var target = {};
    extend(target, obj1);
    extend(target, obj2);
    return target;
  }

  var DATE_PATTERN = /^(\d\d\d\d)(?:-)?(\d\d)(?:-)?(\d\d)$/i;

  function negativeValues(series) {
    for (var i = 0; i < series.length; i++) {
      var data = series[i].data;
      for (var j = 0; j < data.length; j++) {
        if (data[j][1] < 0) {
          return true;
        }
      }
    }
    return false;
  }

  function toStr(obj) {
    return "" + obj;
  }

  function toFloat(obj) {
    return parseFloat(obj);
  }

  function toDate(obj) {
    if (obj instanceof Date) {
      return obj;
    } else if (typeof obj === "number") {
      return new Date(obj * 1000); // ms
    } else {
      var s = toStr(obj);
      var matches = s.match(DATE_PATTERN);
      if (matches) {
        var year = parseInt(matches[1], 10);
        var month = parseInt(matches[2], 10) - 1;
        var day = parseInt(matches[3], 10);
        return new Date(year, month, day);
      } else {
        // try our best to get the str into iso8601
        // TODO be smarter about this
        var str = s.replace(/ /, "T").replace(" ", "").replace("UTC", "Z");
        // Date.parse returns milliseconds if valid and NaN if invalid
        return new Date(Date.parse(str) || s);
      }
    }
  }

  function toArr(obj) {
    if (isArray(obj)) {
      return obj;
    } else {
      var arr = [];
      for (var i in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, i)) {
          arr.push([i, obj[i]]);
        }
      }
      return arr;
    }
  }

  function jsOptionsFunc(defaultOptions, hideLegend, setTitle, setMin, setMax, setStacked, setXtitle, setYtitle) {
    return function (chart, opts, chartOptions) {
      var series = chart.data;
      var options = merge({}, defaultOptions);
      options = merge(options, chartOptions || {});

      if (chart.singleSeriesFormat || "legend" in opts) {
        hideLegend(options, opts.legend, chart.singleSeriesFormat);
      }

      if (opts.title) {
        setTitle(options, opts.title);
      }

      // min
      if ("min" in opts) {
        setMin(options, opts.min);
      } else if (!negativeValues(series)) {
        setMin(options, 0);
      }

      // max
      if (opts.max) {
        setMax(options, opts.max);
      }

      if ("stacked" in opts) {
        setStacked(options, opts.stacked);
      }

      if (opts.colors) {
        options.colors = opts.colors;
      }

      if (opts.xtitle) {
        setXtitle(options, opts.xtitle);
      }

      if (opts.ytitle) {
        setYtitle(options, opts.ytitle);
      }

      // merge library last
      options = merge(options, opts.library || {});

      return options;
    };
  }

  function sortByTime(a, b) {
    return a[0].getTime() - b[0].getTime();
  }

  function sortByNumberSeries(a, b) {
    return a[0] - b[0];
  }

  // needed since sort() without arguments does string comparison
  function sortByNumber(a, b) {
    return a - b;
  }

  function every(values, fn) {
    for (var i = 0; i < values.length; i++) {
      if (!fn(values[i])) {
        return false;
      }
    }
    return true;
  }

  function isDay(timeUnit) {
    return timeUnit === "day" || timeUnit === "week" || timeUnit === "month" || timeUnit === "year";
  }

  function calculateTimeUnit(values, maxDay) {
    if ( maxDay === void 0 ) maxDay = false;

    if (values.length === 0) {
      return null;
    }

    var minute = every(values, function (d) { return d.getMilliseconds() === 0 && d.getSeconds() === 0; });
    if (!minute) {
      return null;
    }

    var hour = every(values, function (d) { return d.getMinutes() === 0; });
    if (!hour) {
      return "minute";
    }

    var day = every(values, function (d) { return d.getHours() === 0; });
    if (!day) {
      return "hour";
    }

    if (maxDay) {
      return "day";
    }

    var month = every(values, function (d) { return d.getDate() === 1; });
    if (!month) {
      var dayOfWeek = values[0].getDay();
      var week = every(values, function (d) { return d.getDay() === dayOfWeek; });
      return (week ? "week" : "day");
    }

    var year = every(values, function (d) { return d.getMonth() === 0; });
    if (!year) {
      return "month";
    }

    return "year";
  }

  function isDate(obj) {
    return !isNaN(toDate(obj)) && toStr(obj).length >= 6;
  }

  function isNumber(obj) {
    return typeof obj === "number";
  }

  var byteSuffixes = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB"];

  function formatValue(pre, value, options, axis) {
    pre = pre || "";
    if (options.prefix) {
      if (value < 0) {
        value = value * -1;
        pre += "-";
      }
      pre += options.prefix;
    }

    var suffix = options.suffix || "";
    var precision = options.precision;
    var round = options.round;

    if (options.byteScale) {
      var positive = value >= 0;
      if (!positive) {
        value *= -1;
      }

      var baseValue = axis ? options.byteScale : value;

      var suffixIdx;
      if (baseValue >= 1152921504606846976) {
        value /= 1152921504606846976;
        suffixIdx = 6;
      } else if (baseValue >= 1125899906842624) {
        value /= 1125899906842624;
        suffixIdx = 5;
      } else if (baseValue >= 1099511627776) {
        value /= 1099511627776;
        suffixIdx = 4;
      } else if (baseValue >= 1073741824) {
        value /= 1073741824;
        suffixIdx = 3;
      } else if (baseValue >= 1048576) {
        value /= 1048576;
        suffixIdx = 2;
      } else if (baseValue >= 1024) {
        value /= 1024;
        suffixIdx = 1;
      } else {
        suffixIdx = 0;
      }

      // TODO handle manual precision case
      if (precision === undefined && round === undefined) {
        if (value >= 1023.5) {
          if (suffixIdx < byteSuffixes.length - 1) {
            value = 1.0;
            suffixIdx += 1;
          }
        }
        precision = value >= 1000 ? 4 : 3;
      }
      suffix = " " + byteSuffixes[suffixIdx];

      // flip value back
      if (!positive) {
        value *= -1;
      }
    }

    if (precision !== undefined && round !== undefined) {
      throw Error("Use either round or precision, not both");
    }

    if (!axis) {
      if (precision !== undefined) {
        value = value.toPrecision(precision);
        if (!options.zeros) {
          value = parseFloat(value);
        }
      }

      if (round !== undefined) {
        if (round < 0) {
          var num = Math.pow(10, -1 * round);
          value = parseInt((1.0 * value / num).toFixed(0)) * num;
        } else {
          value = value.toFixed(round);
          if (!options.zeros) {
            value = parseFloat(value);
          }
        }
      }
    }

    if (options.thousands || options.decimal) {
      value = toStr(value);
      var parts = value.split(".");
      value = parts[0];
      if (options.thousands) {
        value = value.replace(/\B(?=(\d{3})+(?!\d))/g, options.thousands);
      }
      if (parts.length > 1) {
        value += (options.decimal || ".") + parts[1];
      }
    }

    return pre + value + suffix;
  }

  function seriesOption(chart, series, option) {
    if (option in series) {
      return series[option];
    } else if (option in chart.options) {
      return chart.options[option];
    }
    return null;
  }

  var baseOptions = {
    maintainAspectRatio: false,
    animation: false,
    plugins: {
      legend: {},
      tooltip: {
        displayColors: false,
        callbacks: {}
      },
      title: {
        font: {
          size: 20
        },
        color: "#333"
      }
    },
    interaction: {}
  };

  var defaultOptions$2 = {
    scales: {
      y: {
        ticks: {
          maxTicksLimit: 4
        },
        title: {
          font: {
            size: 16
          },
          color: "#333"
        },
        grid: {}
      },
      x: {
        grid: {
          drawOnChartArea: false
        },
        title: {
          font: {
            size: 16
          },
          color: "#333"
        },
        time: {},
        ticks: {}
      }
    }
  };

  // http://there4.io/2012/05/02/google-chart-color-list/
  var defaultColors = [
    "#3366CC", "#DC3912", "#FF9900", "#109618", "#990099", "#3B3EAC", "#0099C6",
    "#DD4477", "#66AA00", "#B82E2E", "#316395", "#994499", "#22AA99", "#AAAA11",
    "#6633CC", "#E67300", "#8B0707", "#329262", "#5574A6", "#651067"
  ];

  function hideLegend$2(options, legend, hideLegend) {
    if (legend !== undefined) {
      options.plugins.legend.display = !!legend;
      if (legend && legend !== true) {
        options.plugins.legend.position = legend;
      }
    } else if (hideLegend) {
      options.plugins.legend.display = false;
    }
  }

  function setTitle$2(options, title) {
    options.plugins.title.display = true;
    options.plugins.title.text = title;
  }

  function setMin$2(options, min) {
    if (min !== null) {
      options.scales.y.min = toFloat(min);
    }
  }

  function setMax$2(options, max) {
    options.scales.y.max = toFloat(max);
  }

  function setBarMin$1(options, min) {
    if (min !== null) {
      options.scales.x.min = toFloat(min);
    }
  }

  function setBarMax$1(options, max) {
    options.scales.x.max = toFloat(max);
  }

  function setStacked$2(options, stacked) {
    options.scales.x.stacked = !!stacked;
    options.scales.y.stacked = !!stacked;
  }

  function setXtitle$2(options, title) {
    options.scales.x.title.display = true;
    options.scales.x.title.text = title;
  }

  function setYtitle$2(options, title) {
    options.scales.y.title.display = true;
    options.scales.y.title.text = title;
  }

  // https://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb
  function addOpacity(hex, opacity) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? "rgba(" + parseInt(result[1], 16) + ", " + parseInt(result[2], 16) + ", " + parseInt(result[3], 16) + ", " + opacity + ")" : hex;
  }

  function notnull(x) {
    return x !== null && x !== undefined;
  }

  function setLabelSize(chart, data, options) {
    var maxLabelSize = Math.ceil(chart.element.offsetWidth / 4.0 / data.labels.length);
    if (maxLabelSize > 25) {
      maxLabelSize = 25;
    } else if (maxLabelSize < 10) {
      maxLabelSize = 10;
    }
    if (!options.scales.x.ticks.callback) {
      options.scales.x.ticks.callback = function (value) {
        value = toStr(this.getLabelForValue(value));
        if (value.length > maxLabelSize) {
          return value.substring(0, maxLabelSize - 2) + "...";
        } else {
          return value;
        }
      };
    }
  }

  function calculateScale(series) {
    var scale = 1;
    var max = maxAbsY(series);
    while (max >= 1024) {
      scale *= 1024;
      max /= 1024;
    }
    return scale;
  }

  function setFormatOptions$1(chart, options, chartType) {
    // options to apply to x and r values for scatter and bubble
    var numericOptions = {
      thousands: chart.options.thousands,
      decimal: chart.options.decimal
    };

    // options to apply to y value
    var formatOptions = merge({
      prefix: chart.options.prefix,
      suffix: chart.options.suffix,
      precision: chart.options.precision,
      round: chart.options.round,
      zeros: chart.options.zeros
    }, numericOptions);

    if (chart.options.bytes) {
      var series = chart.data;
      if (chartType === "pie") {
        series = [{data: series}];
      }

      // set step size
      formatOptions.byteScale = calculateScale(series);
    }

    if (chartType !== "pie") {
      var axis = options.scales.y;
      if (chartType === "bar") {
        axis = options.scales.x;
      }

      if (formatOptions.byteScale) {
        if (!axis.ticks.stepSize) {
          axis.ticks.stepSize = formatOptions.byteScale / 2;
        }
        if (!axis.ticks.maxTicksLimit) {
          axis.ticks.maxTicksLimit = 4;
        }
      }

      if (!axis.ticks.callback) {
        axis.ticks.callback = function (value) {
          return formatValue("", value, formatOptions, true);
        };
      }

      if ((chartType === "scatter" || chartType === "bubble") && !options.scales.x.ticks.callback) {
        options.scales.x.ticks.callback = function (value) {
          return formatValue("", value, numericOptions, true);
        };
      }
    }

    if (!options.plugins.tooltip.callbacks.label) {
      if (chartType === "scatter") {
        options.plugins.tooltip.callbacks.label = function (context) {
          var label = context.dataset.label || '';
          if (label) {
            label += ': ';
          }

          var dataPoint = context.parsed;
          return label + '(' + formatValue('', dataPoint.x, numericOptions) + ', ' + formatValue('', dataPoint.y, formatOptions) + ')';
        };
      } else if (chartType === "bubble") {
        options.plugins.tooltip.callbacks.label = function (context) {
          var label = context.dataset.label || '';
          if (label) {
            label += ': ';
          }
          var dataPoint = context.raw;
          return label + '(' + formatValue('', dataPoint.x, numericOptions) + ', ' + formatValue('', dataPoint.y, formatOptions) + ', ' + formatValue('', dataPoint.v, numericOptions) + ')';
        };
      } else if (chartType === "pie") {
        // need to use separate label for pie charts
        options.plugins.tooltip.callbacks.label = function (context) {
          return formatValue('', context.parsed, formatOptions);
        };
      } else {
        var valueLabel = chartType === "bar" ? "x" : "y";
        options.plugins.tooltip.callbacks.label = function (context) {
          // don't show null values for stacked charts
          if (context.parsed[valueLabel] === null) {
            return;
          }

          var label = context.dataset.label || '';
          if (label) {
            label += ': ';
          }
          return formatValue(label, context.parsed[valueLabel], formatOptions);
        };
      }
    }

    // avoid formatting x-axis labels
    // by default, Chart.js applies locale
    if ((chartType === "line" || chartType === "area") && chart.xtype === "number") {
      if (!options.scales.x.ticks.callback) {
        options.scales.x.ticks.callback = function (value) {
          return toStr(value);
        };
      }

      if (!options.plugins.tooltip.callbacks.title) {
        options.plugins.tooltip.callbacks.title = function (context) {
          return toStr(context[0].parsed.x);
        };
      }
    }
  }

  function maxAbsY(series) {
    var max = 0;
    for (var i = 0; i < series.length; i++) {
      var data = series[i].data;
      for (var j = 0; j < data.length; j++) {
        var v = Math.abs(data[j][1]);
        if (v > max) {
          max = v;
        }
      }
    }
    return max;
  }

  function maxR(series) {
    // start at zero since radius must be positive
    var max = 0;
    for (var i = 0; i < series.length; i++) {
      var data = series[i].data;
      for (var j = 0; j < data.length; j++) {
        var v = data[j][2];
        if (v > max) {
          max = v;
        }
      }
    }
    return max;
  }

  var jsOptions$2 = jsOptionsFunc(merge(baseOptions, defaultOptions$2), hideLegend$2, setTitle$2, setMin$2, setMax$2, setStacked$2, setXtitle$2, setYtitle$2);

  function prepareDefaultData(chart) {
    var series = chart.data;
    var rows = {};
    var keys = [];
    var labels = [];
    var values = [];

    for (var i = 0; i < series.length; i++) {
      var data = series[i].data;

      for (var j = 0; j < data.length; j++) {
        var d = data[j];
        var key = chart.xtype === "datetime" ? d[0].getTime() : d[0];
        if (!rows[key]) {
          rows[key] = new Array(series.length);
          keys.push(key);
        }
        rows[key][i] = d[1];
      }
    }

    if (chart.xtype === "datetime" || chart.xtype === "number") {
      keys.sort(sortByNumber);
    }

    for (var i$1 = 0; i$1 < series.length; i$1++) {
      values.push([]);
    }

    for (var i$2 = 0; i$2 < keys.length; i$2++) {
      var key$1 = keys[i$2];

      var label = chart.xtype === "datetime" ? new Date(key$1) : key$1;
      labels.push(label);

      var row = rows[key$1];
      for (var j$1 = 0; j$1 < series.length; j$1++) {
        var v = row[j$1];
        // Chart.js doesn't like undefined
        values[j$1].push(v === undefined ? null : v);
      }
    }

    return {
      labels: labels,
      values: values
    };
  }

  function prepareBubbleData(chart) {
    var series = chart.data;
    var values = [];
    var max = maxR(series);

    for (var i = 0; i < series.length; i++) {
      var data = series[i].data;
      var points = [];
      for (var j = 0; j < data.length; j++) {
        var v = data[j];
        points.push({
          x: v[0],
          y: v[1],
          r: v[2] * 20 / max,
          // custom attribute, for tooltip
          v: v[2]
        });
      }
      values.push(points);
    }

    return {
      labels: [],
      values: values
    };
  }

  // scatter or numeric line/area
  function prepareNumberData(chart) {
    var series = chart.data;
    var values = [];

    for (var i = 0; i < series.length; i++) {
      var data = series[i].data;

      data.sort(sortByNumberSeries);

      var points = [];
      for (var j = 0; j < data.length; j++) {
        var v = data[j];
        points.push({
          x: v[0],
          y: v[1]
        });
      }
      values.push(points);
    }

    return {
      labels: [],
      values: values
    };
  }

  function prepareData(chart, chartType) {
    if (chartType === "bubble") {
      return prepareBubbleData(chart);
    } else if (chart.xtype === "number" && chartType !== "bar" && chartType !== "column") {
      return prepareNumberData(chart);
    } else {
      return prepareDefaultData(chart);
    }
  }

  function createDataTable(chart, options, chartType) {
    var ref = prepareData(chart, chartType);
    var labels = ref.labels;
    var values = ref.values;

    var series = chart.data;
    var datasets = [];
    var colors = chart.options.colors || defaultColors;
    for (var i = 0; i < series.length; i++) {
      var s = series[i];

      // use colors for each bar for single series format
      var color = (void 0);
      var backgroundColor = (void 0);
      if (chart.options.colors && chart.singleSeriesFormat && (chartType === "bar" || chartType === "column") && !s.color && isArray(chart.options.colors) && !isArray(chart.options.colors[0])) {
        color = colors;
        backgroundColor = [];
        for (var j = 0; j < colors.length; j++) {
          backgroundColor[j] = addOpacity(color[j], 0.5);
        }
      } else {
        color = s.color || colors[i];
        backgroundColor = chartType !== "line" ? addOpacity(color, 0.5) : color;
      }

      var dataset = {
        label: s.name || "",
        data: values[i],
        fill: chartType === "area",
        borderColor: color,
        backgroundColor: backgroundColor,
        borderWidth: 2
      };

      var pointChart = chartType === "line" || chartType === "area" || chartType === "scatter" || chartType === "bubble";
      if (pointChart) {
        dataset.pointBackgroundColor = color;
        dataset.pointHoverBackgroundColor = color;
        dataset.pointHitRadius = 50;
      }

      if (chartType === "bubble") {
        dataset.pointBackgroundColor = backgroundColor;
        dataset.pointHoverBackgroundColor = backgroundColor;
        dataset.pointHoverBorderWidth = 2;
      }

      if (s.stack) {
        dataset.stack = s.stack;
      }

      var curve = seriesOption(chart, s, "curve");
      if (curve === false) {
        dataset.tension = 0;
      } else if (pointChart) {
        dataset.tension = 0.4;
      }

      var points = seriesOption(chart, s, "points");
      if (points === false) {
        dataset.pointRadius = 0;
        dataset.pointHoverRadius = 0;
      }

      dataset = merge(dataset, chart.options.dataset || {});
      dataset = merge(dataset, s.library || {});
      dataset = merge(dataset, s.dataset || {});

      datasets.push(dataset);
    }

    var xmin = chart.options.xmin;
    var xmax = chart.options.xmax;

    if (chart.xtype === "datetime") {
      if (notnull(xmin)) {
        options.scales.x.min = toDate(xmin).getTime();
      }
      if (notnull(xmax)) {
        options.scales.x.max = toDate(xmax).getTime();
      }
    } else if (chart.xtype === "number") {
      if (notnull(xmin)) {
        options.scales.x.min = xmin;
      }
      if (notnull(xmax)) {
        options.scales.x.max = xmax;
      }
    }

    if (chart.xtype === "datetime") {
      var timeUnit = calculateTimeUnit(labels);

      // for empty datetime chart
      if (labels.length === 0) {
        if (notnull(xmin)) {
          labels.push(toDate(xmin));
        }
        if (notnull(xmax)) {
          labels.push(toDate(xmax));
        }
      }

      if (labels.length > 0) {
        var minTime = (notnull(xmin) ? toDate(xmin) : labels[0]).getTime();
        var maxTime = (notnull(xmax) ? toDate(xmax) : labels[0]).getTime();

        for (var i$1 = 1; i$1 < labels.length; i$1++) {
          var value = labels[i$1].getTime();
          if (value < minTime) {
            minTime = value;
          }
          if (value > maxTime) {
            maxTime = value;
          }
        }

        var timeDiff = (maxTime - minTime) / (86400 * 1000.0);

        if (!options.scales.x.time.unit) {
          var step;
          if (timeUnit === "year" || timeDiff > 365 * 10) {
            options.scales.x.time.unit = "year";
            step = 365;
          } else if (timeUnit === "month" || timeDiff > 30 * 10) {
            options.scales.x.time.unit = "month";
            step = 30;
          } else if (timeUnit === "week" || timeUnit === "day" || timeDiff > 10) {
            options.scales.x.time.unit = "day";
            step = 1;
          } else if (timeUnit === "hour" || timeDiff > 0.5) {
            options.scales.x.time.displayFormats = {hour: "MMM d, h a"};
            options.scales.x.time.unit = "hour";
            step = 1 / 24.0;
          } else if (timeUnit === "minute") {
            options.scales.x.time.displayFormats = {minute: "h:mm a"};
            options.scales.x.time.unit = "minute";
            step = 1 / 24.0 / 60.0;
          }

          if (step && timeDiff > 0) {
            // width not available for hidden elements
            var width = chart.element.offsetWidth;
            if (width > 0) {
              var unitStepSize = Math.ceil(timeDiff / step / (width / 100.0));
              if (timeUnit === "week" && step === 1) {
                unitStepSize = Math.ceil(unitStepSize / 7.0) * 7;
              }
              options.scales.x.ticks.stepSize = unitStepSize;
            }
          }
        }

        if (!options.scales.x.time.tooltipFormat) {
          if (timeUnit === "year") {
            options.scales.x.time.tooltipFormat = "yyyy";
          } else if (timeUnit === "month") {
            options.scales.x.time.tooltipFormat = "MMM yyyy";
          } else if (timeUnit === "week" || timeUnit === "day") {
            options.scales.x.time.tooltipFormat = "PP";
          } else if (timeUnit === "hour") {
            options.scales.x.time.tooltipFormat = "MMM d, h a";
          } else if (timeUnit === "minute") {
            options.scales.x.time.tooltipFormat = "h:mm a";
          }
        }
      }
    }

    return {
      labels: labels,
      datasets: datasets
    };
  }

  var defaultExport$2 = function defaultExport(library) {
    this.name = "chartjs";
    this.library = library;
  };

  defaultExport$2.prototype.renderLineChart = function renderLineChart (chart, chartType) {
    if (!chartType) {
      chartType = "line";
    }

    var chartOptions = {};

    var options = jsOptions$2(chart, merge(chartOptions, chart.options));
    setFormatOptions$1(chart, options, chartType);

    var data = createDataTable(chart, options, chartType);

    if (chart.xtype === "number") {
      options.scales.x.type = options.scales.x.type || "linear";
      options.scales.x.position = options.scales.x.position || "bottom";
    } else {
      options.scales.x.type = chart.xtype === "string" ? "category" : "time";
    }

    this.drawChart(chart, "line", data, options);
  };

  defaultExport$2.prototype.renderPieChart = function renderPieChart (chart) {
    var options = merge({}, baseOptions);
    if (chart.options.donut) {
      options.cutout = "50%";
    }

    if ("legend" in chart.options) {
      hideLegend$2(options, chart.options.legend);
    }

    if (chart.options.title) {
      setTitle$2(options, chart.options.title);
    }

    options = merge(options, chart.options.library || {});
    setFormatOptions$1(chart, options, "pie");

    var labels = [];
    var values = [];
    for (var i = 0; i < chart.data.length; i++) {
      var point = chart.data[i];
      labels.push(point[0]);
      values.push(point[1]);
    }

    var dataset = {
      data: values,
      backgroundColor: chart.options.colors || defaultColors
    };
    dataset = merge(dataset, chart.options.dataset || {});

    var data = {
      labels: labels,
      datasets: [dataset]
    };

    this.drawChart(chart, "pie", data, options);
  };

  defaultExport$2.prototype.renderColumnChart = function renderColumnChart (chart, chartType) {
    var options;
    if (chartType === "bar") {
      var barOptions = merge(baseOptions, defaultOptions$2);
      barOptions.indexAxis = "y";

      // ensure gridlines have proper orientation
      barOptions.scales.x.grid.drawOnChartArea = true;
      barOptions.scales.y.grid.drawOnChartArea = false;
      delete barOptions.scales.y.ticks.maxTicksLimit;

      options = jsOptionsFunc(barOptions, hideLegend$2, setTitle$2, setBarMin$1, setBarMax$1, setStacked$2, setXtitle$2, setYtitle$2)(chart, chart.options);
    } else {
      options = jsOptions$2(chart, chart.options);
    }
    setFormatOptions$1(chart, options, chartType);
    var data = createDataTable(chart, options, "column");
    if (chartType !== "bar") {
      setLabelSize(chart, data, options);
    }
    if (!("mode" in options.interaction)) {
      options.interaction.mode = "index";
    }
    this.drawChart(chart, "bar", data, options);
  };

  defaultExport$2.prototype.renderAreaChart = function renderAreaChart (chart) {
    this.renderLineChart(chart, "area");
  };

  defaultExport$2.prototype.renderBarChart = function renderBarChart (chart) {
    this.renderColumnChart(chart, "bar");
  };

  defaultExport$2.prototype.renderScatterChart = function renderScatterChart (chart, chartType) {
    chartType = chartType || "scatter";

    var options = jsOptions$2(chart, chart.options);
    setFormatOptions$1(chart, options, chartType);

    if (!("showLine" in options)) {
      options.showLine = false;
    }

    var data = createDataTable(chart, options, chartType);

    options.scales.x.type = options.scales.x.type || "linear";
    options.scales.x.position = options.scales.x.position || "bottom";

    // prevent grouping hover and tooltips
    if (!("mode" in options.interaction)) {
      options.interaction.mode = "nearest";
    }

    this.drawChart(chart, chartType, data, options);
  };

  defaultExport$2.prototype.renderBubbleChart = function renderBubbleChart (chart) {
    this.renderScatterChart(chart, "bubble");
  };

  defaultExport$2.prototype.destroy = function destroy (chart) {
    if (chart.chart) {
      chart.chart.destroy();
    }
  };

  defaultExport$2.prototype.drawChart = function drawChart (chart, type, data, options) {
    this.destroy(chart);
    if (chart.destroyed) { return; }

    var chartOptions = {
      type: type,
      data: data,
      options: options
    };

    if (chart.options.code) {
      window.console.log("new Chart(ctx, " + JSON.stringify(chartOptions) + ");");
    }

    chart.element.innerHTML = "<canvas></canvas>";
    var ctx = chart.element.getElementsByTagName("CANVAS")[0];
    chart.chart = new this.library(ctx, chartOptions);
  };

  var defaultOptions$1 = {
    chart: {},
    xAxis: {
      title: {
        text: null
      },
      labels: {
        style: {
          fontSize: "12px"
        }
      }
    },
    yAxis: {
      title: {
        text: null
      },
      labels: {
        style: {
          fontSize: "12px"
        }
      }
    },
    title: {
      text: null
    },
    credits: {
      enabled: false
    },
    legend: {
      borderWidth: 0
    },
    tooltip: {
      style: {
        fontSize: "12px"
      }
    },
    plotOptions: {
      areaspline: {},
      area: {},
      series: {
        marker: {}
      }
    },
    time: {
      useUTC: false
    }
  };

  function hideLegend$1(options, legend, hideLegend) {
    if (legend !== undefined) {
      options.legend.enabled = !!legend;
      if (legend && legend !== true) {
        if (legend === "top" || legend === "bottom") {
          options.legend.verticalAlign = legend;
        } else {
          options.legend.layout = "vertical";
          options.legend.verticalAlign = "middle";
          options.legend.align = legend;
        }
      }
    } else if (hideLegend) {
      options.legend.enabled = false;
    }
  }

  function setTitle$1(options, title) {
    options.title.text = title;
  }

  function setMin$1(options, min) {
    options.yAxis.min = min;
  }

  function setMax$1(options, max) {
    options.yAxis.max = max;
  }

  function setStacked$1(options, stacked) {
    var stackedValue = stacked ? (stacked === true ? "normal" : stacked) : null;
    options.plotOptions.series.stacking = stackedValue;
    options.plotOptions.area.stacking = stackedValue;
    options.plotOptions.areaspline.stacking = stackedValue;
  }

  function setXtitle$1(options, title) {
    options.xAxis.title.text = title;
  }

  function setYtitle$1(options, title) {
    options.yAxis.title.text = title;
  }

  var jsOptions$1 = jsOptionsFunc(defaultOptions$1, hideLegend$1, setTitle$1, setMin$1, setMax$1, setStacked$1, setXtitle$1, setYtitle$1);

  function setFormatOptions(chart, options, chartType) {
    var formatOptions = {
      prefix: chart.options.prefix,
      suffix: chart.options.suffix,
      thousands: chart.options.thousands,
      decimal: chart.options.decimal,
      precision: chart.options.precision,
      round: chart.options.round,
      zeros: chart.options.zeros
    };

    // skip when axis is an array (like with min/max)
    if (chartType !== "pie" && !isArray(options.yAxis) && !options.yAxis.labels.formatter) {
      options.yAxis.labels.formatter = function () {
        return formatValue("", this.value, formatOptions);
      };
    }

    if (!options.tooltip.pointFormatter && !options.tooltip.pointFormat) {
      options.tooltip.pointFormatter = function () {
        return '<span style="color:' + this.color + '">\u25CF</span> ' + formatValue(this.series.name + ': <b>', this.y, formatOptions) + '</b><br/>';
      };
    }
  }

  var defaultExport$1 = function defaultExport(library) {
    this.name = "highcharts";
    this.library = library;
  };

  defaultExport$1.prototype.renderLineChart = function renderLineChart (chart, chartType) {
    chartType = chartType || "spline";
    var chartOptions = {};
    if (chartType === "areaspline") {
      chartOptions = {
        plotOptions: {
          areaspline: {
            stacking: "normal"
          },
          area: {
            stacking: "normal"
          },
          series: {
            marker: {
              enabled: false
            }
          }
        }
      };
    }

    if (chart.options.curve === false) {
      if (chartType === "areaspline") {
        chartType = "area";
      } else if (chartType === "spline") {
        chartType = "line";
      }
    }

    var options = jsOptions$1(chart, chart.options, chartOptions);
    if (chart.xtype === "number") {
      options.xAxis.type = options.xAxis.type || "linear";
    } else {
      options.xAxis.type = chart.xtype === "string" ? "category" : "datetime";
    }
    if (!options.chart.type) {
      options.chart.type = chartType;
    }
    setFormatOptions(chart, options, chartType);

    var series = chart.data;
    for (var i = 0; i < series.length; i++) {
      series[i].name = series[i].name || "Value";
      var data = series[i].data;
      if (chart.xtype === "datetime") {
        for (var j = 0; j < data.length; j++) {
          data[j][0] = data[j][0].getTime();
        }
      } else if (chart.xtype === "number") {
        data.sort(sortByNumberSeries);
      }
      series[i].marker = {symbol: "circle"};
      if (chart.options.points === false) {
        series[i].marker.enabled = false;
      }
    }

    this.drawChart(chart, series, options);
  };

  defaultExport$1.prototype.renderScatterChart = function renderScatterChart (chart) {
    var options = jsOptions$1(chart, chart.options, {});
    options.chart.type = "scatter";
    this.drawChart(chart, chart.data, options);
  };

  defaultExport$1.prototype.renderPieChart = function renderPieChart (chart) {
    var chartOptions = merge(defaultOptions$1, {});

    if (chart.options.colors) {
      chartOptions.colors = chart.options.colors;
    }
    if (chart.options.donut) {
      chartOptions.plotOptions = {pie: {innerSize: "50%"}};
    }

    if ("legend" in chart.options) {
      hideLegend$1(chartOptions, chart.options.legend);
    }

    if (chart.options.title) {
      setTitle$1(chartOptions, chart.options.title);
    }

    var options = merge(chartOptions, chart.options.library || {});
    setFormatOptions(chart, options, "pie");
    var series = [{
      type: "pie",
      name: chart.options.label || "Value",
      data: chart.data
    }];

    this.drawChart(chart, series, options);
  };

  defaultExport$1.prototype.renderColumnChart = function renderColumnChart (chart, chartType) {
    chartType = chartType || "column";
    var series = chart.data;
    var options = jsOptions$1(chart, chart.options);
    var rows = [];
    var categories = [];
    options.chart.type = chartType;
    setFormatOptions(chart, options, chartType);

    for (var i = 0; i < series.length; i++) {
      var s = series[i];

      for (var j = 0; j < s.data.length; j++) {
        var d = s.data[j];
        if (!rows[d[0]]) {
          rows[d[0]] = new Array(series.length);
          categories.push(d[0]);
        }
        rows[d[0]][i] = d[1];
      }
    }

    if (chart.xtype === "number") {
      categories.sort(sortByNumber);
    }

    options.xAxis.categories = categories;

    var newSeries = [];
    for (var i$1 = 0; i$1 < series.length; i$1++) {
      var d$1 = [];
      for (var j$1 = 0; j$1 < categories.length; j$1++) {
        d$1.push(rows[categories[j$1]][i$1] || 0);
      }

      var d2 = {
        name: series[i$1].name || "Value",
        data: d$1
      };
      if (series[i$1].stack) {
        d2.stack = series[i$1].stack;
      }

      newSeries.push(d2);
    }

    this.drawChart(chart, newSeries, options);
  };

  defaultExport$1.prototype.renderBarChart = function renderBarChart (chart) {
    this.renderColumnChart(chart, "bar");
  };

  defaultExport$1.prototype.renderAreaChart = function renderAreaChart (chart) {
    this.renderLineChart(chart, "areaspline");
  };

  defaultExport$1.prototype.destroy = function destroy (chart) {
    if (chart.chart) {
      chart.chart.destroy();
    }
  };

  defaultExport$1.prototype.drawChart = function drawChart (chart, data, options) {
    this.destroy(chart);
    if (chart.destroyed) { return; }

    options.chart.renderTo = chart.element.id;
    options.series = data;

    if (chart.options.code) {
      window.console.log("new Highcharts.Chart(" + JSON.stringify(options) + ");");
    }

    chart.chart = new this.library.Chart(options);
  };

  var loaded = {};
  var callbacks = [];

  // Set chart options
  var defaultOptions = {
    chartArea: {},
    fontName: "'Lucida Grande', 'Lucida Sans Unicode', Verdana, Arial, Helvetica, sans-serif",
    pointSize: 6,
    legend: {
      textStyle: {
        fontSize: 12,
        color: "#444"
      },
      alignment: "center",
      position: "right"
    },
    curveType: "function",
    hAxis: {
      textStyle: {
        color: "#666",
        fontSize: 12
      },
      titleTextStyle: {},
      gridlines: {
        color: "transparent"
      },
      baselineColor: "#ccc",
      viewWindow: {}
    },
    vAxis: {
      textStyle: {
        color: "#666",
        fontSize: 12
      },
      titleTextStyle: {},
      baselineColor: "#ccc",
      viewWindow: {}
    },
    tooltip: {
      textStyle: {
        color: "#666",
        fontSize: 12
      }
    }
  };

  function hideLegend(options, legend, hideLegend) {
    if (legend !== undefined) {
      var position;
      if (!legend) {
        position = "none";
      } else if (legend === true) {
        position = "right";
      } else {
        position = legend;
      }
      options.legend.position = position;
    } else if (hideLegend) {
      options.legend.position = "none";
    }
  }

  function setTitle(options, title) {
    options.title = title;
    options.titleTextStyle = {color: "#333", fontSize: "20px"};
  }

  function setMin(options, min) {
    options.vAxis.viewWindow.min = min;
  }

  function setMax(options, max) {
    options.vAxis.viewWindow.max = max;
  }

  function setBarMin(options, min) {
    options.hAxis.viewWindow.min = min;
  }

  function setBarMax(options, max) {
    options.hAxis.viewWindow.max = max;
  }

  function setStacked(options, stacked) {
    options.isStacked = stacked || false;
  }

  function setXtitle(options, title) {
    options.hAxis.title = title;
    options.hAxis.titleTextStyle.italic = false;
  }

  function setYtitle(options, title) {
    options.vAxis.title = title;
    options.vAxis.titleTextStyle.italic = false;
  }

  var jsOptions = jsOptionsFunc(defaultOptions, hideLegend, setTitle, setMin, setMax, setStacked, setXtitle, setYtitle);

  function resize(callback) {
    if (window.attachEvent) {
      window.attachEvent("onresize", callback);
    } else if (window.addEventListener) {
      window.addEventListener("resize", callback, true);
    }
    callback();
  }

  var defaultExport = function defaultExport(library) {
    this.name = "google";
    this.library = library;
  };

  defaultExport.prototype.renderLineChart = function renderLineChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, function () {
      var chartOptions = {};

      if (chart.options.curve === false) {
        chartOptions.curveType = "none";
      }

      if (chart.options.points === false) {
        chartOptions.pointSize = 0;
      }

      var options = jsOptions(chart, chart.options, chartOptions);
      var data = this$1$1.createDataTable(chart.data, chart.xtype);

      this$1$1.drawChart(chart, "LineChart", data, options);
    });
  };

  defaultExport.prototype.renderPieChart = function renderPieChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, function () {
      var chartOptions = {
        chartArea: {
          top: "10%",
          height: "80%"
        },
        legend: {}
      };
      if (chart.options.colors) {
        chartOptions.colors = chart.options.colors;
      }
      if (chart.options.donut) {
        chartOptions.pieHole = 0.5;
      }
      if ("legend" in chart.options) {
        hideLegend(chartOptions, chart.options.legend);
      }
      if (chart.options.title) {
        setTitle(chartOptions, chart.options.title);
      }
      var options = merge(merge(defaultOptions, chartOptions), chart.options.library || {});

      var data = new this$1$1.library.visualization.DataTable();
      data.addColumn("string", "");
      data.addColumn("number", "Value");
      data.addRows(chart.data);

      this$1$1.drawChart(chart, "PieChart", data, options);
    });
  };

  defaultExport.prototype.renderColumnChart = function renderColumnChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, function () {
      var options = jsOptions(chart, chart.options);
      var data = this$1$1.createDataTable(chart.data, chart.xtype);

      this$1$1.drawChart(chart, "ColumnChart", data, options);
    });
  };

  defaultExport.prototype.renderBarChart = function renderBarChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, function () {
      var chartOptions = {
        hAxis: {
          gridlines: {
            color: "#ccc"
          }
        }
      };
      var options = jsOptionsFunc(defaultOptions, hideLegend, setTitle, setBarMin, setBarMax, setStacked, setXtitle, setYtitle)(chart, chart.options, chartOptions);
      var data = this$1$1.createDataTable(chart.data, chart.xtype);

      this$1$1.drawChart(chart, "BarChart", data, options);
    });
  };

  defaultExport.prototype.renderAreaChart = function renderAreaChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, function () {
      var chartOptions = {
        isStacked: true,
        pointSize: 0,
        areaOpacity: 0.5
      };

      var options = jsOptions(chart, chart.options, chartOptions);
      var data = this$1$1.createDataTable(chart.data, chart.xtype);

      this$1$1.drawChart(chart, "AreaChart", data, options);
    });
  };

  defaultExport.prototype.renderGeoChart = function renderGeoChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, "geochart", function () {
      var chartOptions = {
        legend: "none",
        colorAxis: {
          colors: chart.options.colors || ["#f6c7b6", "#ce502d"]
        }
      };
      var options = merge(merge(defaultOptions, chartOptions), chart.options.library || {});

      var data = new this$1$1.library.visualization.DataTable();
      data.addColumn("string", "");
      data.addColumn("number", chart.options.label || "Value");
      data.addRows(chart.data);

      this$1$1.drawChart(chart, "GeoChart", data, options);
    });
  };

  defaultExport.prototype.renderScatterChart = function renderScatterChart (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, function () {
      var chartOptions = {};
      var options = jsOptions(chart, chart.options, chartOptions);

      var series = chart.data;
      var rows2 = [];
      for (var i = 0; i < series.length; i++) {
        series[i].name = series[i].name || "Value";
        var d = series[i].data;
        for (var j = 0; j < d.length; j++) {
          var row = new Array(series.length + 1);
          row[0] = d[j][0];
          row[i + 1] = d[j][1];
          rows2.push(row);
        }
      }

      var data = new this$1$1.library.visualization.DataTable();
      data.addColumn("number", "");
      for (var i$1 = 0; i$1 < series.length; i$1++) {
        data.addColumn("number", series[i$1].name);
      }
      data.addRows(rows2);

      this$1$1.drawChart(chart, "ScatterChart", data, options);
    });
  };

  defaultExport.prototype.renderTimeline = function renderTimeline (chart) {
      var this$1$1 = this;

    this.waitForLoaded(chart, "timeline", function () {
      var chartOptions = {
        legend: "none"
      };

      if (chart.options.colors) {
        chartOptions.colors = chart.options.colors;
      }
      var options = merge(merge(defaultOptions, chartOptions), chart.options.library || {});

      var data = new this$1$1.library.visualization.DataTable();
      data.addColumn({type: "string", id: "Name"});
      data.addColumn({type: "date", id: "Start"});
      data.addColumn({type: "date", id: "End"});
      data.addRows(chart.data);

      chart.element.style.lineHeight = "normal";

      this$1$1.drawChart(chart, "Timeline", data, options);
    });
  };

  // TODO remove resize events
  defaultExport.prototype.destroy = function destroy (chart) {
    if (chart.chart) {
      chart.chart.clearChart();
    }
  };

  defaultExport.prototype.drawChart = function drawChart (chart, type, data, options) {
    this.destroy(chart);
    if (chart.destroyed) { return; }

    if (chart.options.code) {
      window.console.log("var data = new google.visualization.DataTable(" + data.toJSON() + ");\nvar chart = new google.visualization." + type + "(element);\nchart.draw(data, " + JSON.stringify(options) + ");");
    }

    chart.chart = new this.library.visualization[type](chart.element);
    resize(function () {
      chart.chart.draw(data, options);
    });
  };

  defaultExport.prototype.waitForLoaded = function waitForLoaded (chart, pack, callback) {
      var this$1$1 = this;

    if (!callback) {
      callback = pack;
      pack = "corechart";
    }

    callbacks.push({pack: pack, callback: callback});

    if (loaded[pack]) {
      this.runCallbacks();
    } else {
      loaded[pack] = true;

      // https://groups.google.com/forum/#!topic/google-visualization-api/fMKJcyA2yyI
      var loadOptions = {
        packages: [pack],
        callback: function () { this$1$1.runCallbacks(); }
      };
      var config = chart.__config();
      if (config.language) {
        loadOptions.language = config.language;
      }
      if (pack === "geochart" && config.mapsApiKey) {
        loadOptions.mapsApiKey = config.mapsApiKey;
      }

      this.library.charts.load("current", loadOptions);
    }
  };

  defaultExport.prototype.runCallbacks = function runCallbacks () {
    for (var i = 0; i < callbacks.length; i++) {
      var cb = callbacks[i];
      var call = this.library.visualization && ((cb.pack === "corechart" && this.library.visualization.LineChart) || (cb.pack === "timeline" && this.library.visualization.Timeline) || (cb.pack === "geochart" && this.library.visualization.GeoChart));
      if (call) {
        cb.callback();
        callbacks.splice(i, 1);
        i--;
      }
    }
  };

  // cant use object as key
  defaultExport.prototype.createDataTable = function createDataTable (series, columnType) {
    var rows = [];
    var sortedLabels = [];
    for (var i = 0; i < series.length; i++) {
      var s = series[i];
      series[i].name = series[i].name || "Value";

      for (var j = 0; j < s.data.length; j++) {
        var d = s.data[j];
        var key = columnType === "datetime" ? d[0].getTime() : d[0];
        if (!rows[key]) {
          rows[key] = new Array(series.length);
          sortedLabels.push(key);
        }
        rows[key][i] = d[1];
      }
    }

    var rows2 = [];
    var values = [];
    for (var j$1 = 0; j$1 < sortedLabels.length; j$1++) {
      var i$1 = sortedLabels[j$1];
      var value = (void 0);
      if (columnType === "datetime") {
        value = new Date(i$1);
        values.push(value);
      } else {
        value = i$1;
      }
      rows2.push([value].concat(rows[i$1]));
    }

    var day = true;
    if (columnType === "datetime") {
      rows2.sort(sortByTime);

      var timeUnit = calculateTimeUnit(values, true);
      day = isDay(timeUnit);
    } else if (columnType === "number") {
      rows2.sort(sortByNumberSeries);

      for (var i$2 = 0; i$2 < rows2.length; i$2++) {
        rows2[i$2][0] = toStr(rows2[i$2][0]);
      }

      columnType = "string";
    }

    // create datatable
    var data = new this.library.visualization.DataTable();
    columnType = columnType === "datetime" && day ? "date" : columnType;
    data.addColumn(columnType, "");
    for (var i$3 = 0; i$3 < series.length; i$3++) {
      data.addColumn("number", series[i$3].name);
    }
    data.addRows(rows2);

    return data;
  };

  var adapters = [];

  function getAdapterType(library) {
    if (library) {
      if (library.product === "Highcharts") {
        return defaultExport$1;
      } else if (library.charts) {
        return defaultExport;
      } else if (isFunction(library)) {
        return defaultExport$2;
      }
    }
    throw new Error("Unknown adapter");
  }

  function addAdapter(library) {
    var adapterType = getAdapterType(library);

    for (var i = 0; i < adapters.length; i++) {
      if (adapters[i].library === library) {
        return;
      }
    }

    adapters.push(new adapterType(library));
  }

  function loadAdapters() {
    if ("Chart" in window) {
      addAdapter(window.Chart);
    }

    if ("Highcharts" in window) {
      addAdapter(window.Highcharts);
    }

    if (window.google && window.google.charts) {
      addAdapter(window.google);
    }
  }

  // TODO remove chartType if cross-browser way
  // to get the name of the chart class
  function callAdapter(chartType, chart) {
    var fnName = "render" + chartType;
    var adapterName = chart.options.adapter;

    loadAdapters();

    for (var i = 0; i < adapters.length; i++) {
      var adapter = adapters[i];
      if ((!adapterName || adapterName === adapter.name) && isFunction(adapter[fnName])) {
        chart.adapter = adapter.name;
        chart.__adapterObject = adapter;
        return adapter[fnName](chart);
      }
    }

    if (adapters.length > 0) {
      throw new Error("No charting library found for " + chartType);
    } else {
      throw new Error("No charting libraries found - be sure to include one before your charts");
    }
  }

  var Chartkick = {
    charts: {},
    configure: function (options) {
      for (var key in options) {
        if (Object.prototype.hasOwnProperty.call(options, key)) {
          Chartkick.config[key] = options[key];
        }
      }
    },
    setDefaultOptions: function (opts) {
      Chartkick.options = opts;
    },
    eachChart: function (callback) {
      for (var chartId in Chartkick.charts) {
        if (Object.prototype.hasOwnProperty.call(Chartkick.charts, chartId)) {
          callback(Chartkick.charts[chartId]);
        }
      }
    },
    destroyAll: function () {
      for (var chartId in Chartkick.charts) {
        if (Object.prototype.hasOwnProperty.call(Chartkick.charts, chartId)) {
          Chartkick.charts[chartId].destroy();
          delete Chartkick.charts[chartId];
        }
      }
    },
    config: {},
    options: {},
    adapters: adapters,
    addAdapter: addAdapter,
    use: function (adapter) {
      addAdapter(adapter);
      return Chartkick;
    }
  };

  function formatSeriesBubble(data) {
    var r = [];
    for (var i = 0; i < data.length; i++) {
      r.push([toFloat(data[i][0]), toFloat(data[i][1]), toFloat(data[i][2])]);
    }
    return r;
  }

  // casts data to proper type
  // sorting is left to adapters
  function formatSeriesData(data, keyType) {
    if (keyType === "bubble") {
      return formatSeriesBubble(data);
    }

    var keyFunc;
    if (keyType === "number") {
      keyFunc = toFloat;
    } else if (keyType === "datetime") {
      keyFunc = toDate;
    } else {
      keyFunc = toStr;
    }

    var r = [];
    for (var i = 0; i < data.length; i++) {
      r.push([keyFunc(data[i][0]), toFloat(data[i][1])]);
    }
    return r;
  }

  function detectXType(series, noDatetime, options) {
    if (dataEmpty(series)) {
      if ((options.xmin || options.xmax) && (!options.xmin || isDate(options.xmin)) && (!options.xmax || isDate(options.xmax))) {
        return "datetime";
      } else {
        return "number";
      }
    } else if (detectXTypeWithFunction(series, isNumber)) {
      return "number";
    } else if (!noDatetime && detectXTypeWithFunction(series, isDate)) {
      return "datetime";
    } else {
      return "string";
    }
  }

  function detectXTypeWithFunction(series, func) {
    for (var i = 0; i < series.length; i++) {
      var data = toArr(series[i].data);
      for (var j = 0; j < data.length; j++) {
        if (!func(data[j][0])) {
          return false;
        }
      }
    }
    return true;
  }

  // creates a shallow copy of each element of the array
  // elements are expected to be objects
  function copySeries(series) {
    var newSeries = [];
    for (var i = 0; i < series.length; i++) {
      var copy = {};
      for (var j in series[i]) {
        if (Object.prototype.hasOwnProperty.call(series[i], j)) {
          copy[j] = series[i][j];
        }
      }
      newSeries.push(copy);
    }
    return newSeries;
  }

  function processSeries(chart, keyType, noDatetime) {
    var opts = chart.options;
    var series = chart.rawData;

    // see if one series or multiple
    chart.singleSeriesFormat = !isArray(series) || !isPlainObject(series[0]);
    if (chart.singleSeriesFormat) {
      series = [{name: opts.label, data: series}];
    }

    // convert to array
    // must come before dataEmpty check
    series = copySeries(series);
    for (var i = 0; i < series.length; i++) {
      series[i].data = toArr(series[i].data);
    }

    chart.xtype = keyType || (opts.discrete ? "string" : detectXType(series, noDatetime, opts));

    // right format
    for (var i$1 = 0; i$1 < series.length; i$1++) {
      series[i$1].data = formatSeriesData(series[i$1].data, chart.xtype);
    }

    return series;
  }

  function processSimple(chart) {
    var perfectData = toArr(chart.rawData);
    for (var i = 0; i < perfectData.length; i++) {
      perfectData[i] = [toStr(perfectData[i][0]), toFloat(perfectData[i][1])];
    }
    return perfectData;
  }

  function dataEmpty(data, chartType) {
    if (chartType === "PieChart" || chartType === "GeoChart" || chartType === "Timeline") {
      return data.length === 0;
    } else {
      for (var i = 0; i < data.length; i++) {
        if (data[i].data.length > 0) {
          return false;
        }
      }
      return true;
    }
  }

  function addDownloadButton(chart) {
    var download = chart.options.download;
    if (download === true) {
      download = {};
    } else if (typeof download === "string") {
      download = {filename: download};
    }

    var link = document.createElement("a");
    link.download = download.filename || "chart.png";
    link.style.position = "absolute";
    link.style.top = "20px";
    link.style.right = "20px";
    link.style.zIndex = 1000;
    link.style.lineHeight = "20px";
    link.target = "_blank"; // for safari

    var image = document.createElement("img");
    // icon from Font Awesome, modified to set fill color
    var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 512\"><!--! Font Awesome Free 6.2.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2022 Fonticons, Inc. --><path fill=\"#CCCCCC\" d=\"M344 240h-56L287.1 152c0-13.25-10.75-24-24-24h-16C234.7 128 223.1 138.8 223.1 152L224 240h-56c-9.531 0-18.16 5.656-22 14.38C142.2 263.1 143.9 273.3 150.4 280.3l88.75 96C243.7 381.2 250.1 384 256.8 384c7.781-.3125 13.25-2.875 17.75-7.844l87.25-96c6.406-7.031 8.031-17.19 4.188-25.88S353.5 240 344 240zM256 0C114.6 0 0 114.6 0 256s114.6 256 256 256s256-114.6 256-256S397.4 0 256 0zM256 464c-114.7 0-208-93.31-208-208S141.3 48 256 48s208 93.31 208 208S370.7 464 256 464z\"/></svg>";
    image.src = "data:image/svg+xml;utf8," + (encodeURIComponent(svg));
    image.alt = "Download";
    image.style.width = "20px";
    image.style.height = "20px";
    image.style.border = "none";
    link.appendChild(image);

    var element = chart.element;
    element.style.position = "relative";

    chart.__downloadAttached = true;

    // mouseenter
    chart.__enterEvent = element.addEventListener("mouseover", function (e) {
      var related = e.relatedTarget;
      // check download option again to ensure it wasn't changed
      if ((!related || (related !== this && !this.contains(related))) && chart.options.download) {
        link.href = chart.toImage(download);
        element.appendChild(link);
      }
    });

    // mouseleave
    chart.__leaveEvent = element.addEventListener("mouseout", function (e) {
      var related = e.relatedTarget;
      if (!related || (related !== this && !this.contains(related))) {
        if (link.parentNode) {
          link.parentNode.removeChild(link);
        }
      }
    });
  }

  var pendingRequests = [];
  var runningRequests = 0;
  var maxRequests = 4;

  function pushRequest(url, success, error) {
    pendingRequests.push([url, success, error]);
    runNext();
  }

  function runNext() {
    if (runningRequests < maxRequests) {
      var request = pendingRequests.shift();
      if (request) {
        runningRequests++;
        getJSON(request[0], request[1], request[2]);
        runNext();
      }
    }
  }

  function requestComplete() {
    runningRequests--;
    runNext();
  }

  function getJSON(url, success, error) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onload = function () {
      requestComplete();
      if (xhr.status === 200) {
        success(JSON.parse(xhr.responseText));
      } else {
        error(xhr.statusText);
      }
    };
    xhr.send();
  }

  // helpers

  function setText(element, text) {
    element.textContent = text;
  }

  // TODO remove prefix for all messages
  function chartError(element, message, noPrefix) {
    if (!noPrefix) {
      message = "Error Loading Chart: " + message;
    }
    setText(element, message);
    element.style.color = "#ff0000";
  }

  function errorCatcher(chart) {
    try {
      chart.__render();
    } catch (err) {
      chartError(chart.element, err.message);
      throw err;
    }
  }

  function fetchDataSource(chart, dataSource, showLoading) {
    // only show loading message for urls and callbacks
    if (showLoading && chart.options.loading && (typeof dataSource === "string" || typeof dataSource === "function")) {
      setText(chart.element, chart.options.loading);
    }

    if (typeof dataSource === "string") {
      pushRequest(dataSource, function (data) {
        chart.rawData = data;
        errorCatcher(chart);
      }, function (message) {
        chartError(chart.element, message);
      });
    } else if (typeof dataSource === "function") {
      try {
        dataSource(function (data) {
          chart.rawData = data;
          errorCatcher(chart);
        }, function (message) {
          chartError(chart.element, message, true);
        });
      } catch (err) {
        chartError(chart.element, err, true);
      }
    } else {
      chart.rawData = dataSource;
      errorCatcher(chart);
    }
  }

  function renderChart(chartType, chart) {
    if (dataEmpty(chart.data, chartType)) {
      var message = chart.options.empty || (chart.options.messages && chart.options.messages.empty) || "No data";
      setText(chart.element, message);
    } else {
      callAdapter(chartType, chart);
      // TODO add downloadSupported method to adapter
      if (chart.options.download && !chart.__downloadAttached && chart.adapter === "chartjs") {
        addDownloadButton(chart);
      }
    }
  }

  function getElement(element) {
    if (typeof element === "string") {
      var elementId = element;
      element = document.getElementById(element);
      if (!element) {
        throw new Error("No element with id " + elementId);
      }
    }
    return element;
  }

  // define classes

  var Chart = function Chart(element, dataSource, options) {
    this.element = getElement(element);
    this.options = merge(Chartkick.options, options || {});
    this.dataSource = dataSource;

    // TODO handle charts without an id for eachChart and destroyAll
    if (this.element.id) {
      Chartkick.charts[this.element.id] = this;
    }

    fetchDataSource(this, dataSource, true);

    if (this.options.refresh) {
      this.startRefresh();
    }
  };

  Chart.prototype.getElement = function getElement () {
    return this.element;
  };

  Chart.prototype.getDataSource = function getDataSource () {
    return this.dataSource;
  };

  Chart.prototype.getData = function getData () {
    return this.data;
  };

  Chart.prototype.getOptions = function getOptions () {
    return this.options;
  };

  Chart.prototype.getChartObject = function getChartObject () {
    return this.chart;
  };

  Chart.prototype.getAdapter = function getAdapter () {
    return this.adapter;
  };

  Chart.prototype.updateData = function updateData (dataSource, options) {
    this.dataSource = dataSource;
    if (options) {
      this.__updateOptions(options);
    }
    fetchDataSource(this, dataSource, true);
  };

  Chart.prototype.setOptions = function setOptions (options) {
    this.__updateOptions(options);
    this.redraw();
  };

  Chart.prototype.redraw = function redraw () {
    fetchDataSource(this, this.rawData);
  };

  Chart.prototype.refreshData = function refreshData () {
    if (typeof this.dataSource === "string") {
      // prevent browser from caching
      var sep = this.dataSource.indexOf("?") === -1 ? "?" : "&";
      var url = this.dataSource + sep + "_=" + (new Date()).getTime();
      fetchDataSource(this, url);
    } else if (typeof this.dataSource === "function") {
      fetchDataSource(this, this.dataSource);
    }
  };

  Chart.prototype.startRefresh = function startRefresh () {
      var this$1$1 = this;

    var refresh = this.options.refresh;

    if (refresh && typeof this.dataSource !== "string" && typeof this.dataSource !== "function") {
      throw new Error("Data source must be a URL or callback for refresh");
    }

    if (!this.intervalId) {
      if (refresh) {
        this.intervalId = setInterval(function () {
          this$1$1.refreshData();
        }, refresh * 1000);
      } else {
        throw new Error("No refresh interval");
      }
    }
  };

  Chart.prototype.stopRefresh = function stopRefresh () {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  };

  Chart.prototype.toImage = function toImage (download) {
    // TODO move logic to adapter
    if (this.adapter === "chartjs") {
      if (download && download.background && download.background !== "transparent") {
        // https://stackoverflow.com/questions/30464750/chartjs-line-chart-set-background-color
        var canvas = this.chart.canvas;
        var ctx = this.chart.ctx;
        var tmpCanvas = document.createElement("canvas");
        var tmpCtx = tmpCanvas.getContext("2d");
        tmpCanvas.width = ctx.canvas.width;
        tmpCanvas.height = ctx.canvas.height;
        tmpCtx.fillStyle = download.background;
        tmpCtx.fillRect(0, 0, tmpCanvas.width, tmpCanvas.height);
        tmpCtx.drawImage(canvas, 0, 0);
        return tmpCanvas.toDataURL("image/png");
      } else {
        return this.chart.toBase64Image();
      }
    } else {
      throw new Error("Feature only available for Chart.js");
    }
  };

  Chart.prototype.destroy = function destroy () {
    this.destroyed = true;
    this.stopRefresh();

    if (this.__adapterObject) {
      this.__adapterObject.destroy(this);
    }

    if (this.__enterEvent) {
      this.element.removeEventListener("mouseover", this.__enterEvent);
    }

    if (this.__leaveEvent) {
      this.element.removeEventListener("mouseout", this.__leaveEvent);
    }
  };

  Chart.prototype.__updateOptions = function __updateOptions (options) {
    var updateRefresh = options.refresh && options.refresh !== this.options.refresh;
    this.options = merge(Chartkick.options, options);
    if (updateRefresh) {
      this.stopRefresh();
      this.startRefresh();
    }
  };

  Chart.prototype.__render = function __render () {
    this.data = this.__processData();
    renderChart(this.__chartName(), this);
  };

  Chart.prototype.__config = function __config () {
    return Chartkick.config;
  };

  var LineChart = /*@__PURE__*/(function (Chart) {
    function LineChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) LineChart.__proto__ = Chart;
    LineChart.prototype = Object.create( Chart && Chart.prototype );
    LineChart.prototype.constructor = LineChart;

    LineChart.prototype.__processData = function __processData () {
      return processSeries(this);
    };

    LineChart.prototype.__chartName = function __chartName () {
      return "LineChart";
    };

    return LineChart;
  }(Chart));

  var PieChart = /*@__PURE__*/(function (Chart) {
    function PieChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) PieChart.__proto__ = Chart;
    PieChart.prototype = Object.create( Chart && Chart.prototype );
    PieChart.prototype.constructor = PieChart;

    PieChart.prototype.__processData = function __processData () {
      return processSimple(this);
    };

    PieChart.prototype.__chartName = function __chartName () {
      return "PieChart";
    };

    return PieChart;
  }(Chart));

  var ColumnChart = /*@__PURE__*/(function (Chart) {
    function ColumnChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) ColumnChart.__proto__ = Chart;
    ColumnChart.prototype = Object.create( Chart && Chart.prototype );
    ColumnChart.prototype.constructor = ColumnChart;

    ColumnChart.prototype.__processData = function __processData () {
      return processSeries(this, null, true);
    };

    ColumnChart.prototype.__chartName = function __chartName () {
      return "ColumnChart";
    };

    return ColumnChart;
  }(Chart));

  var BarChart = /*@__PURE__*/(function (Chart) {
    function BarChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) BarChart.__proto__ = Chart;
    BarChart.prototype = Object.create( Chart && Chart.prototype );
    BarChart.prototype.constructor = BarChart;

    BarChart.prototype.__processData = function __processData () {
      return processSeries(this, null, true);
    };

    BarChart.prototype.__chartName = function __chartName () {
      return "BarChart";
    };

    return BarChart;
  }(Chart));

  var AreaChart = /*@__PURE__*/(function (Chart) {
    function AreaChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) AreaChart.__proto__ = Chart;
    AreaChart.prototype = Object.create( Chart && Chart.prototype );
    AreaChart.prototype.constructor = AreaChart;

    AreaChart.prototype.__processData = function __processData () {
      return processSeries(this);
    };

    AreaChart.prototype.__chartName = function __chartName () {
      return "AreaChart";
    };

    return AreaChart;
  }(Chart));

  var GeoChart = /*@__PURE__*/(function (Chart) {
    function GeoChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) GeoChart.__proto__ = Chart;
    GeoChart.prototype = Object.create( Chart && Chart.prototype );
    GeoChart.prototype.constructor = GeoChart;

    GeoChart.prototype.__processData = function __processData () {
      return processSimple(this);
    };

    GeoChart.prototype.__chartName = function __chartName () {
      return "GeoChart";
    };

    return GeoChart;
  }(Chart));

  var ScatterChart = /*@__PURE__*/(function (Chart) {
    function ScatterChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) ScatterChart.__proto__ = Chart;
    ScatterChart.prototype = Object.create( Chart && Chart.prototype );
    ScatterChart.prototype.constructor = ScatterChart;

    ScatterChart.prototype.__processData = function __processData () {
      return processSeries(this, "number");
    };

    ScatterChart.prototype.__chartName = function __chartName () {
      return "ScatterChart";
    };

    return ScatterChart;
  }(Chart));

  var BubbleChart = /*@__PURE__*/(function (Chart) {
    function BubbleChart () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) BubbleChart.__proto__ = Chart;
    BubbleChart.prototype = Object.create( Chart && Chart.prototype );
    BubbleChart.prototype.constructor = BubbleChart;

    BubbleChart.prototype.__processData = function __processData () {
      return processSeries(this, "bubble");
    };

    BubbleChart.prototype.__chartName = function __chartName () {
      return "BubbleChart";
    };

    return BubbleChart;
  }(Chart));

  var Timeline = /*@__PURE__*/(function (Chart) {
    function Timeline () {
      Chart.apply(this, arguments);
    }

    if ( Chart ) Timeline.__proto__ = Chart;
    Timeline.prototype = Object.create( Chart && Chart.prototype );
    Timeline.prototype.constructor = Timeline;

    Timeline.prototype.__processData = function __processData () {
      var data = this.rawData;
      for (var i = 0; i < data.length; i++) {
        data[i][1] = toDate(data[i][1]);
        data[i][2] = toDate(data[i][2]);
      }
      return data;
    };

    Timeline.prototype.__chartName = function __chartName () {
      return "Timeline";
    };

    return Timeline;
  }(Chart));

  Chartkick.LineChart = LineChart;
  Chartkick.PieChart = PieChart;
  Chartkick.ColumnChart = ColumnChart;
  Chartkick.BarChart = BarChart;
  Chartkick.AreaChart = AreaChart;
  Chartkick.GeoChart = GeoChart;
  Chartkick.ScatterChart = ScatterChart;
  Chartkick.BubbleChart = BubbleChart;
  Chartkick.Timeline = Timeline;

  // not ideal, but allows for simpler integration
  if (typeof window !== "undefined" && !window.Chartkick) {
    window.Chartkick = Chartkick;

    // clean up previous charts before Turbolinks loads new page
    document.addEventListener("turbolinks:before-render", function () {
      if (Chartkick.config.autoDestroy !== false) {
        Chartkick.destroyAll();
      }
    });

    // clean up previous charts before Turbo loads new page
    document.addEventListener("turbo:before-render", function () {
      if (Chartkick.config.autoDestroy !== false) {
        Chartkick.destroyAll();
      }
    });

    // use setTimeout so charting library can come later in same JS file
    setTimeout(function () {
      window.dispatchEvent(new Event("chartkick:load"));
    }, 0);
  }

  // backwards compatibility for esm require
  Chartkick.default = Chartkick;

  return Chartkick;

}));
