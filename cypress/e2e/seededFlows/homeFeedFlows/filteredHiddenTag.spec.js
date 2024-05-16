describe('Home Feed should not filter when logged-out', () => {
  beforeEach(() => {
    cy.testSetup();

    // Explicitly set the viewport to make sure we're in the full desktop view for these tests
    cy.viewport('macbook-15');

    cy.visit('/');
  });

  it('**should** show tag1 tagged article', () => {
    cy.findByRole('heading', { name: 'Tag test article' }).should('exist');
  });
});

describe('Home Feed should filter tagged article when logged-in as user with hidden tags', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/hiddenTagUser.json').as('user');

    // Explicitly set the viewport to make sure we're in the full desktop view for these tests
    cy.viewport('macbook-15');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it('should **not** show tag1 tagged article', () => {
    cy.findByRole('heading', { name: 'Tag test article' }).should('not.exist');
  });
});

describe('Home Feed should not filter when logged-in as other user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    // Explicitly set the viewport to make sure we're in the full desktop view for these tests
    cy.viewport('macbook-15');

    cy.visit('/');
  });

  it('**should** show tag1 tagged article', () => {
    cy.findByRole('heading', { name: 'Tag test article' }).should('exist');
  });
});

// describe('Search should **not** filter tagged article even when logged-in as user with hidden tags', () => {
//   beforeEach(() => {
//     cy.testSetup();
//     cy.fixture('users/hiddenTagUser.json').as('user');

//     // Explicitly set the viewport to make sure we're in the full desktop view for these tests
//     cy.viewport('macbook-15');

//     cy.get('@user').then((user) => {
//       cy.loginAndVisit(user, '/');
//       cy.findByRole('textbox', { name: /search/i }).type('Tag test');
//       cy.findByRole('button', { name: /search/i }).click();

//       cy.url().should('include', '/search?q=Tag%20test');
//     });
//   });

//   it('**should** show tag1 tagged article', () => {
//     cy.findByRole('heading', { name: 'Tag test article' }).should('exist');
//   });
// });

describe('Tag view should **not** filter tagged article even when logged-in as user with hidden tags', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/hiddenTagUser.json').as('user');

    // Explicitly set the viewport to make sure we're in the full desktop view for these tests
    cy.viewport('macbook-15');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/t/tag1');
    });
  });

  it('**should** show tag1 tagged article', () => {
    cy.findByRole('heading', { name: 'Tag test article' }).should('exist');
  });
});
