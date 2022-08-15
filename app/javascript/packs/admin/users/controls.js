import { initializeFiltersModal } from './filtersModal';
import { INTERACTIVE_ELEMENTS_QUERY } from '@utilities/dropdownUtils';

const expandSearchButton = document.getElementById('expand-search-btn');
const searchSection = document.getElementById('search-users');

/**
 * Sets up the expand/collapse behavior used on the small-screen layout for Search form section
 */
const initializeExpandingSections = () => {
  expandSearchButton?.addEventListener('click', () => {
    expandOrCollapseControlsSection({
      section: searchSection,
      triggerButton: expandSearchButton,
    });
  });
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
 * Helps provide a more seamless search experience by sending keyboard focus directly to the newly expanded form
 *
 * @param {HTMLElement} element The element to send focus into (e.g. search form)
 */
const sendFocusToFirstInteractiveItem = (element) => {
  element?.querySelector(INTERACTIVE_ELEMENTS_QUERY)?.focus();
};

/**
 * Ensures that search button indicator in mobile view stays in sync with the user's current selections.
 * Indicators may become visible when a search term is input (although it is only displayed via CSS
 * when the section is collapsed).
 */
const initializeSearchIndicator = () => {
  document
    .getElementById('search-small')
    ?.addEventListener('change', ({ target: { value } }) => {
      toggleIndicator({
        indicator: expandSearchButton?.querySelector('.search-indicator'),
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

initializeExpandingSections();
initializeSearchIndicator();
initializeFiltersModal();
