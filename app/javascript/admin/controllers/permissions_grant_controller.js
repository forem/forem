import { Controller } from '@hotwired/stimulus';

export default class PermissionsGrantController extends Controller {
  static targets = [
    'roleSelect',
    'panel',
    'panelTitle',
    'clausesSection',
    'clausesList',
    'baselineHint',
    'summary',
    'modeRadio',
    'modeCard',
  ];

  static values = {
    config: Object,
    summaryFull: String,
    summaryRestrictedNone: String,
    summaryRestrictedCount: String,
  };

  connect() {
    this.handleRoleChange();
  }

  handleRoleChange() {
    const selectedValue = this.roleSelectTarget.value || '';
    const [roleName, resourceType] = selectedValue.split('|');
    const resourceConfig =
      roleName === 'single_resource_admin' && resourceType
        ? this.configValue[resourceType]
        : null;

    if (!resourceConfig) {
      this.resetPanel();
      return;
    }

    this.renderClauses(resourceConfig);
    this.panelTitleTarget.textContent = resourceConfig.title;

    if (resourceConfig.baseline_hint) {
      this.baselineHintTarget.textContent = resourceConfig.baseline_hint;
      this.baselineHintTarget.hidden = false;
    } else {
      this.baselineHintTarget.textContent = '';
      this.baselineHintTarget.hidden = true;
    }

    this.setRestrictedMode(false);
    this.panelTarget.hidden = false;
    this.syncMode();
  }

  syncMode() {
    const isRestricted = this.isRestricted();

    this.modeCardTargets.forEach((card) => {
      const cardRestricted = card.dataset.restricted === '1';
      card.classList.toggle('is-selected', cardRestricted === isRestricted);
    });

    this.clausesSectionTarget.hidden = !isRestricted;
    this.clauseCheckboxes().forEach((checkbox) => {
      checkbox.disabled = !isRestricted;
    });

    this.updateSummary();
  }

  selectNone(event) {
    event.preventDefault();
    this.setRestrictedMode(true);
    this.clauseCheckboxes().forEach((checkbox) => {
      checkbox.checked = false;
    });
    this.syncMode();
  }

  selectAll(event) {
    event.preventDefault();
    this.setRestrictedMode(true);
    this.clauseCheckboxes().forEach((checkbox) => {
      checkbox.checked = true;
    });
    this.syncMode();
  }

  updateSummary() {
    if (!this.hasSummaryTarget) return;

    const isRestricted = this.isRestricted();
    this.summaryTarget.classList.toggle('is-restricted', isRestricted);

    if (!isRestricted) {
      this.summaryTarget.textContent = this.summaryFullValue;
      return;
    }

    const checkboxes = this.clauseCheckboxes();
    const total = checkboxes.length;
    const checked = checkboxes.filter((checkbox) => checkbox.checked).length;

    if (checked === 0) {
      this.summaryTarget.textContent = this.summaryRestrictedNoneValue;
    } else {
      this.summaryTarget.textContent = this.summaryRestrictedCountValue
        .replace('%{count}', String(checked))
        .replace('%{total}', String(total));
    }
  }

  resetPanel() {
    this.panelTarget.hidden = true;
    this.clausesListTarget.textContent = '';
    this.setRestrictedMode(false);
    this.clausesSectionTarget.hidden = true;
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

  clauseCheckboxes() {
    return Array.from(
      this.clausesListTarget.querySelectorAll('input[type="checkbox"]'),
    );
  }

  renderClauses(resourceConfig) {
    this.clausesListTarget.textContent = '';

    resourceConfig.clauses.forEach((clause) => {
      const label = document.createElement('label');
      label.className = 'admin-perm-clause';

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.name = 'allow[]';
      checkbox.value = clause.key;
      checkbox.className = 'crayons-checkbox';
      checkbox.id = `grant_allow_${resourceConfig.resource_type}_${clause.key}`;
      checkbox.dataset.action = 'change->permissions-grant#updateSummary';

      const body = document.createElement('span');
      body.className = 'admin-perm-clause__body';

      const title = document.createElement('span');
      title.className = 'admin-perm-clause__title';
      title.textContent = clause.label;
      body.appendChild(title);

      if (clause.description) {
        const desc = document.createElement('span');
        desc.className = 'admin-perm-clause__desc';
        desc.textContent = clause.description;
        body.appendChild(desc);
      }

      label.appendChild(checkbox);
      label.appendChild(body);
      this.clausesListTarget.appendChild(label);
    });
  }
}
