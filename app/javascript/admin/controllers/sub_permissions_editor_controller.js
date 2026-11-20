import { Controller } from '@hotwired/stimulus';

export default class SubPermissionsEditorController extends Controller {
  static targets = [
    'form',
    'modeRadio',
    'modeCard',
    'clausesSection',
    'clauseCheckbox',
    'presetButton',
    'summary',
  ];

  static values = {
    summaryNone: String,
    summaryCount: String,
    fullAccessSummary: String,
  };

  connect() {
    this.syncMode();
  }

  syncMode() {
    const isRestricted = this.isRestricted();

    this.modeCardTargets.forEach((card) => {
      const cardRestricted = card.dataset.restricted === '1';
      card.classList.toggle('is-selected', cardRestricted === isRestricted);
    });

    if (this.hasClausesSectionTarget) {
      this.clausesSectionTarget.classList.toggle('is-disabled', !isRestricted);
      this.clausesSectionTarget.setAttribute(
        'aria-disabled',
        String(!isRestricted),
      );
    }

    this.clauseCheckboxTargets.forEach((checkbox) => {
      checkbox.disabled = !isRestricted;
    });

    this.presetButtonTargets.forEach((button) => {
      button.disabled = !isRestricted;
    });

    this.updateSummary();
  }

  selectNone(event) {
    event.preventDefault();
    this.setRestrictedMode(true);
    this.clauseCheckboxTargets.forEach((checkbox) => {
      checkbox.checked = false;
    });
    this.syncMode();
  }

  selectAll(event) {
    event.preventDefault();
    this.setRestrictedMode(true);
    this.clauseCheckboxTargets.forEach((checkbox) => {
      checkbox.checked = true;
    });
    this.syncMode();
  }

  updateSummary() {
    if (!this.hasSummaryTarget) return;

    const isRestricted = this.isRestricted();
    this.summaryTarget.classList.toggle('is-restricted', isRestricted);

    if (!isRestricted) {
      this.summaryTarget.textContent = this.fullAccessSummaryValue;
      return;
    }

    const total = this.clauseCheckboxTargets.length;
    const checked = this.clauseCheckboxTargets.filter(
      (checkbox) => checkbox.checked,
    ).length;

    if (checked === 0) {
      this.summaryTarget.textContent = this.summaryNoneValue.replace(
        '%{total}',
        String(total),
      );
    } else {
      this.summaryTarget.textContent = this.summaryCountValue
        .replace('%{count}', String(checked))
        .replace('%{total}', String(total));
    }
  }

  cancel(event) {
    event.preventDefault();
    if (this.hasFormTarget) {
      this.formTarget.reset();
    }
    this.syncMode();
    if (this.element.tagName === 'DETAILS') {
      this.element.open = false;
    }
  }

  setRestrictedMode(restricted) {
    const targetValue = restricted ? '1' : '0';
    this.modeRadioTargets.forEach((radio) => {
      radio.checked = radio.value === targetValue;
    });
  }

  isRestricted() {
    return this.modeRadioTargets.some(
      (radio) => radio.checked && radio.value === '1',
    );
  }
}
