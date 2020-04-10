import { Controller } from 'stimulus';

export default class VomitReactionController extends Controller {
  static targets = ['invalid', 'status'];

  // eslint-disable-next-line class-methods-use-this
  updateReaction(id, status) {
    fetch(`/internal/reactions/${id}`, {
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
            // removeReactionDiv(id)
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
    return this.statusTarget.dataset.status;
  }

  get reactableType() {
    return this.statusTarget.dataset.reactable;
  }

  get invalidStatus() {
    return this.invalidTarget.dataset.altstatus;
  }
}
