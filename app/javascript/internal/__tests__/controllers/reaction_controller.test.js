import { Application } from 'stimulus';
import ReactionController from '../../controllers/reaction_controller';

describe('ReactionController', () => {
  beforeEach(() => {
    document.body.innerHTML = `
    <div class="container">
      <div data-controller="reaction" data-reaction-id="1">
        <p>Vomit Reaction for User</p>
        <button type="button" data-reactable="user" data-status="confirmed" data-target="reaction.confirmed" data-action="reaction#reactableUserCheck">
            CONFIRM
        </button>
        <button type="button" data-altstatus="invalid" data-target="reaction.invalid" data-action="reaction#updateReactionInvalid">
            INVALID
        </button>
      </div>
      <hr id="js__reaction__div__hr__1">
      <div data-controller="reaction" data-reaction-id="2">
        <p>Vomit Reaction for Article</p>
        <button type="button" data-reactable="non-user" data-status="confirmed" data-target="reaction.confirmed" data-action="reaction#reactableUserCheck">
            CONFIRM
        </button>
        <button type="button" data-altstatus="invalid" data-target="reaction.invalid" data-action="reaction#updateReactionInvalid">
            INVALID
        </button>
      </div>
      <hr id="js__reaction__div__hr__2">
    </div>
    `;

    const application = Application.start();
    application.register('reaction', ReactionController);
  });

  describe('#updateReaction', () => {
    it('removes both the div containing the button clicked, and the hr that follows', () => {
      const parentDiv = document.querySelector('.container');
      const button = document.querySelectorAll(
        '[data-reaction-id="1"] button',
      )[1];
      button.click();
      console.log(parentDiv.children.length);
    });
  });
});
