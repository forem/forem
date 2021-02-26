// import { BREAKPOINTS } from '../../../app/javascript/shared/components/useMediaQuery';

describe('Reading List', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then((_response) => {
        cy.visit('/readinglist');
      });
    });
  });

  it('should load an empty reading list', () => {
    cy.intercept(
      Cypress.config().baseUrl +
        'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
      { fixture: 'search/emptyReadingList.json' },
    ).as('emptyReadingList');
    cy.wait('@emptyReadingList');
    cy.findByRole('main')
      .as('main')
      .findByText(/^Your reading list is empty$/i);
    cy.get('@main').findByText(/^View Archive$/i);
    cy.get('@main').findByLabelText(/^Search...$/i);
    cy.get('@main').findByText(/^Reading list \(0\)$/);
  });

  it('should load an a reading list with items', () => {
    cy.intercept(
      Cypress.config().baseUrl +
        'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
      { fixture: 'search/readingList.json' },
    ).as('readingList');
    cy.wait('@readingList');
    cy.findByRole('main')
      .as('main')
      .findByText(/^Your reading list is empty$/i)
      .should('not.exist');
    cy.get('@main').findByText(/^View Archive$/i);
    cy.get('@main').findByLabelText(/Search...$/i);
    cy.get('@main').findByText(/^Reading list \(3\)$/);
  });
});
