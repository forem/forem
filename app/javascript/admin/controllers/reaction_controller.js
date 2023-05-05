import { Controller } from '@hotwired/stimulus';
import { addSnackbarItem } from '../../Snackbar';

export default class ReactionController extends Controller {
  static targets = ['invalid', 'confirmed'];
  static values = {
    id: Number,
    url: String,
  };

  updateReaction(status, removeElement) {
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
            addSnackbarItem({
              message: 'Flag status has been changed successfully',
              addCloseButton: false,
            });

            if(removeElement === true){
              this.element.remove();
              document.getElementById(`js__reaction__div__hr__${id}`).remove();
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
    const {removeElement} = event.target.dataset;
    this.updateReaction(this.invalidStatus, removeElement);
  }

  updateReactionConfirmed(event) {
    const {removeElement} = event.target.dataset;
    this.updateReaction(this.confirmedStatus, removeElement);
  }

  reactableUserCheck() {
    if (this.reactableType === 'user') {
      if (
        window.confirm('You are confirming a User flag reaction; are you sure?')
      ) {
        this.updateReaction(this.confirmedStatus, true);
      }
    } else {
      this.updateReaction(this.confirmedStatus, true);
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
