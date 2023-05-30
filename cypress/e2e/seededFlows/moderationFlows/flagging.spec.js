describe('Flagging to admins', () => {
  const navigateToCommentFlagPage = () => {
    return cy.get('#comments').within(() => {
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
      cy.findByRole('link', { name: 'Moderate' }).click();
    });
  };

  const findButton = (labelText, { as, highlighted }) => {
    const assertion = highlighted ? 'have.class' : 'not.have.class';
    cy.get('.reaction-button')
      .filter(`:contains("${labelText}")`)
      .as(as)
      .should(assertion, 'reacted');
  };

  const clickButton = (buttonAlias) => {
    cy.get(buttonAlias).click();
    cy.wait('@flagRequest');
  };

  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/adminUser.json').as('admin');
    cy.fixture('users/questionableUser.json').as('contentUser');
    cy.intercept('POST', '/reactions').as('flagRequest');

    cy.get('@admin').then((admin) => {
      cy.loginAndVisit(admin, '/series_user/series-test-article-slug');
    });
  });

  it('flags and unflags only the comment when clicked', () => {
    navigateToCommentFlagPage().then(() => {
      cy.get('@contentUser').then(({ username }) => {
        findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
        findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });

        clickButton('@contentFlag');

        findButton('Flag to Admins', { as: 'contentFlag', highlighted: true });
        findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });

        clickButton('@contentFlag');

        findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
        findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });
      });
    });
  });

  it('flags and unflags only the user when clicked', () => {
    navigateToCommentFlagPage().then(() => {
      cy.get('@contentUser').then(({ username }) => {
        findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
        findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });

        clickButton('@userFlag');

        findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
        findButton(`Flag ${username}`, { as: 'userFlag', highlighted: true });

        clickButton('@userFlag');

        findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
        findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });
      });
    });
  });
});
