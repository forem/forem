import { Application } from 'stimulus';
import ArticleController from '../../controllers/article_controller';

describe('ArticleController', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="article">
      <div class="card-body">
        <button data-action="article#increaseFeaturedNumber"></button>
        <button data-action="article#decreaseFeaturedNumber"></button>
        <button data-action="article#highlightElement"></button>
        <input data-target="article.featuredNumber"></input>
      </div>
    </div>`;

    const application = Application.start();
    application.register('article', ArticleController);
  });

  // Unix timestamp, one hour ago
  const initialValue = Math.round((Date.now() - 3600000) / 1000);

  describe('#increaseFeaturedNumber', () => {
    it('increases the featured number input', () => {
      const button = document.querySelectorAll('button')[0];
      const input = document.querySelector(
        "[data-target='article.featuredNumber']",
      );

      input.value = initialValue;
      button.click();

      expect(parseInt(input.value, 10)).toBeGreaterThan(initialValue);
    });
  });

  describe('#decreaseFeaturedNumber', () => {
    it('increases the featured number input', () => {
      const button = document.querySelectorAll('button')[1];
      const input = document.querySelector(
        "[data-target='article.featuredNumber']",
      );

      input.value = initialValue;
      button.click();

      expect(parseInt(input.value, 10)).toBeLessThan(initialValue);
    });
  });

  describe('#highlightElement', () => {
    it('adds a class to the controller element', () => {
      const button = document.querySelectorAll('button')[2];
      const element = document.querySelector('.card-body');

      button.click();

      expect(
        element.classList.contains('bg-highlighted', 'border-highlighted'),
      ).toBe(true);
    });
  });
});
