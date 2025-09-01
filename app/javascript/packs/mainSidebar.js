// You'll need to make the FeedTracker class available in this file's scope.
// Assuming you are using JS modules, you would do:
import { FeedTracker } from '../packs/feedEvents.js';

const rootDomain = document.getElementById('root-subforem-link')?.getAttribute('href').split('/')[2] || '';

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
      <a href="${article.url}" class="crayons-link crayons-link--contentful crayons-link--contentfulsidebar ${article.id === articleId ? 'active' : ''}" data-article-id="${article.id}">
      ${article.main_image ? `<img src="${article.main_image}" loading="lazy" alt="Cover Image" class="crayons-side-nav__item-cover" width="1000" height="${article.main_image_height}" style="aspect-ratio: 1000 / ${article.main_image_height}">` : ''}
      <div class="flex ${article.title.length < 40 ? 'items-center' : ''}">
        <img src="${article.subforem_logo}" alt="Logo" class="crayons-side-nav__item-icon">
        <span class="crayons-side-nav__item-text">${article.title}</span>
      </div>
      </a>
    `).join('');

    // --- START: ADDED TRACKING LOGIC ---
    // Ensure the FeedTracker class is available (e.g. via import or a global script tag)
    if (typeof FeedTracker !== 'undefined') {
      const sidebarTracker = new FeedTracker({
        feedItemsRoot: feedContainer, // The element containing the links
        contentIdAttribute: 'articleId', // The data attribute for the ID is 'data-article-id'
        config: {
          categoryClick: 'click',
          categoryImpression: 'impression',
          contextType: 'sidebar',
          feedConfigId: data[0].feed_config // A unique identifier for this feed type
        }
      });
      sidebarTracker.init();
    }
    // --- END: ADDED TRACKING LOGIC ---
  }
  // For each a element within the main sidebar feed, remove the 'hovered' class and add 'not-hovered' when clicked
  const links = document.querySelectorAll('#main-side-bar a');
  links.forEach((link) => {
    link.addEventListener('click', () => {
      links.forEach((l) => {
        l.classList.remove('hovered');
        l.classList.add('not-hovered');
      });
    });
  });
})
.catch((error) => {
  console.error('Error fetching stories:', error);
});


window.InstantClick.on('change', () => {
  // Remove active class from all .crayons-side-nav__item elements
  const hoveredItems = document.querySelectorAll('.crayons-side-nav__item.hovered');
  hoveredItems.forEach((item) => {
    item.classList.remove('hovered');
    item.classList.add('not-hovered');
  });
  let feedEl = document.getElementById('root-feed-card');
  if (feedEl) {
    feedEl.scrollTop = 0;
  }
});