import { INTERACTIVE_ELEMENTS_QUERY } from '@utilities/dropdownUtils';
import {
  showWindowModal,
  closeWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';

const expandSearchButton = document.getElementById('expand-search-btn');
const expandFilterButton = document.getElementById('expand-filter-btn');
const searchSection = document.getElementById('search-users');
const filterSection = document.getElementById('filter-users');

/**
 * Sets up the expand/collapse behavior used on the small-screen layout for Search and Filter form sections
 */
const initializeExpandingSections = () => {
  expandSearchButton?.addEventListener('click', () => {
    collapseControlsSection({
      section: filterSection,
      triggerButton: expandFilterButton,
    });

    expandOrCollapseControlsSection({
      section: searchSection,
      triggerButton: expandSearchButton,
    });
  });

  expandFilterButton?.addEventListener('click', () => {
    collapseControlsSection({
      section: searchSection,
      triggerButton: expandSearchButton,
    });

    expandOrCollapseControlsSection({
      section: filterSection,
      triggerButton: expandFilterButton,
    });
  });
};

/**
 * Ensures the given controls section is closed.
 *
 * @param {HTMLElement} section The controls section to be closed
 * @param {HTMLElement} triggerButton The button responsible for opening and closing the section
 */
const collapseControlsSection = ({ section, triggerButton }) => {
  section?.classList.add('hidden');
  triggerButton?.setAttribute('aria-expanded', false);
};

/**
 * Expands the given section if it's currently closed. Otherwise closes it.
 *
 * @param {HTMLElement} section The controls section to be toggled
 * @param {HTMLElement} triggerButton The button responsible for opening and closing the section
 */
const expandOrCollapseControlsSection = ({ section, triggerButton }) => {
  const isExpanded = triggerButton?.getAttribute('aria-expanded') === 'true';
  if (isExpanded) {
    section?.classList.add('hidden');
    triggerButton?.setAttribute('aria-expanded', false);
  } else {
    section?.classList.remove('hidden');
    triggerButton?.setAttribute('aria-expanded', true);
    sendFocusToFirstInteractiveItem(section);
  }
};

/**
 * Helps provide a more seamless search/filter experience by sending keyboard focus directly to a newly expanded form
 *
 * @param {HTMLElement} element The element to send focus into (e.g. search form)
 */
const sendFocusToFirstInteractiveItem = (element) => {
  element?.querySelector(INTERACTIVE_ELEMENTS_QUERY)?.focus();
};

/**
 * Ensures that search/filter button indicators in mobile view stay in sync with the user's current selections.
 * Indicators may become visible when a search term or filter option is input (although they are only displayed via CSS
 * when the section is collapsed).
 */
const initializeSectionIndicators = () => {
  document
    .getElementById('search-small')
    ?.addEventListener('change', ({ target: { value } }) => {
      toggleIndicator({
        indicator: expandSearchButton?.querySelector('.search-indicator'),
        value,
      });
    });

  document
    .getElementById('filter-small')
    ?.addEventListener('change', ({ target: { value } }) => {
      toggleIndicator({
        indicator: expandFilterButton?.querySelector('.search-indicator'),
        value,
      });
    });
};

/**
 * Helper function to show or hide an indicator depending if a value is selected or not
 *
 * @param {Object} args
 * @param {string} args.value The current input value
 * @param {HTMLElement} args.indicator The HTML indicator element
 */
const toggleIndicator = ({ value, indicator }) => {
  if (value !== '') {
    indicator?.classList.remove('hidden');
  } else {
    indicator?.classList.add('hidden');
  }
};

/**
 * Controls the triggering of the filters popover modal
 */
const initializeFilterPopoverButtons = () => {
  document.querySelectorAll('.js-open-filter-modal-btn').forEach((button) => {
    button.addEventListener('click', () => {
      showWindowModal({
        contentSelector: '.js-filters-modal',
        showHeader: false,
        sheet: true,
        sheetAlign: 'right',
        size: 'small',
        onOpen: () => {
          document
            .querySelector(`#${WINDOW_MODAL_ID} .js-filter-modal-cancel-btn`)
            .addEventListener('click', closeWindowModal);
        },
      });
    });
  });
};

initializeExpandingSections();
initializeSectionIndicators();
initializeFilterPopoverButtons();
