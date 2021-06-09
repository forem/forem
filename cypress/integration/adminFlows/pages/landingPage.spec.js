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
    cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
      .first()
      .check();
    cy.findAllByRole('button', { name: 'Update Page' }).first().click();

    // Verify that the form has submitted and the page has changed to the confirmation page
    cy.url().should('contain', '/admin/customization/pages');

    cy.findAllByRole('img', { name: 'Current locked screen' })
      .first()
      .should('be.visible');
  });

  it('should overwrite the landing page when choosing to set a new landing page', () => {
    cy.findAllByRole('link', { name: 'Edit' }).first().click();
    cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
      .first()
      .check();
    cy.findAllByRole('button', { name: 'Update Page' }).first().click();

    cy.findByRole('main')
      .first()
      .within(() => {
        cy.findAllByRole('link', { name: 'Edit' }).first().click();
        cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
          .first()
          .check();
        cy.findAllByRole('button', { name: 'Overwrite current locked screen' })
          .first()
          .click();
        cy.findAllByRole('button', { name: 'Update Page' }).first().click();
      });

    cy.findByRole('main');
    cy.findAllByRole('link', { name: 'Edit' }).first().click();
    cy.findAllByRole('checkbox', { name: 'Landing Page' })
      .first()
      .should('be.checked');
  });

  it('should not change the landing page when clicking dismiss', () => {
    cy.findAllByRole('link', { name: 'Edit' }).first().click();
    cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
      .first()
      .check();
    cy.findAllByRole('button', { name: 'Update Page' }).first().click();

    cy.findByRole('main')
      .first()
      .within(() => {
        cy.findAllByRole('link', { name: 'Edit' }).first().click();
        cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
          .first()
          .check();
        cy.findAllByRole('button', { name: 'Cancel' }).first().click();
        cy.findAllByRole('button', { name: 'Update Page' }).first().click();
      });

    cy.findByRole('main');
    cy.findAllByRole('link', { name: 'Edit' }).first().click();
    cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
      .first()
      .should('not.be.checked');
  });
});
