/* eslint-disable no-alert */
import { Controller } from 'stimulus';

export default class ReactionController extends Controller {
  static targets = ['invalid', 'confirmed'];

  // eslint-disable-next-line class-methods-use-this
  /* eslint no-alert: "error" */
  updateReaction(id, status) {
    fetch(`/admin/reactions/${id}`, {
      method: 'PATCH',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          .content,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        id,
        status,
      }),
      credentials: 'same-origin',
    }).then((response) =>
      response
        .json()
        .then((json) => {
          if (json.outcome === 'Success') {
            this.element.remove();
            document.getElementById(`js__reaction__div__hr__${id}`).remove();
          } else {
            alert(json.error);
          }
        })
        .catch((error) => {
          alert(error);
        }),
    );
  }

  updateReactionInvalid() {
    this.updateReaction(this.reactionId, this.invalidStatus);
  }

  updateReactionConfirmed() {
    this.updateReaction(this.reactionId, this.confirmedStatus);
  }

  reactableUserCheck() {
    if (this.reactableType === 'user') {
      // eslint-disable-next-line no-restricted-globals
      if (confirm('You are confirming a User vomit reaction; are you sure?')) {
        this.updateReaction(this.reactionId, this.confirmedStatus);
      }
    } else {
      this.updateReaction(this.reactionId, this.confirmedStatus);
    }
  }

  get reactionId() {
    return parseInt(this.data.get('id'), 10);
  }

  get confirmedStatus() {
    return this.confirmedTarget.dataset.status;
  }

  get reactableType() {
    return this.confirmedTarget.dataset.reactable;
  }

  get invalidStatus() {
    return this.invalidTarget.dataset.altstatus;
  }
}
