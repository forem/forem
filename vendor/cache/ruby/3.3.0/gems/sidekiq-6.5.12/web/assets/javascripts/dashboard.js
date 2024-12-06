Sidekiq = {};

var nf = new Intl.NumberFormat();
var poller;
var realtimeGraph = function(updatePath) {
  var timeInterval = parseInt(localStorage.sidekiqTimeInterval) || 5000;
  var graphElement = document.getElementById("realtime");

  var graph = new Rickshaw.Graph( {
    element: graphElement,
    width: responsiveWidth(),
    height: 200,
    renderer: 'line',
    interpolation: 'linear',

    series: new Rickshaw.Series.FixedDuration([{ name: graphElement.dataset.failedLabel, color: '#af0014' }, { name: graphElement.dataset.processedLabel, color: '#006f68' }], undefined, {
      timeInterval: timeInterval,
      maxDataPoints: 100,
    })
  });

  var y_axis = new Rickshaw.Graph.Axis.Y( {
    graph: graph,
    tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
    ticksTreatment: 'glow'
  });

  graph.render();

  var legend = document.getElementById('realtime-legend');
  var Hover = Rickshaw.Class.create(Rickshaw.Graph.HoverDetail, {
    render: function(args) {
      legend.innerHTML = "";

      var timestamp = document.createElement('div');
      timestamp.className = 'timestamp';
      timestamp.innerHTML = args.formattedXValue;
      legend.appendChild(timestamp);

      args.detail.sort(function(a, b) { return a.order - b.order }).forEach( function(d) {
        var line = document.createElement('div');
        line.className = 'line';

        var swatch = document.createElement('div');
        swatch.className = 'swatch';
        swatch.style.backgroundColor = d.series.color;

        var label = document.createElement('div');
        label.className = 'tag';
        label.innerHTML = d.name + ": " + nf.format(Math.floor(d.formattedYValue));

        line.appendChild(swatch);
        line.appendChild(label);
        legend.appendChild(line);

        var dot = document.createElement('div');
        dot.className = 'dot';
        dot.style.top = graph.y(d.value.y0 + d.value.y) + 'px';
        dot.style.borderColor = d.series.color;

        this.element.appendChild(dot);
        dot.className = 'dot active';
        this.show();
      }, this );
    }
  });
  var hover = new Hover( { graph: graph } );

  var i = 0;
  poller = setInterval(function() {
    var url = document.getElementById("history").getAttribute("data-update-url");

    fetch(url).then(response => response.json()).then(data => {
      if (i === 0) {
        var processed = data.sidekiq.processed;
        var failed = data.sidekiq.failed;
      } else {
        var processed = data.sidekiq.processed - Sidekiq.processed;
        var failed = data.sidekiq.failed - Sidekiq.failed;
      }

      dataPoint = {};
      dataPoint[graphElement.dataset.failedLabel] = failed;
      dataPoint[graphElement.dataset.processedLabel] = processed;

      graph.series.addData(dataPoint);
      graph.render();

      Sidekiq.processed = data.sidekiq.processed;
      Sidekiq.failed = data.sidekiq.failed;

      updateStatsSummary(data.sidekiq);
      updateRedisStats(data.redis);
      updateFooterUTCTime(data.server_utc_time)

      pulseBeacon();
    });

    i++;
  }, timeInterval);
}

