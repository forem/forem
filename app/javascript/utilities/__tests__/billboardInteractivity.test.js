// Import the function to test and any necessary parts
import { setupBillboardInteractivity } from '@utilities/billboardInteractivity';

jest.mock('../../packs/billboardAfterRenderActions', () => ({
  observeBillboards: jest.fn(),
  executeBBScripts: jest.fn(),
}));

describe('billboard close functionality', () => {
  beforeEach(() => {
    // Setup a simple DOM structure that includes only the elements needed for the close functionality
    document.body.innerHTML = `
      <div class="another-element"></div>
      <div class="js-billboard popover-billboard" style="display: block;" data-dismissal-sku="WHATUP">
        <button id="sponsorship-close-trigger-1"></button>
      </div>
    `;
    localStorage.clear();
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
    const dismissalSkus = JSON.parse(
      localStorage.getItem('dismissal_skus_triggered'),
    );
    expect(dismissalSkus).toEqual(['WHATUP']);
  });
});

describe('persistent billboard close functionality', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('moves persistent billboard to existing sidebar container on close', () => {
    document.body.innerHTML = `
      <div id="persistent-minimized-billboard-container" class="hidden"></div>
      <div class="js-billboard popover-billboard" style="display: block;" data-dismissal-sku="PERSISTENT_SKU" data-special="persistent">
        <button id="sponsorship-close-trigger-2"></button>
        <template class="js-minimized-template">
          <div class="minimized-content">Minimized content matches!</div>
        </template>
      </div>
    `;

    const { observeBillboards, executeBBScripts } = require('../../packs/billboardAfterRenderActions');
    setupBillboardInteractivity();

    const closeButton = document.querySelector('#sponsorship-close-trigger-2');
    closeButton.click();

    // Assert the bottom billboard is hidden and its contents cleared
    const billboard = document.querySelector('.js-billboard');
    expect(billboard.style.display).toBe('none');
    expect(billboard.innerHTML).toBe('');

    // Assert the sidebar container has minimized content and is visible
    const sidebarContainer = document.getElementById('persistent-minimized-billboard-container');
    expect(sidebarContainer.classList.contains('hidden')).toBe(false);
    expect(sidebarContainer.innerHTML).toContain('Minimized content matches!');

    // Assert observeBillboards and executeBBScripts were called
    expect(observeBillboards).toHaveBeenCalled();
    expect(executeBBScripts).toHaveBeenCalledWith(sidebarContainer);
  });

  it('creates the container dynamically and appends to body on close if not present and no sidebar', () => {
    document.body.innerHTML = `
      <div class="js-billboard popover-billboard" style="display: block;" data-dismissal-sku="PERSISTENT_SKU" data-special="persistent">
        <button id="sponsorship-close-trigger-2"></button>
        <template class="js-minimized-template">
          <div class="minimized-content">Minimized content matches!</div>
        </template>
      </div>
    `;

    const { observeBillboards, executeBBScripts } = require('../../packs/billboardAfterRenderActions');
    setupBillboardInteractivity();

    expect(document.getElementById('persistent-minimized-billboard-container')).toBeNull();

    const closeButton = document.querySelector('#sponsorship-close-trigger-2');
    closeButton.click();

    const sidebarContainer = document.getElementById('persistent-minimized-billboard-container');
    expect(sidebarContainer).not.toBeNull();
    expect(sidebarContainer.parentNode).toBe(document.body);
    expect(sidebarContainer.classList.contains('hidden')).toBe(false);
    expect(sidebarContainer.innerHTML).toContain('Minimized content matches!');
  });

  it('creates the container dynamically and inserts after sidebar-bb if sidebar is present', () => {
    document.body.innerHTML = `
      <div class="crayons-layout__sidebar-right">
        <div class="sidebar-bb"></div>
      </div>
      <div class="js-billboard popover-billboard" style="display: block;" data-dismissal-sku="PERSISTENT_SKU" data-special="persistent">
        <button id="sponsorship-close-trigger-2"></button>
        <template class="js-minimized-template">
          <div class="minimized-content">Minimized content matches!</div>
        </template>
      </div>
    `;

    const { observeBillboards, executeBBScripts } = require('../../packs/billboardAfterRenderActions');
    setupBillboardInteractivity();

    expect(document.getElementById('persistent-minimized-billboard-container')).toBeNull();

    const closeButton = document.querySelector('#sponsorship-close-trigger-2');
    closeButton.click();

    const sidebarContainer = document.getElementById('persistent-minimized-billboard-container');
    expect(sidebarContainer).not.toBeNull();
    
    const sidebarBb = document.querySelector('.sidebar-bb');
    expect(sidebarBb.nextElementSibling).toBe(sidebarContainer);
    expect(sidebarContainer.classList.contains('hidden')).toBe(false);
  });
});
