import { baseURL, eyesOpen } from '../../utils';
describe('Visual  Regression Tests', () => {
  beforeEach(() => {
    cy.visit(baseURL);
    eyesOpen('Home Page');
  });
  afterEach(() => {
    cy.eyesClose();
  });

  it('should open home page', () => {
    cy.eyesCheckWindow('Main Page');
  });

  it('should display sign up options', () => {
    cy.get('#navigation-butt').click();
    cy.eyesCheckWindow({
      sizeMode: 'selector', //mode
      selector: '.menu.logged-out',
    });
  });

  it('should redirect to code of conduct', () => {
    const elem = cy.get('[data-cy-href=codeofconduct]');
    elem.contains('Code of Conduct');
    return elem.invoke('attr', 'href').then(href => {
      cy.visit(`${baseURL}${href}`);
      cy.wait(2000);
      cy.eyesCheckWindow('Code of Conduct');
    });
  });

  it('should redirect to about us', () => {
    cy.get('#loggedoutmenu.menu.logged-out').invoke('show');
    const elem = cy.get('[data-cy-href=aboutus]');
    cy.wait(2000)
    elem.contains('All about dev.to').invoke('show');
    return elem.invoke('attr', 'href').then(href => {
      cy.visit(`${baseURL}${href}`);
      cy.wait(2000);
      cy.eyesCheckWindow('All about dev.to');
    });
  });

});
