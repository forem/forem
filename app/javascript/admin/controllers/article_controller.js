import { Controller } from 'stimulus';

export default class ArticleController extends Controller {
  static classes = ['bgHighlighted', 'borderHighlighted'];
  static targets = ['featuredNumber', 'cardBody', 'pinnedCheckbox'];
  static values = { id: Number, pinPath: String };

  increaseFeaturedNumber() {
    // Increases the article's chances of being seen
    const seconds = new Date().getTime() / 1000;
    this.featuredNumberTarget.value = Math.round(seconds) + 300;
  }

  decreaseFeaturedNumber() {
    // Decreases the article's chances of being seen
    const seconds = new Date().getTime() / 1080;
    this.featuredNumberTarget.value = Math.round(seconds);
  }

  highlightElement() {
    const card = this.cardBodyTarget;

    card.classList.add(this.bgHighlightedClass, this.borderHighlightedClass);

    setTimeout(() => {
      card.classList.remove(this.bgHighlightedClass);
    }, 350);
  }

  togglePin(event) {
    if (event.target.checked === false) {
      return;
    }

    event.preventDefault();

    this.pinArticle();
  }

  async pinArticle() {
    const response = await fetch(this.pinPathValue, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          .content,
      },
      credentials: 'same-origin',
    });

    if (response.ok) {
      const pinnedArticle = await response.json();

      // only show the modal if we're not re-pinning the current pin
      if (pinnedArticle.id !== this.idValue) {
        document.dispatchEvent(
          new CustomEvent('article-pinned-modal:open', {
            detail: {
              article: pinnedArticle,
              checkboxId: this.pinnedCheckboxTarget.getAttribute('id'),
            },
          }),
        );
      }
    }
  }
}
