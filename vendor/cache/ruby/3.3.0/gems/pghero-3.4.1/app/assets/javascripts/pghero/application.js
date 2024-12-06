//= require ./jquery
//= require ./nouislider
//= require ./Chart.bundle
//= require ./chartkick
//= require ./highlight.min

function highlightQueries() {
  $("pre code").each(function (i, block) {
    $(block).addClass("language-pgsql");
    hljs.highlightElement(block);
  });
}

function initSlider() {
  function roundTime(time) {
    var period = 1000 * 60 * 5;
    return new Date(Math.ceil(time.getTime() / period) * period);
  }

  function pad(num) {
    return (num < 10) ? "0" + num : num;
  }

  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  var days = 1;
  var now = new Date();
  var sliderStartAt = roundTime(now) - days * 24 * 60 * 60 * 1000;
  var sliderMax = 24 * 12 * days;

  startAt = startAt || sliderStartAt;
  var min = (startAt > 0) ? (startAt - sliderStartAt) / (1000 * 60 * 5) : 0;

  var max = (endAt > 0) ? (endAt - sliderStartAt) / (1000 * 60 * 5) : sliderMax;

  var slider = document.getElementById("slider");

  noUiSlider.create(slider, {
    range: {
      min: 0,
      max: sliderMax
    },
    step: 1,
    connect: true,
    start: [min, max]
  });

  // remove outline for mouse only
  $(".noUi-handle").mousedown(function () {
    $(this).addClass("no-outline");
  }).blur(function () {
    $(this).removeClass("no-outline");
  });

  function updateText() {
    var values = slider.noUiSlider.get();
    setText("#range-start", values[0]);
    setText("#range-end", values[1]);
  }

  function setText(selector, offset) {
    var time = timeAt(offset);

    var html = "";
    if (time === now) {
      if (selector === "#range-end") {
        html = "Now";
      }
    } else {
      html = time.getDate() + " " + months[time.getMonth()] + " " + pad(time.getHours()) + ":" + pad(time.getMinutes());
    }
    $(selector).text(html);
  }

  function timeAt(offset) {
    var time = new Date(sliderStartAt + (offset * 5) * 60 * 1000);
    return (time > now) ? now : time;
  }

  function timeParam(time) {
    return time.toISOString().replace(/\.000Z$/, "Z");
  }

  function queriesPath(params) {
    var path = "queries";
    if (params.start_at || params.end_at || params.sort || params.min_average_time || params.min_calls || params.debug) {
      path += "?" + $.param(params);
    }
    return path;
  }

  function refreshStats(push) {
    var values = slider.noUiSlider.get();
    var startAt = push ? timeAt(values[0]) : new Date(window.startAt);
    var endAt = timeAt(values[1]);

    var params = {}
    if (startAt.getTime() != sliderStartAt) {
      params.start_at = timeParam(startAt);
    }
    if (endAt < now) {
      params.end_at = timeParam(endAt);
    }
    if (sort) {
      params.sort = sort;
    }
    if (minAverageTime) {
      params.min_average_time = minAverageTime;
    }
    if (minCalls) {
      params.min_calls = minCalls;
    }
    if (debug) {
      params.debug = debug;
    }

    var path = queriesPath(params);

    $(".queries-table th a").each(function () {
      var p = $.extend({}, params, {sort: $(this).data("sort"), min_average_time: minAverageTime, min_calls: minCalls, debug: debug});
      if (!p.sort) {
        delete p.sort;
      }
      if (!p.min_average_time) {
        delete p.min_average_time;
      }
      if (!p.min_calls) {
        delete p.min_calls;
      }
      if (!p.debug) {
        delete p.debug;
      }
      $(this).attr("href", queriesPath(p));
    });


    var callback = function (response, status, xhr) {
      if (status === "error" ) {
        $(".queries-info").css("color", "red").text(xhr.status + " " + xhr.statusText);
      } else {
        highlightQueries();
      }
    };
    $("#queries").html('<tr><td colspan="3"><p class="queries-info text-muted">...</p></td></tr>').load(path, callback);

    if (push && history.pushState) {
      history.pushState(null, null, path);
    }
  }

  slider.noUiSlider.on("slide", updateText);
  slider.noUiSlider.on("change", function () {
    refreshStats(true);
  });
  updateText();
  $(function () {
    refreshStats(false);
  });
}
