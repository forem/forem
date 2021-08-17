import { Controller } from 'stimulus';
import Rails from '@rails/ujs';

export default class UserController extends Controller {
  static targets = ['toolsComponent', 'replace', 'activeSection'];
  static values = { toolsComponentPath: String };

  replacePartial(event) {
    event.preventDefault();
    event.stopPropagation();

    const [, , xhr] = event.detail;

    // if it's one of the grey boxes triggering the action, hide the tools component and replace
    // NOTE: fetchAndOpenTools it also going to dispatch ajax:success, so we make sure this only
    // happens when we want to
    if (event.target.classList.contains('js-action')) {
      this.toolsComponentTarget.classList.add('hidden');
      this.replaceTarget.innerHTML = xhr.responseText;
      this.announceChangedSectionToScreenReader();
    }
  }

  // This is used in those actions where we need to programmatically load the Tools Component
  // eg. EmailsController#ajaxSuccess
  fetchAndOpenTools(event) {
    event.preventDefault();
    event.stopPropagation();

    Rails.ajax({
      url: this.toolsComponentPathValue,
      type: 'get',
      success: (partial) => {
        this.replaceTarget.innerHTML =
          partial.documentElement.getElementsByClassName(
            'js-component',
          )[0].outerHTML;
        this.announceChangedSectionToScreenReader();
      },
    });
  }

  announceChangedSectionToScreenReader() {
    // When the user changes to a new section, we need to announce it to the screen reader,
    // we do that by replacing the content of the `activeSection` target, which is an `aria-live` element,
    // with the hidden title coming from the component server side.
    // NOTE: We can't use Stimulus targets here as it's a dynamic element not present
    // when this controller is attached to the page
    const sectionTitle = this.replaceTarget.querySelector('#section-title');
    if (sectionTitle) {
      this.activeSectionTarget.innerText = sectionTitle.innerText;
    }

    // If we're in one of the inner boxes, we focus on the link in the header (the backlink),
    // otherwise (the outer section), we focus on the grey box itself and focus it
    this.replaceTarget.querySelector('h3 a, .crayons-card.box')?.focus();
  }
}
