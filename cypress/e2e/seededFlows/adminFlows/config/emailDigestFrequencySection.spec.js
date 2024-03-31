describe('Emails Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/customization/config');
    });
  });

  describe('contact settings', () => {
    it('can update the contact email', () => {
      cy.findByTestId('emailForm').as('emailForm');

      cy.get('@emailForm').within(() => {
        cy.findByText('Emails').click();
        cy.findByLabelText('Contact email').as('contact');
        cy.get('@contact').clear();
        cy.get('@contact').type('yo@dev.to');
        cy.findByText('Update Settings').click();
      });

      cy.url().should('contains', '/admin/customization/config');

      cy.findByText('Successfully updated settings.').should('be.visible');

      cy.findByLabelText('Contact email').should('have.value', 'yo@dev.to');
    });
  });

  describe('email digest frequency settings', () => {
    it('can change the frequency', () => {
      cy.findByTestId('emailForm').as('emailForm');

      cy.get('@emailForm').within(() => {
        cy.findByText('Emails').click();
        cy.findByLabelText('Periodic email digest').as('frequency');
        cy.get('@frequency').clear();
        cy.get('@frequency').type('42');
        cy.findByText('Update Settings').click();
      });

      cy.url().should('contains', '/admin/customization/config');

      cy.findByText('Successfully updated settings.').should('be.visible');

      cy.findByLabelText('Periodic email digest').should('have.value', '42');
    });
  });
});
