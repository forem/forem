import { Application } from '@hotwired/stimulus';
import ConfigController from '../../controllers/config_controller';

describe('ConfigController', () => {
  beforeEach(() => {
    document.body.innerHTML = `
    <div data-controller="config">
      <button data-action="click->config#activateEmailAuthModal">
        Disable
      </button>
      <div data-config-target="configModalAnchor"></div>
    </div>`;

    global.scrollTo = jest.fn();

    const application = Application.start();
    application.register('config', ConfigController);
  });

  describe('#activateEmailAuthModal', () => {
    it('builds and adds a Modal to the page', () => {
      const button = document.getElementsByTagName('button')[0];
      const modalAnchor = document.querySelector(
        '[data-config-target="configModalAnchor"]',
      );

      button.click();

      expect(
        modalAnchor.firstElementChild.classList.contains('crayons-modal'),
      ).toBe(true);
    });
  });
});
