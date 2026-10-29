import { Controller } from '@hotwired/stimulus';
import ApexCharts from 'apexcharts';

export default class extends Controller {
  static values = {
    dates: Array,
    popularity: Array,
    views: Array,
    reactions: Array
  }

  connect() {
    this.renderChart();
  }

  renderChart() {
    const dates = this.datesValue;
    if (!dates || dates.length === 0) {
      this.element.innerHTML = `
        <div class="flex flex-col items-center justify-center p-8 text-center text-secondary border border-dashed rounded bg-base-5">
          <p class="fs-s color-base-60">No daily metrics recorded yet.</p>
        </div>
      `;
      return;
    }

    const options = {
      series: [
        {
          name: 'Popularity Score',
          type: 'line',
          data: this.popularityValue
        },
        {
          name: 'Page Views',
          type: 'area',
          data: this.viewsValue
        },
        {
          name: 'Reactions',
          type: 'column',
          data: this.reactionsValue
        }
      ],
      chart: {
        height: 350,
        type: 'line',
        stacked: false,
        toolbar: { show: false }
      },
      stroke: {
        width: [3, 2, 0],
        curve: 'smooth'
      },
      plotOptions: {
        bar: {
          columnWidth: '50%'
        }
      },
      fill: {
        opacity: [1, 0.2, 0.8],
        gradient: {
          inverseColors: false,
          shade: 'light',
          type: "vertical",
          opacityFrom: 0.85,
          opacityTo: 0.55,
          stops: [0, 100, 100]
        }
      },
      labels: dates,
      markers: {
        size: 4
      },
      xaxis: {
        type: 'datetime',
        labels: {
          datetimeUTC: false
        }
      },
      yaxis: [
        {
          title: {
            text: 'Popularity & Page Views',
          },
        },
        {
          opposite: true,
          title: {
            text: 'Reactions'
          }
        }
      ],
      tooltip: {
        shared: true,
        intersect: false,
        y: {
          formatter: function (y) {
            if (typeof y !== "undefined") {
              return y.toFixed(0);
            }
            return y;
          }
        }
      },
      colors: ['#3b49df', '#1cae65', '#f9c513']
    };

    const chart = new ApexCharts(this.element, options);
    chart.render();
  }
}
