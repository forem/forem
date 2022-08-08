import {
  showWindowModal,
  closeWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';

const updateDateRangeFilterIndicator = ({ startDate, endDate, indicator }) => {
  const hasValues = startDate || endDate;
  if (hasValues) {
    indicator.classList.remove('hidden');
  } else {
    indicator.classList.add('hidden');
  }
};

/**
 * Some sections require the Preact DateRangePicker.
 * This function imports the required packages and adds the pickers to the modal.
 */
const initializeDateRangePickers = async () => {
  const joiningRangeContainer = document.querySelector(
    `#${WINDOW_MODAL_ID} .js-joining-date-range`,
  );

  const joiningDateIndicator = document.querySelector(
    `#${WINDOW_MODAL_ID} .js-filtered-indicator-joining-date`,
  );

  const [
    { render, h },
    { DateRangePicker, ALL_PRESET_RANGES },
    { default: moment },
  ] = await Promise.all([
    import('preact'),
    import('@crayons'),
    import('moment'),
  ]);

  const { defaultStart, defaultEnd, defaultDatesFormat, earliestDate } =
    joiningRangeContainer.dataset;

  render(
    <DateRangePicker
      startDateId="joining_start"
      endDateId="joining_end"
      startDateAriaLabel="Joined after"
      endDateAriaLabel="Joined before"
      onDatesChanged={(dates) =>
        updateDateRangeFilterIndicator({
          ...dates,
          indicator: joiningDateIndicator,
        })
      }
      defaultStartDate={
        defaultStart && moment(defaultStart, defaultDatesFormat).toDate()
      }
      defaultEndDate={
        defaultEnd && moment(defaultEnd, defaultDatesFormat).toDate()
      }
      minStartDate={new Date(earliestDate)}
      maxEndDate={new Date()}
      presetRanges={ALL_PRESET_RANGES}
    />,
    joiningRangeContainer,
  );
};

/**
 * Details panels will automatically expand on click when required.
 * We want to make sure only _one_ panel is expanded at any given time,
 * so here we collapse any which don't match the click's target
 */
const initializeFilterDetailsToggles = () => {
  const allDetailsPanels = document.querySelectorAll(
    `#${WINDOW_MODAL_ID} details`,
  );
  allDetailsPanels?.forEach((panel) => {
    panel.addEventListener('toggle', ({ target }) => {
      // If the panel is closing, do nothing
      if (target.getAttribute('open') === null) {
        return;
      }

      const {
        dataset: { section: clickedSection },
      } = target;

      document
        .querySelectorAll(`#${WINDOW_MODAL_ID} details[open]`)
        .forEach((openPanel) => {
          if (openPanel.dataset?.section !== clickedSection) {
            openPanel.removeAttribute('open');
          }
        });
    });
  });
};

/**
 * Each filter section has a "Clear filter" button, visible only if one of its values is currently selected.
 * There is also a "Clear all filters" button.
 * We use a single listener on the modal to handle all clear button clicks.
 */
const initializeFilterClearButtons = () => {
  document
    .getElementById(WINDOW_MODAL_ID)
    .addEventListener('click', ({ target }) => {
      if (target.classList.contains('js-clear-all-filters-btn')) {
        // Execute the related "clear" action for all checkbox groups
        document
          .querySelectorAll(`#${WINDOW_MODAL_ID} .js-clear-filter-btn`)
          .forEach((button) => {
            const {
              dataset: { checkboxFieldsetSelector },
            } = button;

            clearAllCheckboxesInFieldset(
              document.querySelector(
                `#${WINDOW_MODAL_ID} ${checkboxFieldsetSelector}`,
              ),
            );
          });

        // Clear the date range picker
        document.querySelector(`#${WINDOW_MODAL_ID} #joining_start`).value = '';
        document.querySelector(`#${WINDOW_MODAL_ID} #joining_end`).value = '';
      }

      if (!target.classList.contains('js-clear-filter-btn')) {
        return;
      }

      const {
        dataset: { checkboxFieldsetSelector },
      } = target;

      if (checkboxFieldsetSelector) {
        clearAllCheckboxesInFieldset(
          document.querySelector(
            `#${WINDOW_MODAL_ID} ${checkboxFieldsetSelector}`,
          ),
        );
      }
    });

  // Set up change listeners on each checkbox group so we can toggle the button/status indicator visibility
  document.querySelectorAll('.js-clear-filter-btn').forEach((button) => {
    const { checkboxFieldsetSelector, filterIndicatorSelector } =
      button.dataset;

    document
      .querySelector(`#${WINDOW_MODAL_ID} ${checkboxFieldsetSelector}`)
      ?.addEventListener('change', ({ currentTarget }) => {
        const anyFiltersApplied =
          areAnyCheckboxesInFieldsetChecked(currentTarget);
        const relatedIndicator = document.querySelector(
          `#${WINDOW_MODAL_ID} ${filterIndicatorSelector}`,
        );

        if (anyFiltersApplied) {
          button.classList.remove('hidden');
          relatedIndicator.classList.remove('hidden');
        } else {
          button.classList.add('hidden');
          relatedIndicator.classList.add('hidden');
        }
      });
  });
};

const areAnyCheckboxesInFieldsetChecked = (fieldset) =>
  Array.from(fieldset.querySelectorAll("input[type='checkbox']")).some(
    (checkbox) => checkbox.checked,
  );

const clearAllCheckboxesInFieldset = (fieldset) => {
  fieldset
    .querySelectorAll("input[type='checkbox']")
    .forEach((checkbox) => (checkbox.checked = false));
  const event = new Event('change');

  // Trigger change event to make sure "clear filter" button updates
  fieldset.dispatchEvent(event);
};

const initializeModalCloseButton = () =>
  document
    .querySelector(`#${WINDOW_MODAL_ID} .js-filter-modal-cancel-btn`)
    .addEventListener('click', () => closeWindowModal());

/**
 * Roles list is dynamically expanded and collapsed by this toggle button
 */
const initializeShowHideRoles = () => {
  document
    .querySelector('.js-expand-roles-btn')
    .addEventListener('click', ({ target }) => {
      const initiallyHiddenRoles = document.querySelector(
        '.js-initially-hidden-roles',
      );

      const isCurrentlyHidden =
        initiallyHiddenRoles.classList.contains('hidden');

      initiallyHiddenRoles.classList.toggle('hidden');
      target.setAttribute('aria-pressed', isCurrentlyHidden ? 'true' : 'false');
      target.innerText = `See ${isCurrentlyHidden ? 'fewer' : 'more'} roles`;
    });
};

let cachedFiltersModalContent;

export const initializeFiltersModal = () => {
  document.querySelectorAll('.js-open-filter-modal-btn').forEach((button) => {
    button.addEventListener('click', () => {
      // We need to remove the originally "hidden" modal content from the page to prevent conflicts with input IDs
      if (!cachedFiltersModalContent) {
        const filterModalContent = document.querySelector('.js-filters-modal');
        cachedFiltersModalContent = filterModalContent.innerHTML;
        filterModalContent.remove();
      }

      showWindowModal({
        modalContent: cachedFiltersModalContent,
        showHeader: false,
        sheet: true,
        sheetAlign: 'right',
        size: 'small',
        allowOverflow: true,
        onOpen: () => {
          initializeModalCloseButton();
          initializeFilterDetailsToggles();
          initializeShowHideRoles();
          initializeFilterClearButtons();
          initializeDateRangePickers();
        },
      });
    });
  });
};
