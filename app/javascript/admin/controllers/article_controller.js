import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class ArticleController extends Controller {
  static classes = ['bgHighlighted', 'borderHighlighted'];
  static targets = ['featuredNumber', 'cardBody'];

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
}
