import { h, render } from 'preact';
import { TagAutocompleteSelection } from '../../article-form/components/TagAutocompleteSelection';
import { TagAutocompleteOption } from '../../article-form/components/TagAutocompleteOption';
import { MultiSelectAutocomplete } from '@crayons';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { fetchTags } from '@utilities/search';
import { getCsrfToken } from '@utilities/getUserDataAndCsrfToken';

window.getCsrfToken = getCsrfToken;

function adjustCreditRange(event) {
  const {
    target: { value, name, form },
  } = event;

  if (name === 'user[credit_action]') {
    const creditAmount = form['user[credit_amount]'];

    if (value === 'Add') {
      if (creditAmount.getAttribute('data-old-max')) {
        creditAmount.setAttribute(
          'max',
          creditAmount.getAttribute('data-old-max'),
        );
      }
    } else {
      creditAmount.setAttribute(
        'data-old-max',
        creditAmount.getAttribute('max'),
      );
      creditAmount.setAttribute('max', creditAmount.dataset.unspentCredits);
    }
  }
}

function enableEvents(key, enabled = true) {
  if (!eventMap.has(key)) {
    return;
  }

  const [eventType, handler] = eventMap.get(key);

  modalContainer[enabled ? 'addEventListener' : 'removeEventListener'](
    eventType,
    handler,
  );
}

function getModalContents(modalContentSelector) {
  if (!modalContents.has(modalContentSelector)) {
    const modelContentElement = document.querySelector(modalContentSelector);
    const modalContent = modelContentElement.innerHTML;

    // Remove the element from the DOM to avoid duplicate ID errors in regards to a11y.
    modelContentElement.remove();
    modalContents.set(modalContentSelector, modalContent);
  }

  return modalContents.get(modalContentSelector);
}

let AdminModal;
const modalContents = new Map();

// Keys are the modalContentSelector data attribute on a button that opens a modal.
// Values are a tuple containing the event type and handler to add to the modal container.
const eventMap = new Map();

eventMap.set('#adjust-balance', ['change', adjustCreditRange]);

// Append an empty div to the end of the document so that is does not affect the layout.
const modalContainer = document.createElement('div');
document.body.appendChild(modalContainer);

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  const { dataset } = event.target;

  if (!Object.prototype.hasOwnProperty.call(dataset, 'modalTrigger')) {
    // We're not trying to trigger a modal.
    return;
  }

  event.preventDefault();

  // Only load Preact if we haven't already.
  if (!AdminModal) {
    AdminModal = (await import('@crayons/Modal/Modal')).Modal;
  }

  const { modalTitle, modalSize, modalContentSelector } = dataset;

  enableEvents(modalContentSelector);

  render(
    <AdminModal
      title={modalTitle}
      size={modalSize}
      onClose={() => {
        render(null, modalContainer);
        enableEvents(modalContentSelector, false);
      }}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: getModalContents(modalContentSelector),
        }}
      />
    </AdminModal>,
    modalContainer,
  );
};

document.body.addEventListener('click', openModal);

const tagsRoot = document.getElementById('tag-moderation-container');

// Normally, Preact can diff the server-side rendered DOM to hydrate the client-side rendered DOM,
// but in this case, the MultiSelectAutocomplete component has a lot of markup, so I opted for
// just a stylized input which is why innerHTML is used.
tagsRoot.innerHTML = '';

render(
  <MultiSelectAutocomplete
    fetchSuggestions={fetchTags}
    labelText="Assign tags"
    maxSelections={Math.MAX_VALUE}
    placeholder="Add a tag..."
    showLabel={false}
    SuggestionTemplate={TagAutocompleteOption}
    SelectionTemplate={TagAutocompleteSelection}
  />,
  tagsRoot,
);
