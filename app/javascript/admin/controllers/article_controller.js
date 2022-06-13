import { Controller } from '@hotwired/stimulus';

export default class ArticleController extends Controller {
  static classes = ['bgHighlighted', 'borderHighlighted'];
  static targets = [
    'featuredNumber',
    'cardBody',
    'pinnedCheckbox',
  ];
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

  async pinArticle(event) {
    const pinArticleForm = event.target;
    // We dont want to submit the pin form here.
    event.preventDefault();
    const response = await fetch(this.pinPathValue, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          ?.content,
      },
      credentials: 'same-origin',
    });

    if (response.ok) {
      const pinnedArticle = await response.json();

      // only show the modal if we're not re-pinning the current pin
      if (pinnedArticle.id !== this.idValue) {
        // By dispatching this custom event, we communicate with
        // `ArticlePinnedModalController`, responsible to display the modal and
        // determine the final state of the checkbox, depending on which action
        // the user follows up with (ie. confirming the pin or dismissing)
        // This technique is a good way to separate behavior and have Stimulus
        // controllers talk with each other.
        // See https://fullstackheroes.com/stimulusjs/create-custom-events/
        document.dispatchEvent(
          new CustomEvent('article-pinned-modal:open', {
            detail: {
              article: pinnedArticle,
              pinArticleForm,
            },
          }),
        );
      } else {
        pinArticleForm.submit();
      }
    } else if (response.status === 404) {
      // if there is no pinned article, it means we can go ahead and pin this one
      pinArticleForm.submit();
    }
  }

  async unpinArticle(event) {
    const unpinArticleForm = event.target;
    // We dont want to submit the pin form here.
    event.preventDefault();

    unpinArticleForm.submit();
  }

  ajaxSuccess(event) {
    // Replace the current Article HTML with the HTML sent by the server
    const newArticle = document.createElement('div');

    const [, , xhr] = event.detail;
    newArticle.innerHTML = xhr.responseText;

    this.element.innerHTML = newArticle.querySelector(
      '.js-individual-article',
    ).innerHTML;
  }
}
