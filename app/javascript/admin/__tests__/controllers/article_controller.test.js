import { Application } from '@hotwired/stimulus';
import ArticleController from '../../controllers/article_controller';

describe('ArticleController', () => {
  beforeEach(() => {
    document.body.innerHTML = `
    <div data-controller="article"
         data-article-bg-highlighted-class="bg-highlighted"
         data-article-border-highlighted-class="border-highlighted">
      <div class="card-body" data-article-target="cardBody">
        <button data-action="article#increaseFeaturedNumber"></button>
        <button data-action="article#decreaseFeaturedNumber"></button>
        <button data-action="article#highlightElement"></button>
        <input data-article-target="featuredNumber"></input>
      </div>
    </div>`;

    const application = Application.start();
    application.register('article', ArticleController);
  });

  // Unix timestamp, one hour ago
  const initialValue = Math.round((Date.now() - 3600000) / 1000);

  describe('#increaseFeaturedNumber', () => {
    it('increases the featured number input', () => {
      const button = document.getElementsByTagName('button')[0];
      const input = document.querySelector(
        "[data-article-target='featuredNumber']",
      );

      input.value = initialValue;
      button.click();

      expect(parseInt(input.value, 10)).toBeGreaterThan(initialValue);
    });
  });

  describe('#decreaseFeaturedNumber', () => {
    it('increases the featured number input', () => {
      const button = document.getElementsByTagName('button')[1];
      const input = document.querySelector(
        "[data-article-target='featuredNumber']",
      );

      input.value = initialValue;
      button.click();

      expect(parseInt(input.value, 10)).toBeLessThan(initialValue);
    });
  });

  describe('#highlightElement', () => {
    it('adds a class to the controller element', () => {
      const button = document.getElementsByTagName('button')[2];
      const element = document.getElementsByClassName('card-body')[0];

      button.click();

      expect(
        element.classList.contains('bg-highlighted', 'border-highlighted'),
      ).toBe(true);
    });
  });
});
