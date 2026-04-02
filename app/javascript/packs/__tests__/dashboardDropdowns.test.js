import { toggleArchived } from '../dashboardDropdowns';

jest.mock('@utilities/dropdownUtils', () => ({
  initializeDropdown: jest.fn().mockReturnValue({ closeDropdown: jest.fn() }),
}));

describe('toggleArchived', () => {
  let article;

  beforeEach(() => {
    article = document.createElement('div');
    article.classList.add('js-dashboard-story', 'story-archived');
    document.body.appendChild(article);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('when needsArchived is "true"', () => {
    it('removes the article element from the DOM', () => {
      toggleArchived(article, 'true');
      expect(document.body.contains(article)).toBe(false);
    });

    it('reveals the hidden Show Archived button when one exists', () => {
      const btn = document.createElement('a');
      btn.classList.add('js-show-archived-btn');
      btn.setAttribute('hidden', 'hidden');
      document.body.appendChild(btn);

      toggleArchived(article, 'true');

      expect(btn.hasAttribute('hidden')).toBe(false);
    });

    it('does not error when no Show Archived button is in the DOM', () => {
      expect(() => toggleArchived(article, 'true')).not.toThrow();
    });

    it('does not affect an already-visible Show Archived button', () => {
      const btn = document.createElement('a');
      btn.classList.add('js-show-archived-btn');
      // no hidden attribute — already visible
      document.body.appendChild(btn);

      toggleArchived(article, 'true');

      expect(btn.hasAttribute('hidden')).toBe(false);
    });
  });

  describe('when needsArchived is not "true"', () => {
    it('removes the story-archived class from the article', () => {
      toggleArchived(article, 'false');
      expect(article.classList.contains('story-archived')).toBe(false);
    });

    it('keeps the article in the DOM', () => {
      toggleArchived(article, 'false');
      expect(document.body.contains(article)).toBe(true);
    });

    it('does not affect the Show Archived button', () => {
      const btn = document.createElement('a');
      btn.classList.add('js-show-archived-btn');
      btn.setAttribute('hidden', 'hidden');
      document.body.appendChild(btn);

      toggleArchived(article, 'false');

      expect(btn.hasAttribute('hidden')).toBe(true);
    });
  });
});
