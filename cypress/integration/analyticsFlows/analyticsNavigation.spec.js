describe('Analytics navigation', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/dashboard/analytics');
      });
    });
  });

  it('should show Week view by default', () => {
    cy.findByRole('navigation', { name: 'Analytics period' }).within(() => {
      cy.findByRole('button', { name: 'Week' }).as('week');
      cy.findByRole('button', { name: 'Month' }).as('month');
      cy.findByRole('button', { name: 'Infinity' }).as('infinity');

      cy.get('@week').should('have.attr', 'aria-current', 'page');
      cy.get('@month').should('not.have.attr', 'aria-current');
      cy.get('@infinity').should('not.have.attr', 'aria-current');
    });
  });

  it('should switch tab to Month view', () => {
    cy.findByRole('navigation', { name: 'Analytics period' }).within(() => {
      cy.findByRole('button', { name: 'Month' }).as('month');
      cy.get('@month').should('not.have.attr', 'aria-current');
      cy.get('@month').click();
    });
    cy.findByRole('navigation', { name: 'Analytics period' })
      .findByRole('button', { name: 'Month' })
      .should('have.attr', 'aria-current', 'page');
  });

  it('should switch tab to Infinity view', () => {
    cy.findByRole('navigation', { name: 'Analytics period' }).within(() => {
      cy.findByRole('button', { name: 'Infinity' }).as('infinity');
      cy.get('@infinity').should('not.have.attr', 'aria-current');
      cy.get('@infinity').click();
    });
    cy.findByRole('navigation', { name: 'Analytics period' })
      .findByRole('button', { name: 'Infinity' })
      .should('have.attr', 'aria-current', 'page');
  });

  it('should hide organizations menu', () => {
    cy.findByRole('navigation', { name: 'Organizations menu' }).should(
      'not.exist',
    );
  });

  describe.skip('when user is admin of an organization', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('adminUser');

      cy.get('@adminUser').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/dashboard/analytics');
        });
      });
    });

    it('should show organizations menu', () => {
      cy.findByRole('navigation', { name: 'Dashboards' }).should('exist');
    });

    it('should navigate to correct organization analytics dashboard', () => {
      cy.findByText('Bachmanity Analytics Dashboard').click();

      cy.contains('h1', 'Analytics Dashboard for Bachmanity');
    });
  });
});
