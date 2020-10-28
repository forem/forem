import { Application } from 'stimulus';
import ConfigController from '../../controllers/config_controller';

describe('ConfigController', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="config">
      <button data-action="click->config#activateEmailAuthModal">
        Disable
      </button>
      <div class="admin-config-modal-anchor"></div>
    </div>`;

    const application = Application.start();
    application.register('config', ConfigController);
  });

  describe('#activateEmailAuthModal', () => {
    it('builds and adds a Modal to the page', () => {
      const button = document.querySelectorAll('button')[0];
      const modalAnchor = document.querySelector('.admin-config-modal-anchor');

      button.click();

      expect(
        modalAnchor.firstChild.classList.contains('crayons-modal'),
      ).toBe(true);
    });
  });
});