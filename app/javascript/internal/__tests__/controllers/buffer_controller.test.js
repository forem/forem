import { Application } from 'stimulus';
import BufferController from '../../controllers/buffer_controller';
import '../../__mocks__/mutationObserver';

describe('BufferController', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="buffer">
      <h2 data-target="buffer.header"></h2>
      <button data-action="buffer#tagBufferUpdateConfirmed"></button>
      <button data-action="buffer#tagBufferUpdateDismissed"></button>
      <button data-action="buffer#highlightElement"></button>
    </div>`;

    const application = Application.start();
    application.register('buffer', BufferController);
  });

  describe('#tagBufferUpdateConfirmed', () => {
    it('adds a badge to the header', () => {
      const button = document.querySelectorAll('button')[0];
      const header = document.querySelector('h2');

      button.click();

      expect(header.firstChild.textContent).toMatch(/Confirm/);
    });
  });

  describe('#tagBufferUpdateDismissed', () => {
    it('adds a badge to the header', () => {
      const button = document.querySelectorAll('button')[1];
      const header = document.querySelector('h2');

      button.click();

      expect(header.firstChild.textContent).toMatch(/Dismiss/);
    });
  });

  describe('#highlightElement', () => {
    it('adds a class to the controller element', () => {
      const button = document.querySelectorAll('button')[2];
      const element = document.querySelector("[data-controller='buffer']");

      button.click();

      expect(
        element.classList.contains('bg-highlighted', 'border-highlighted'),
      ).toBe(true);
    });
  });
});
