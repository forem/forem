import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

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
      },
    });
  }

  closeEmail(event) {
    event.preventDefault();

    Rails.ajax({
      url: this.admin_user_toolsValue,
      type: 'get',
      success: (partial) => {
        this.emailComponent.classList.add('hidden');

        const partialHTML =
          partial.documentElement.getElementsByClassName('js-component')[0]
            .outerHTML;
        this.toolsComponentTarget.insertAdjacentHTML('afterend', partialHTML);
      },
    });
  }
}