var historyGraph = function() {
  var h = document.getElementById("history");
  processed = createSeries(h.getAttribute("data-processed"));
  failed = createSeries(h.getAttribute("data-failed"));

  var graphElement = h;
  var graph = new Rickshaw.Graph( {
    element: graphElement,
    width: responsiveWidth(),
    height: 200,
    renderer: 'line',
    interpolation: 'linear',
    series: [
      {
        color: "#af0014",
        data: failed,
        name: graphElement.dataset.failedLabel
      }, {
        color: "#006f68",
        data: processed,
        name: graphElement.dataset.processedLabel
      }
    ]
  } );
  var x_axis = new Rickshaw.Graph.Axis.Time( { graph: graph } );
  var y_axis = new Rickshaw.Graph.Axis.Y({
    graph: graph,
    tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
    ticksTreatment: 'glow'
  });

  graph.render();

  var legend = document.getElementById('history-legend');
  var Hover = Rickshaw.Class.create(Rickshaw.Graph.HoverDetail, {
    render: function(args) {
      legend.innerHTML = "";

      var timestamp = document.createElement('div');
      timestamp.className = 'timestamp';
      timestamp.innerHTML = args.formattedXValue;
      legend.appendChild(timestamp);

      args.detail.sort(function(a, b) { return a.order - b.order }).forEach( function(d) {
        var line = document.createElement('div');
        line.className = 'line';

        var swatch = document.createElement('div');
        swatch.className = 'swatch';
        swatch.style.backgroundColor = d.series.color;

        var label = document.createElement('div');
        label.className = 'tag';
        label.innerHTML = d.name + ": " + nf.format(Math.floor(d.formattedYValue));

        line.appendChild(swatch);
        line.appendChild(label);
        legend.appendChild(line);

        var dot = document.createElement('div');
        dot.className = 'dot';
        dot.style.top = graph.y(d.value.y0 + d.value.y) + 'px';
        dot.style.borderColor = d.series.color;

        this.element.appendChild(dot);
        dot.className = 'dot active';
        this.show();
      }, this );
    }
  });
  var hover = new Hover( { graph: graph } );
}

var createSeries = function(data) {
  var obj = JSON.parse(data);
  var series = [];
  for (var date in obj) {
    var value = obj[date];
    var point = { x: Date.parse(date)/1000, y: value };
    series.unshift(point);
  }
  return series;
};

var updateStatsSummary = function(data) {
  document.getElementById("txtProcessed").innerText = nf.format(data.processed);
  document.getElementById("txtFailed").innerText = nf.format(data.failed);
  document.getElementById("txtBusy").innerText = nf.format(data.busy);
  document.getElementById("txtScheduled").innerText = nf.format(data.scheduled);
  document.getElementById("txtRetries").innerText = nf.format(data.retries);
  document.getElementById("txtEnqueued").innerText = nf.format(data.enqueued);
  document.getElementById("txtDead").innerText = nf.format(data.dead);
}

var updateRedisStats = function(data) {
  document.getElementById('redis_version').innerText = data.redis_version;
  document.getElementById('uptime_in_days').innerText = data.uptime_in_days;
  document.getElementById('connected_clients').innerText = data.connected_clients;
  document.getElementById('used_memory_human').innerText = data.used_memory_human;
  document.getElementById('used_memory_peak_human').innerText = data.used_memory_peak_human;
}

var updateFooterUTCTime = function(time) {
  document.getElementById('serverUtcTime').innerText = time;
}

var pulseBeacon = function() {
  document.getElementById('beacon').classList.add('pulse');
  window.setTimeout(() => { document.getElementById('beacon').classList.remove('pulse'); }, 1000);
}

// Render graphs
var renderGraphs = function() {
  realtimeGraph();
  historyGraph();
};

var setSliderLabel = function(val) {
  document.getElementById('sldr-text').innerText = Math.round(parseFloat(val) / 1000) + ' sec';
}

var ready = (callback) => {
  if (document.readyState != "loading") callback();
  else document.addEventListener("DOMContentLoaded", callback);
}

ready(() => {
  renderGraphs();

  var sldr = document.getElementById('sldr');
  if (typeof localStorage.sidekiqTimeInterval !== 'undefined') {
    sldr.value = localStorage.sidekiqTimeInterval;
    setSliderLabel(localStorage.sidekiqTimeInterval);
  }

  sldr.addEventListener("change", event => {
    clearInterval(poller);
    localStorage.sidekiqTimeInterval = sldr.value;
    setSliderLabel(sldr.value);
    resetGraphs();
    renderGraphs();
  });

  sldr.addEventListener("mousemove", event => {
    setSliderLabel(sldr.value);
  });
});

// Reset graphs
var resetGraphs = function() {
  document.getElementById('realtime').innerHTML = '';
  document.getElementById('history').innerHTML = '';
};

// Resize graphs after resizing window
var debounce = function(fn, timeout) {
  var timeoutID = -1;
  return function() {
    if (timeoutID > -1) {
      window.clearTimeout(timeoutID);
    }
    timeoutID = window.setTimeout(fn, timeout);
  }
};

window.onresize = function() {
  var prevWidth = window.innerWidth;
  return debounce(function () {
    var currWidth = window.innerWidth;
    if (prevWidth !== currWidth) {
      prevWidth = currWidth;
      clearInterval(poller);
      resetGraphs();
      renderGraphs();
    }
  }, 125);
}();
