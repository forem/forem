describe('Flagging to admins', () => {
  const navigateToCommentFlagPage = () => {
    return cy.get('#comments').within(() => {
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
      cy.findByRole('link', { name: 'Moderate' }).click();
    });
  };

  const findButton = (labelText, { as }) => {
    cy.get('.reaction-button')
      .filter(`:contains("${labelText}")`)
      .as(as)
      .should('not.have.class', 'reacted');
  };

  const clickButton = (buttonAlias) => {
    cy.get(buttonAlias).click();
    cy.wait('@flagRequest');
  };

  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/adminUser.json').as('admin');
    cy.fixture('users/questionableUser.json').as('contentUser');

    cy.get('@admin').then((admin) => {
      cy.loginAndVisit(admin, '/series_user/series-test-article-slug');
    });
  });

  it('flags and unflags only the comment when clicked', () => {
    navigateToCommentFlagPage().then(() => {
      cy.get('@contentUser').then(({ username }) => {
        cy.intercept('POST', '/reactions').as('flagRequest');

        findButton('Flag to Admins', { as: 'contentFlag' });
        findButton(`Flag ${username}`, { as: 'userFlag' });

        clickButton('@contentFlag');

        cy.get('@contentFlag').should('have.class', 'reacted');
        cy.get('@userFlag').should('not.have.class', 'reacted');

        clickButton('@contentFlag');

        cy.get('@contentFlag').should('not.have.class', 'reacted');
        cy.get('@userFlag').should('not.have.class', 'reacted');
      });
    });
  });

  it('flags and unflags only the user when clicked', () => {
    navigateToCommentFlagPage().then(() => {
      cy.get('@contentUser').then(({ username }) => {
        cy.intercept('POST', '/reactions').as('flagRequest');

        findButton('Flag to Admins', { as: 'contentFlag' });
        findButton(`Flag ${username}`, { as: 'userFlag' });

        clickButton('@userFlag');

        cy.get('@contentFlag').should('not.have.class', 'reacted');
        cy.get('@userFlag').should('have.class', 'reacted');

        clickButton('@userFlag');

        cy.get('@contentFlag').should('not.have.class', 'reacted');
        cy.get('@userFlag').should('not.have.class', 'reacted');
      });
    });
  });
});
