import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

export default class UserController extends Controller {
  static targets = ['toolsComponent', 'replace'];
  static values = { toolsComponentPath: String };

  replacePartial(event) {
    event.preventDefault();
    event.stopPropagation();

    const [, , xhr] = event.detail;

    // if it's one of the grey boxes triggering the action, hide the tools component
    if (event.target.classList.contains('js-action')) {
      this.toolsComponentTarget.classList.add('hidden');
    }

    this.replaceTarget.innerHTML = xhr.responseText;
  }

  // This is used in those actions where we need to programmatically load the Tools Component
  // eg. EmailsController#ajaxSuccess
  fetchAndOpenTools(event) {
    event.preventDefault();

    Rails.ajax({
      url: this.toolsComponentPathValue,
      type: 'get',
      success: (partial) => {
        this.replaceTarget.innerHTML =
          partial.documentElement.getElementsByClassName(
            'js-component',
          )[0].outerHTML;
      },
    });
  }
}
