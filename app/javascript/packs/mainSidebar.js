const rootDomain = document.getElementById('root-subforem-link')?.getAttribute('href').replace(/https?:\/\//, '').replace(/\/$/, '');

fetch(`/stories/feed/?page=1&type_of=discover&passed_domain=${rootDomain}`, {
  method: 'GET',
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  },
  credentials: 'same-origin',
})
.then((response) => response.json())
.then((data) => {
  const feedContainer = document.getElementById('main-side-feed');
  const articleContainer = document.getElementById('article-show-container');
  let articleId = null;
  if (articleContainer) {
    articleId = articleContainer.getAttribute('data-article-id');
  }
  if (feedContainer) {
    feedContainer.innerHTML = data.map((article) => `
      <a href="${article.url}" class="crayons-link crayons-link--contentful flex items-center ${article.id === articleId ? 'active' : ''}" data-article-id="${article.id}">
      <img src="${article.subforem_logo}" alt="Logo" class="crayons-side-nav__item-icon">
      <span class="crayons-side-nav__item-text">${article.title}</span>
      </a>
    `).join('');
  }
})
.catch((error) => {
  console.error('Error fetching stories:', error);
});
