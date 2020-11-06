import { Application } from 'stimulus';
import ConfigController from '../../controllers/config_controller';

describe('ConfigController', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="config">
      <button data-action="click->config#activateEmailAuthModal">
        Disable
      </button>
      <div data-target="config.configModalAnchor"></div>
    </div>`;

    global.scrollTo = jest.fn();

    const application = Application.start();
    application.register('config', ConfigController);
  });

  describe('#activateEmailAuthModal', () => {
    it('builds and adds a Modal to the page', () => {
      const button = document.querySelector('button');
      const modalAnchor = document.querySelector(
        '[data-target="config.configModalAnchor"]',
      );

      button.click();

      expect(
        modalAnchor.firstElementChild.classList.contains('crayons-modal'),
      ).toBe(true);
    });
  });
});
