import { Controller } from '@hotwired/stimulus';

export default class ReactionController extends Controller {
  static targets = ['invalid', 'confirmed'];
  static values = {
    id: Number,
    url: String,
  };

  updateReaction(status, removeElement = true) {
    const id = this.idValue;

    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          ?.content,
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
            if (removeElement === true) {
              this.element.remove();
              document.getElementById(`js__reaction__div__hr__${id}`).remove();
            } else {
              // TODO (#19531): Code Optimisation- avoid reloading entire page for this minor item change.
              // Once the status of item gets updated in admin/content_manager/articles/<article-id>, we
              // reload the entire page here. Ideally we should only re-render the item which was updated
              // but given the case that this feature is used by internal-team, for now its fine.
              location.reload();
            }
          } else {
            window.alert(json.error);
          }
        })
        .catch((error) => {
          window.alert(error);
        }),
    );
  }

  updateReactionInvalid(event) {
    const { removeElement } = event.target.dataset;
    this.updateReaction(this.invalidStatus, removeElement);
  }

  updateReactionConfirmed(event) {
    const { removeElement } = event.target.dataset;
    this.updateReaction(this.confirmedStatus, removeElement);
  }

  reactableUserCheck() {
    if (this.reactableType === 'user') {
      if (
        window.confirm('You are confirming a User flag reaction; are you sure?')
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
