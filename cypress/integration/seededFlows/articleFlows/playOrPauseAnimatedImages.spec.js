describe('play or pause animated images', () => {
  // Animated images are only identified async in the backend, and we can't rely on seeding them in the E2E DB
  // Instead, we inject 3 images into the page body for testing purposes. 2 with the data-animated attribute, and 1 without.
  const generateFakePageBody = () => {
    const fakeBody = document.createElement('body');
    const fakeMain = document.createElement('main');

    for (let i = 0; i < 3; i++) {
      const link = document.createElement('a');
      link.setAttribute('href', '/test-link');

      const image = document.createElement('img');
      image.setAttribute('src', '/media/test-image.gif');
      // Create two animated images, and one not
      if (i < 2) {
        image.setAttribute('data-animated', 'true');
      }

      link.appendChild(image);
      fakeMain.appendChild(link);
    }

    fakeBody.appendChild(fakeMain);

    return fakeBody;
  };

  describe('no reduced motion preference', () => {
    beforeEach(() => {
      Cypress.on('window:before:load', (window) => {
        window.document.body = generateFakePageBody();
      });

      cy.visit('/admin_mcadmin/test-article-slug');
    });

    it('initializes pausable images for a user with prefers-reduce-motion unset', () => {
      // Only two images should be pausable
      cy.findAllByRole('button', { name: 'Pause animation playback' })
        .as('pauseButtons')
        .should('have.length', 2);

      // By default, both buttons should be in the 'playing' state
      cy.get('@pauseButtons')
        .first()
        .should('have.attr', 'aria-pressed', 'false');
      cy.get('@pauseButtons')
        .last()
        .should('have.attr', 'aria-pressed', 'false');

      // Pressing the button should toggle only the state of the individual image
      cy.get('@pauseButtons')
        .first()
        .click()
        .should('have.attr', 'aria-pressed', 'true');
      cy.get('@pauseButtons')
        .last()
        .should('have.attr', 'aria-pressed', 'false');

      // It should also toggle back to playing
      cy.get('@pauseButtons')
        .first()
        .click()
        .should('have.attr', 'aria-pressed', 'false');
    });
  });

  describe('user prefers reduced motion', () => {
    beforeEach(() => {
      Cypress.on('window:before:load', (window) => {
        // We make sure when prefers-reduced-motion: no-preference is checked, we return false to mimic a user with reduced motion prefs
        cy.stub(window, 'matchMedia').returns({ matches: false });
        window.document.body = generateFakePageBody();
      });

      cy.visit('/admin_mcadmin/test-article-slug');
    });

    it('initializes pausable images for a user with prefers-reduce-motion set', () => {
      // Only two images should be pausable
      cy.findAllByRole('button', { name: 'Pause animation playback' })
        .as('pauseButtons')
        .should('have.length', 2);

      // By default, both buttons should be in the 'paused' state
      cy.get('@pauseButtons')
        .first()
        .should('have.attr', 'aria-pressed', 'true');
      cy.get('@pauseButtons')
        .last()
        .should('have.attr', 'aria-pressed', 'true');

      // Pressing the button should toggle only the state of the individual image
      cy.get('@pauseButtons')
        .first()
        .click()
        .should('have.attr', 'aria-pressed', 'false');
      cy.get('@pauseButtons')
        .last()
        .should('have.attr', 'aria-pressed', 'true');

      // It should also toggle back to paused
      cy.get('@pauseButtons')
        .first()
        .click()
        .should('have.attr', 'aria-pressed', 'true');
    });
  });
});
