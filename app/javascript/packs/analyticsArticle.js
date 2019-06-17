import initCharts from '../analytics/dashboard';

function initDashboardArticle() {
  const article = document.getElementById('article');
  initCharts({ articleId: article.dataset.articleId });
}

window.InstantClick.on('change', () => {
  initDashboardArticle();
});

initDashboardArticle();
