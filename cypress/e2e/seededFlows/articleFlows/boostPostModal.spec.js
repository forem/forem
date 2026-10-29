describe('Boost post modal', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['python'],
          content: `This is an article about ball pythons.`,
          published: true,
        }).then((response) => {
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
        });
      });
    });

    cy.viewport('macbook-16');
  });

  it('closes on Escape and returns focus to the Boost button', () => {
    cy.findByRole('button', { name: 'Boost' }).as('boostButton').click();

    cy.findByRole('dialog', { name: 'modal' }).should('be.visible');
    cy.findByRole('heading', { name: 'Boost Post to the Feed' }).should(
      'be.visible',
    );

    cy.get('body').type('{esc}');

    cy.findByRole('dialog', { name: 'modal' }).should('not.exist');
    cy.get('@boostButton').should('have.focus');
  });

  it('still closes with the close button', () => {
    cy.findByRole('button', { name: 'Boost' }).click();
    cy.findByRole('dialog', { name: 'modal' }).should('be.visible');

    cy.findByRole('button', { name: 'Close' }).click();

    cy.findByRole('dialog', { name: 'modal' }).should('not.exist');
  });
});
