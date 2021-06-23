import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

// NOTE: [@rhymes] there's a bit of coupling going on between this component
// (see show.html.erb) and the ViewComponent used server side. Need to clean that.
export default class UserController extends Controller {
  static targets = ['emailComponent', 'toolsComponent'];
  static values = { emailComponentPath: String, toolsComponentPath: String };

  openEmail(event) {
    event.preventDefault();

    Rails.ajax({
      url: this.emailComponentPathValue,
      type: 'get',
      success: (partial) => {
        this.toolsComponentTarget.classList.add('hidden');

        const partialHTML =
          partial.documentElement.getElementsByClassName('js-component')[0]
            .outerHTML;
        this.toolsComponentTarget.insertAdjacentHTML('afterend', partialHTML);

        this.toolsComponentTarget.remove();
      },
    });
  }

  closeEmail(event) {
    event.preventDefault();

    Rails.ajax({
      url: this.toolsComponentPathValue,
      type: 'get',
      success: (partial) => {
        this.emailComponentTarget.classList.add('hidden');

        const partialHTML =
          partial.documentElement.getElementsByClassName('js-component')[0]
            .outerHTML;
        this.emailComponentTarget.insertAdjacentHTML('afterend', partialHTML);

        this.emailComponentTarget.remove();
      },
    });
  }
}
