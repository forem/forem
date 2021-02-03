import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class ReactionController extends Controller {
  static targets = ['invalid', 'confirmed'];
  static values = {
    id: Number,
    url: String,
  };

  updateReaction(status) {
    const id = this.idValue;

    fetch(this.urlValue, {
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
            window.alert(json.error);
          }
        })
        .catch((error) => {
          window.alert(error);
        }),
    );
  }

  updateReactionInvalid() {
    this.updateReaction(this.invalidStatus);
  }

  updateReactionConfirmed() {
    this.updateReaction(this.confirmedStatus);
  }

  reactableUserCheck() {
    if (this.reactableType === 'user') {
      if (
        window.confirm(
          'You are confirming a User vomit reaction; are you sure?',
        )
      ) {
        this.updateReaction(this.confirmedStatus);
      }
    } else {
      this.updateReaction(this.confirmedStatus);
    }
  }

  get reactableType() {
    return this.confirmedTarget.dataset.reactable;
  }

  get confirmedStatus() {
    return this.confirmedTarget.dataset.status;
  }

  get invalidStatus() {
    return this.invalidTarget.dataset.altstatus;
  }
}
