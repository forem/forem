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
    cy.url().should('contain', '/customization/pages/');

    cy.findAllByRole('svg', { name: 'Current locked screen' })
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
        cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
          .last()
          .check();
        cy.findAllByRole('button', { name: 'Overwrite current locked screen' })
          .last()
          .click();
        cy.findAllByRole('button', { name: 'Update Page' }).last().click();
      });

    cy.findByRole('main')
      .findAllByRole('checkbox', { name: 'Landing Page' })
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
        cy.findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
          .first()
          .check();
        cy.findAllByRole('button', { name: 'Dismiss' }).first().click();
        cy.findAllByRole('button', { name: 'Update Page' }).first().click();
      });

    cy.findByRole('main')
      .findAllByRole('checkbox', { name: "Use as 'Locked Screen'" })
      .first()
      .should('not.be.checked');
  });
});
