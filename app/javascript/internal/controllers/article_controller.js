import { Controller } from 'stimulus';

export default class ArticleController extends Controller {
  static targets = ['featuredNumber'];

  increaseFeaturedNumber() {
    // Increases the article's chances of being seen
    const seconds = new Date().getTime() / 1000;
    this.featuredNumberTarget.value = Math.round(seconds);
  }

  decreaseFeaturedNumber() {
    // Decreases the article's chances of being seen
    const seconds = new Date().getTime() / 1080;
    this.featuredNumberTarget.value = Math.round(seconds);
  }

  highlightElement() {
    const card = this.element.querySelector('.card-body');
    card.classList.add('bg-highlighted', 'border-highlighted');
    setTimeout(() => {
      card.classList.remove('bg-highlighted');
    }, 350);
  }

  get articleId() {
    return parseInt(this.data.get('id'), 10);
  }

  set articleId(value) {
    this.data.set('id', value);
  }
}
