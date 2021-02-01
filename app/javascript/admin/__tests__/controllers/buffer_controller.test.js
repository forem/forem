import { Application } from 'stimulus';
import { BufferController } from '../../controllers/buffer_controller';

describe('BufferController', () => {
  beforeEach(() => {
    document.body.innerHTML = `
    <div data-controller="buffer"
         data-buffer-bg-highlighted-class="bg-highlighted"
         data-buffer-border-highlighted-class="border-highlighted">
      <h2 data-buffer-target="header"></h2>
      <button data-action="buffer#tagBufferUpdateConfirmed"></button>
      <button data-action="buffer#tagBufferUpdateDismissed"></button>
      <button data-action="buffer#highlightElement"></button>
    </div>`;

    const application = Application.start();
    application.register('buffer', BufferController);
  });

  describe('#tagBufferUpdateConfirmed', () => {
    it('adds a badge to the header', () => {
      const button = document.getElementsByTagName('button')[0];
      const header = document.getElementsByTagName('h2')[0];

      button.click();

      expect(header.firstChild.textContent).toMatch(/Confirm/);
    });
  });

  describe('#tagBufferUpdateDismissed', () => {
    it('adds a badge to the header', () => {
      const button = document.getElementsByTagName('button')[1];
      const header = document.getElementsByTagName('h2')[0];

      button.click();

      expect(header.firstChild.textContent).toMatch(/Dismiss/);
    });
  });

  describe('#highlightElement', () => {
    it('adds a class to the controller element', () => {
      const button = document.getElementsByTagName('button')[2];
      const element = document.querySelector("[data-controller='buffer']");

      button.click();

      expect(
        element.classList.contains('bg-highlighted', 'border-highlighted'),
      ).toBe(true);
    });
  });
});
