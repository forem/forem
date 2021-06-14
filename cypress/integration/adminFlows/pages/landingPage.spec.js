describe('Set a landing page from the admin portal', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin/customization/pages');
      });
    });
  });

  it('should set a landing page when no other landing page exists', () => {
    cy.findAllByRole('link', { name: 'Edit' }).first().click();
    cy.findByRole('checkbox', { name: "Use as 'Locked Screen'" }).check();
    cy.findByRole('button', { name: 'Update Page' }).click();

    // Verify that the form has submitted and the page has changed to the confirmation page
    cy.url().should('contain', '/admin/customization/pages');

    cy.findByRole('img', { name: 'Current locked screen' }).should(
      'be.visible',
    );
  });

  it('should overwrite the landing page when choosing to set a new landing page', () => {
    cy.findAllByRole('link', { name: 'Edit' }).first().click();
    cy.findByRole('checkbox', { name: "Use as 'Locked Screen'" });
    // Set landing page
    cy.findByRole('main').within(() => {
      cy.findByRole('checkbox', { name: "Use as 'Locked Screen'" }).check();

      cy.findByRole('button', { name: 'Update Page' }).click();
    });
    cy.url().should('contain', '/admin/customization/pages');
    // Retrieve the title of the landing page
    let landingPageTitle;
    cy.findByRole('main').within(() => {
      cy.findAllByTestId('page').should((elements) => {
        for (let i = elements.length - 1; i >= 0; i--) {
          const el = elements[i];
          const isLandingPage =
            el.getElementsByClassName('crayons-icon').length > 0;
          if (isLandingPage) {
            landingPageTitle = el.querySelector('a').innerHTML;
          }
        }
      });

      cy.findAllByRole('link', { name: 'Edit' }).eq(1).click();
    });
    cy.findByRole('checkbox', { name: "Use as 'Locked Screen'" });
    // Change landing page
    cy.findByRole('main').within(() => {
      cy.findByRole('checkbox', { name: "Use as 'Locked Screen'" }).check();

      cy.findAllByRole('button', {
        name: 'Overwrite current locked screen',
      }).click();

      cy.findByRole('button', { name: 'Update Page' }).click();
    });

    // Check the title of the landing page has changed
    cy.findByRole('main').within(() => {
      let newLandingPageTitle;
      cy.findAllByTestId('page').should((elements) => {
        for (let i = elements.length - 1; i >= 0; i--) {
          const el = elements[i];
          const isLandingPage =
            el.getElementsByClassName('crayons-icon').length > 0;
          if (isLandingPage) {
            newLandingPageTitle = el.querySelector('a').innerHTML;
          }
        }

        assert.notEqual(landingPageTitle, newLandingPageTitle);
      });
    });
  });

  it('should not change the landing page when clicking cancel', () => {
    cy.findAllByRole('link', { name: 'Edit' }).first().click();

    // Set landing page
    cy.findByRole('main').within(() => {
      cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
        .first()
        .check();

      cy.findAllByRole('button', { name: 'Update Page' }).first().click();
    });

    // Retrieve the title of the landing page
    let landingPageTitle;
    cy.findByRole('main').within(() => {
      cy.findAllByTestId('page').should((elements) => {
        for (let i = elements.length - 1; i >= 0; i--) {
          const el = elements[i];
          const isLandingPage =
            el.getElementsByClassName('crayons-icon').length > 0;
          if (isLandingPage) {
            landingPageTitle = el.querySelector('a').innerHTML;
          }
        }
      });

      cy.findAllByRole('link', { name: 'Edit' }).eq(1).click();
    });

    // Change landing page but then Cancel
    cy.findByRole('main').within(() => {
      cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
        .first()
        .check();

      cy.findAllByRole('button', { name: 'Cancel' }).first().click();

      cy.findAllByRole('button', { name: 'Update Page' }).first().click();
    });

    // Check the title of the landing page has not changed
    cy.findByRole('main').within(() => {
      let newLandingPageTitle;
      cy.findAllByTestId('page').should((elements) => {
        for (let i = elements.length - 1; i >= 0; i--) {
          const el = elements[i];
          const isLandingPage =
            el.getElementsByClassName('crayons-icon').length > 0;
          if (isLandingPage) {
            newLandingPageTitle = el.querySelector('a').innerHTML;
          }
        }

        assert.equal(landingPageTitle, newLandingPageTitle);
      });
    });
  });
});
