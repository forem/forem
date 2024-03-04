// Import the function to test and any necessary parts
import { setupBillboardInteractivity } from '@utilities/billboardInteractivity';

describe('billboard close functionality', () => {
  beforeEach(() => {
    // Setup a simple DOM structure that includes only the elements needed for the close functionality
    document.body.innerHTML = `
      <div class="another-element"></div>
      <div class="js-billboard" style="display: block;" data-dismissal-sku="WHATUP">
        <button id="sponsorship-close-trigger-1"></button>
      </div>
    `;
  });

  it('hides billboard on close button click', () => {
    setupBillboardInteractivity();

    // Simulate clicking the close button
    const closeButton = document.querySelector('#sponsorship-close-trigger-1');
    closeButton.click();

    // Assert the billboard is hidden
    const billboard = document.querySelector('.js-billboard');
    expect(billboard.style.display).toBe('none');
  });

  it('hides billboard when clicking outside of it', () => {
    setupBillboardInteractivity();

    // Simulate a click outside the billboard
    const anotherElement = document.querySelector('.another-element');
    anotherElement.click();

    // Assert the billboard is hidden
    const billboard = document.querySelector('.js-billboard');
    expect(billboard.style.display).toBe('none');
  });

  it('adds dismissal sku to local storage when dismissing a billboard', () => {
    setupBillboardInteractivity();

    // Simulate clicking the close button
    const closeButton = document.querySelector('#sponsorship-close-trigger-1');
    closeButton.click();

    // Assert the dismissal sku is added to local storage
    const dismissalSkus = JSON.parse(localStorage.getItem('dismissal_skus_triggered'));
    expect(dismissalSkus).toEqual(['WHATUP']);
  });
});