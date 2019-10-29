import { baseURL, eyesOpen } from '../../utils';
describe('Visual  Regression Tests', () => {
  beforeEach(() => {
    cy.visit(baseURL);
  });

  it('should display sign up options', () => {
    cy.get('#navigation-butt').should('be.visible');
  });

  it('should redirect to code of conduct', () => {
    cy.get('[data-cy=codeofconduct]')
      .contains('Code of Conduct')
      .invoke('attr', 'href')
      .then(href => {
        cy.visit(`${baseURL}${href}`);
        cy.get('h1')
          .should('be.visible')
          .contains('Code of Conduct');
      });
  });

  it('should redirect to about us', () => {
    cy.get('#loggedoutmenu.menu.logged-out').invoke('show');
    cy.get('[data-cy=aboutus]')
      .contains('All about dev.to')
      .parent()
      .invoke('attr', 'href')
      .then(href => {
        cy.visit(`${baseURL}${href}`);
        console.log('hi');
        console.log(`${href}`);
        cy.get('h1')
          .should('be.visible')
          .contains('More information about dev.to');
      });
  });
});
