describe('Comment notifications', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/notificationsUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/notifications');
      cy.findByRole('heading', { name: 'Notifications', level: 1 });
    });
  });

  it('Likes and unlikes a comment', () => {
    cy.get('main').within(() => {
      cy.findByRole('button', { name: 'Like' }).as('like');

      // User can like a comment
      cy.get('@like').should('have.attr', 'aria-pressed', 'false');
      cy.get('@like').click();
      cy.get('@like').should('have.attr', 'aria-pressed', 'true');

      // User can unlike a comment
      cy.get('@like').click();
      cy.get('@like').should('have.attr', 'aria-pressed', 'false');
    });
  });

  it('Replies to a comment', () => {
    cy.get('main').within(() => {
      // Check that comment form is initially hidden
      cy.findByRole('textbox', { name: 'Reply to a comment...' }).should(
        'not.exist',
      );

      // Check the textbox appears and received immediate focus
      cy.findByRole('link', { name: 'Reply' }).click();
      cy.findByRole('textbox', { name: 'Reply to a comment...' })
        .should('have.focus')
        .type('Example reply text');

      cy.findByRole('button', { name: 'Submit' }).click();
      // Check the confirmation is displayed on the page
      cy.findByRole('link', { name: 'Check it out' });
    });
  });
});
