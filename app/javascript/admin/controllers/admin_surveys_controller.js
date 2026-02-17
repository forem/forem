import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
    static targets = ['pollContainer', 'pollTemplate', 'poll', 'optionsContainer'];

    connect() {
        console.log('AdminSurveys connected!');
        this.updatePollsVisibility();
    }

    addPoll(event) {
        if (event) event.preventDefault();
        console.log('AdminSurveys: addPoll called');

        if (!this.hasPollTemplateTarget || !this.hasPollContainerTarget) {
            console.error('AdminSurveys: Missing targets');
            return;
        }

        const template = this.pollTemplateTarget.innerHTML;
        const newIndex = new Date().getTime();
        const html = template.replace(/NEW_RECORD/g, newIndex);

        this.pollContainerTarget.insertAdjacentHTML('beforeend', html);
        this.updatePollsVisibility();
    }

    removePoll(event) {
        if (event) event.preventDefault();
        console.log('AdminSurveys: removePoll called');
        const poll = event.target.closest('[data-admin-surveys-target="poll"]');
        if (!poll) return;

        const destroyField = poll.querySelector('.destroy-poll-field');
        if (destroyField) {
            destroyField.value = '1';
            poll.style.display = 'none';
        } else {
            poll.remove();
        }
    }

    handleTypeChange(event) {
        const poll = event.target.closest('[data-admin-surveys-target="poll"]');
        if (poll) this.updateVisibility(poll);
    }

    updatePollsVisibility() {
        if (this.hasPollTargets) {
            this.pollTargets.forEach(poll => this.updateVisibility(poll));
        }
    }

    updateVisibility(poll) {
        const typeSelect = poll.querySelector('.poll-type-select');
        if (!typeSelect) return;

        const type = typeSelect.value;
        const optionsSection = poll.querySelector('.options-section');
        const scaleSection = poll.querySelector('.scale-section');

        if (type === 'text_input') {
            if (optionsSection) optionsSection.style.display = 'none';
            if (scaleSection) scaleSection.style.display = 'none';
        } else if (type === 'scale') {
            if (optionsSection) optionsSection.style.display = 'none';
            if (scaleSection) scaleSection.style.display = 'block';
        } else {
            if (optionsSection) optionsSection.style.display = 'block';
            if (scaleSection) scaleSection.style.display = 'none';
        }
    }

    addOption(event) {
        if (event) event.preventDefault();
        console.log('AdminSurveys: addOption called');
        const poll = event.target.closest('[data-admin-surveys-target="poll"]');
        if (!poll) return;

        const container = this.optionsContainerTargets.find(c => poll.contains(c));
        if (!container) return;

        const pollIndex = poll.dataset.index;
        const optionIndex = new Date().getTime();

        const html = `
      <div class="option-fields flex gap-2 mb-2 items-start" data-admin-surveys-target="optionField">
        <div class="flex-1">
          <input type="text" name="survey[polls_attributes][${pollIndex}][poll_options_attributes][${optionIndex}][markdown]" class="crayons-textfield" placeholder="Option text" required>
        </div>
        <div class="flex-1">
          <input type="text" name="survey[polls_attributes][${pollIndex}][poll_options_attributes][${optionIndex}][supplementary_text]" class="crayons-textfield" placeholder="Supplementary text (optional)">
        </div>
        <button type="button" class="crayons-btn crayons-btn--ghost crayons-btn--icon" data-action="click->admin-surveys#removeOption">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="crayons-icon"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
        </button>
      </div>
    `;
        container.insertAdjacentHTML('beforeend', html);
    }

    removeOption(event) {
        if (event) event.preventDefault();
        const field = event.target.closest('[data-admin-surveys-target="optionField"]');
        if (field) field.remove();
    }
}
