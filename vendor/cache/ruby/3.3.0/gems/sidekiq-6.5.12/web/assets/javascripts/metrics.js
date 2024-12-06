if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
  Chart.defaults.borderColor = "#333"
  Chart.defaults.color = "#aaa"
}

class BaseChart {
  constructor(id, options) {
    this.ctx = document.getElementById(id);
    this.options = options
    this.fallbackColor = "#999";
    this.colors = [
      // Colors taken from https://www.chartjs.org/docs/latest/samples/utils.html
      "#537bc4",
      "#4dc9f6",
      "#f67019",
      "#f53794",
      "#acc236",
      "#166a8f",
      "#00a950",
      "#58595b",
      "#8549ba",
      "#991b1b",
    ];

    this.chart = new Chart(this.ctx, {
      type: this.options.chartType,
      data: { labels: this.options.labels, datasets: this.datasets },
      options: this.chartOptions,
    });
  }

  addMarksToChart() {
    this.options.marks.forEach(([bucket, label], i) => {
      this.chart.options.plugins.annotation.annotations[`deploy-${i}`] = {
        type: "line",
        xMin: bucket,
        xMax: bucket,
        borderColor: "rgba(220, 38, 38, 0.4)",
        borderWidth: 2,
      };
    });
  }
}

class JobMetricsOverviewChart extends BaseChart {
  constructor(id, options) {
    super(id, { ...options, chartType: "line" });
    this.swatches = [];

    this.addMarksToChart();
    this.chart.update();
  }

  registerSwatch(id) {
    const el = document.getElementById(id);
    el.onchange = () => this.toggle(el.value, el.checked);
    this.swatches[el.value] = el;
    this.updateSwatch(el.value);
  }

  updateSwatch(kls) {
    const el = this.swatches[kls];
    const ds = this.chart.data.datasets.find((ds) => ds.label == kls);
    el.checked = !!ds;
    el.style.color = ds ? ds.borderColor : null;
  }

  toggle(kls, visible) {
    if (visible) {
      this.chart.data.datasets.push(this.dataset(kls));
    } else {
      const i = this.chart.data.datasets.findIndex((ds) => ds.label == kls);
      this.colors.unshift(this.chart.data.datasets[i].borderColor);
      this.chart.data.datasets.splice(i, 1);
    }

    this.updateSwatch(kls);
    this.chart.update();
  }

  dataset(kls) {
    const color = this.colors.shift() || this.fallbackColor;

    return {
      label: kls,
      data: this.options.series[kls],
      borderColor: color,
      backgroundColor: color,
      borderWidth: 2,
      pointRadius: 2,
    };
  }

  get datasets() {
    return Object.entries(this.options.series)
      .filter(([kls, _]) => this.options.visible.includes(kls))
      .map(([kls, _]) => this.dataset(kls));
  }

  get chartOptions() {
    return {
      aspectRatio: 4,
      scales: {
        y: {
          beginAtZero: true,
          title: {
            text: "Total execution time (sec)",
            display: true,
          },
        },
      },
      interaction: {
        mode: "x",
      },
      plugins: {
        legend: {
          display: false,
        },
        tooltip: {
          callbacks: {
            title: (items) => `${items[0].label} UTC`,
            label: (item) =>
              `${item.dataset.label}: ${item.parsed.y.toFixed(1)} seconds`,
            footer: (items) => {
              const bucket = items[0].label;
              const marks = this.options.marks.filter(([b, _]) => b == bucket);
              return marks.map(([b, msg]) => `Deploy: ${msg}`);
            },
          },
        },
      },
    };
  }
}

class HistTotalsChart extends BaseChart {
  constructor(id, options) {
    super(id, { ...options, chartType: "bar" });
  }

  get datasets() {
    return [{
      data: this.options.series,
      backgroundColor: this.colors[0],
      borderWidth: 0,
    }];
  }

  get chartOptions() {
    return {
      aspectRatio: 6,
      scales: {
        y: {
          beginAtZero: true,
          title: {
            text: "Total jobs",
            display: true,
          },
        },
      },
      interaction: {
        mode: "x",
      },
      plugins: {
        legend: {
          display: false,
        },
        tooltip: {
          callbacks: {
            label: (item) => `${item.parsed.y} jobs`,
          },
        },
      },
    };
  }
}

class HistBubbleChart extends BaseChart {
  constructor(id, options) {
    super(id, { ...options, chartType: "bubble" });

    this.addMarksToChart();
    this.chart.update();
  }

  get datasets() {
    const data = [];
    let maxCount = 0;

    Object.entries(this.options.hist).forEach(([bucket, hist]) => {
      hist.forEach((count, histBucket) => {
        if (count > 0) {
          data.push({
            x: bucket,
            // histogram data is ordered fastest to slowest, but this.histIntervals is
            // slowest to fastest (so it displays correctly on the chart).
            y:
              this.options.histIntervals[this.options.histIntervals.length - 1 - histBucket] /
              1000,
            count: count,
          });

          if (count > maxCount) maxCount = count;
        }
      });
    });

    // Chart.js will not calculate the bubble size. We have to do that.
    const maxRadius = this.ctx.offsetWidth / this.options.labels.length;
    const minRadius = 1
    const multiplier = (maxRadius / maxCount) * 1.5;
    data.forEach((entry) => {
      entry.r = entry.count * multiplier + minRadius;
    });

    return [{
      data: data,
      backgroundColor: "#537bc4",
      borderColor: "#537bc4",
    }];
  }

  get chartOptions() {
    return {
      aspectRatio: 3,
      scales: {
        x: {
          type: "category",
          labels: this.options.labels,
        },
        y: {
          title: {
            text: "Execution time (sec)",
            display: true,
          },
        },
      },
      interaction: {
        mode: "x",
      },
      plugins: {
        legend: {
          display: false,
        },
        tooltip: {
          callbacks: {
            title: (items) => `${items[0].raw.x} UTC`,
            label: (item) =>
              `${item.parsed.y} seconds: ${item.raw.count} job${
                item.raw.count == 1 ? "" : "s"
              }`,
            footer: (items) => {
              const bucket = items[0].raw.x;
              const marks = this.options.marks.filter(([b, _]) => b == bucket);
              return marks.map(([b, msg]) => `Deploy: ${msg}`);
            },
          },
        },
      },
    };
  }
}
