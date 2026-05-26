import { Controller } from '@hotwired/stimulus';
import ApexCharts from 'apexcharts';

export default class extends Controller {
  static values = {
    type: String,
    categories: Array,
    votes: Array
  }

  connect() {
    this.renderChart();
  }

  renderChart() {
    const pollType = this.typeValue;
    const categories = this.categoriesValue;
    const votes = this.votesValue;

    const options = {
      series: [],
      chart: {
        height: 350,
        toolbar: { show: false }
      },
      colors: ['#3b49df', '#f9c513', '#ff4242', '#1cae65', '#2a0076', '#e03131', '#0f172a'],
      dataLabels: { enabled: true }
    };

    if (pollType === 'single_choice') {
      options.chart.type = 'donut';
      options.series = votes;
      options.labels = categories;
    } else if (pollType === 'multiple_choice') {
      options.chart.type = 'bar';
      options.series = [{ name: 'Votes', data: votes }];
      options.xaxis = { categories: categories };
      options.plotOptions = { bar: { horizontal: true, borderRadius: 4 } };
    } else if (pollType === 'scale') {
      options.chart.type = 'bar';
      options.series = [{ name: 'Votes', data: votes }];
      options.xaxis = { categories: categories };
      options.plotOptions = { bar: { horizontal: false, borderRadius: 4, columnWidth: '50%' } };
    }

    if (votes.some(v => v > 0) || pollType === 'scale') {
      const chart = new ApexCharts(this.element, options);
      chart.render();
    } else {
      this.element.innerHTML = '<p class="color-base-60 italic">No votes yet.</p>';
    }
  }
}
