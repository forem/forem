import { BREAKPOINTS } from '../../../app/javascript/shared/components/useMediaQuery';

describe('Reading List', () => {
  const mediaMatch = {
    addListener: () => {},
    removeListener: () => {},
  };
  const pageVisitOptions = {
    onBeforeLoad(window) {
      cy.stub(window, 'matchMedia', (query) => {
        // We need to know the implementation details here, but it's
        // required since Cypress can't evaluate the match.
        switch (query) {
          case `(width <= ${BREAKPOINTS.Medium - 1}px)`:
            return {
              ...mediaMatch,
              matches: window.innerWidth <= BREAKPOINTS.Medium - 1,
            };
          case `(width >= ${BREAKPOINTS.Medium}px)`:
            return {
              ...mediaMatch,
              matches: window.innerWidth >= BREAKPOINTS.Medium,
            };

          default:
            return {
              ...mediaMatch,
              matches: false,
            };
        }
      });
    },
  };

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  it('should load an empty reading list', () => {
    cy.visit('/readinglist');
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
    cy.get('@main').findByText(/^Reading list \(0\)$/i);
    cy.get('@main')
      .findByLabelText(/^Filter by tag$/i)
      .should('not.exist');
  });

  it('should load the reading list with items on screens smaller than the medium breakpoint', () => {
    cy.viewport(BREAKPOINTS.Medium - 1, BREAKPOINTS.Medium);
    cy.visit('/readinglist', pageVisitOptions);
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
    cy.get('@main').findByLabelText(/^Filter by tag$/i, { selector: 'select' });
    cy.get('@main')
      .findByText(/^Filter by tag$/i, { selector: 'legend' })
      .should('not.exist');
  });

  it('should load the reading list with items on screens larger than the medium breakpoint', () => {
    cy.viewport(BREAKPOINTS.Large, 600);
    cy.visit('/readinglist', pageVisitOptions);
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
    cy.get('@main').findByText(/^Filter by tag$/i, { selector: 'legend' });
    cy.get('@main')
      .findByLabelText(/^Filter by tag$/i, { selector: 'select' })
      .should('not.exist');
  });
});
