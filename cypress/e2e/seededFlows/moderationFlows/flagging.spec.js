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

    cy.get('@admin').then((admin) => {
      cy.loginAndVisit(admin, '/');
    });
  });

  context('when targeting an article', () => {
    beforeEach(() => {
      cy.fixture('users/seriesUser.json').as('contentUser');
      cy.visit('/series_user/series-test-article-slug/mod');
    });

    it('flags and unflags only the article when clicked', flagContentSpec);
  });

  context('when targeting a comment', () => {
    beforeEach(() => {
      cy.fixture('users/notificationsUser.json').as('contentUser');
    });

    it('flags and unflags only the comment when clicked', () => {
      cy.get('#comment-trees-container').within(() => {
        cy.findAllByLabelText(/Toggle dropdown menu/i)
          .first()
          .click();
        cy.findByRole('link', { name: 'Moderate' }).then((link) => {
          // For some reason just clicking the link times out in Cypress only?
          cy.visit(link.href);
          flagContentSpec();
        });
      });
    });
  });
});
