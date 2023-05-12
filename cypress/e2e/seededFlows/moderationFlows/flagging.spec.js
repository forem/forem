describe('Flagging to admins', () => {
  const findButton = (labelText, { as, highlighted }) => {
    const assertion = highlighted ? 'have.class' : 'not.have.class';
    cy.get('.reaction-button')
      .filter(`:contains("${labelText}")`)
      .as(as)
      .should(assertion, 'reacted');
  };

  const flagContentSpec = () => {
    cy.get('@contentUser').then(({ username }) => {
      cy.intercept('POST', '/reactions').as('flagRequest');

      findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
      findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });

      cy.get('@contentFlag').click();
      cy.wait('@flagRequest');
      cy.reload();

      findButton('Flag to Admins', { as: 'contentFlag', highlighted: true });
      findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });

      cy.get('@contentFlag').click();
      cy.wait('@flagRequest');
      cy.reload();

      findButton('Flag to Admins', { as: 'contentFlag', highlighted: false });
      findButton(`Flag ${username}`, { as: 'userFlag', highlighted: false });
    });
  };

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('admin');
    cy.fixture('users/seriesUser.json').as('contentUser');
  });

  context('when targeting an article', () => {
    beforeEach(() => {
      cy.get('@admin').then((admin) => {
        cy.loginAndVisit(admin, '/series_user/series-test-article-slug/mod');
      });
    });

    it('flags and unflags only the article when clicked', flagContentSpec);
  });

  context('when targeting a comment', () => {
    beforeEach(() => {
      cy.get('@contentUser')
        .then((user) => cy.loginUser(user))
        .then(() =>
          cy.createArticle({
            title: 'Test Article',
            content: 'Test article contents',
            published: true,
          }),
        )
        .then((response) =>
          cy.createComment({
            content: 'This is a test comment.',
            commentableId: response.body.id,
            commentableType: 'Article',
          }),
        )
        .then((response) => {
          cy.signOutUser().then(() => {
            cy.get('@admin').then((admin) => {
              cy.loginAndVisit(admin, `${response.body.url}/mod`);
            });
          });
        });
    });

    it('flags and unflags only the comment when clicked', flagContentSpec);
  });
});
