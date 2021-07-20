describe('Follow tag', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/t/tag1').then(() => {
        cy.findByRole('heading', { name: '# tag1' });
        cy.get('[data-follow-clicks-initialized]');
      });
    });
  });

  it('Follows and unfollows a tag', () => {
    cy.intercept('/follows').as('followsRequest');
    cy.findByRole('button', { name: 'Follow' }).as('followButton');

    cy.get('@followButton').click();
    cy.wait('@followsRequest');

    cy.get('@followButton').should('have.text', 'Following');

    cy.get('@followButton').click();
    cy.wait('@followsRequest');

    cy.get('@followButton').should('have.text', 'Follow');
  });
});
