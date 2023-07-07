describe('Moderation Tools for Comments', () => {
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

    cy.fixture('users/questionableUser.json').as('questionableUser');
  });

  context('when the user is only a trusted user', () => {
    beforeEach(() => {
      cy.fixture('users/trustedUser.json').as('trustedUser');

      cy.get('@trustedUser').then((trustedUser) => {
        cy.loginAndVisit(trustedUser, '/series_user/series-test-article-slug');
      });
    });

    it.skip('flags and unflags only the comment when clicked', () => {
      navigateToCommentFlagPage().then(() => {
        cy.get('@questionableUser').then(({ username }) => {
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

    it.skip('flags and unflags only the user when clicked', () => {
      navigateToCommentFlagPage().then(() => {
        cy.get('@questionableUser').then(({ username }) => {
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

    it.skip('visually toggles contradictory mod reactions off', () => {
      navigateToCommentFlagPage().then(() => {
        cy.intercept('POST', '/reactions').as('flagRequest');

        findButton('High Quality', { as: 'thumbsUp' });
        findButton('Low Quality', { as: 'thumbsDown' });
        findButton('Flag to Admins', { as: 'vomit' });

        clickButton('@thumbsUp');

        cy.get('@thumbsUp').should('have.class', 'reacted');
        cy.get('@thumbsDown').should('not.have.class', 'reacted');
        cy.get('@vomit').should('not.have.class', 'reacted');

        clickButton('@thumbsDown');

        cy.get('@thumbsUp').should('not.have.class', 'reacted');
        cy.get('@thumbsDown').should('have.class', 'reacted');
        cy.get('@vomit').should('not.have.class', 'reacted');

        clickButton('@vomit');

        cy.get('@thumbsUp').should('not.have.class', 'reacted');
        cy.get('@thumbsDown').should('have.class', 'reacted');
        cy.get('@vomit').should('have.class', 'reacted');

        clickButton('@thumbsUp');

        cy.get('@thumbsUp').should('have.class', 'reacted');
        cy.get('@thumbsDown').should('not.have.class', 'reacted');
        cy.get('@vomit').should('not.have.class', 'reacted');
      });
    });
  });

  context('when the user is an admin', () => {
    beforeEach(() => {
      cy.fixture('users/adminUser.json').as('admin');

      cy.get('@admin').then((admin) => {
        cy.loginAndVisit(admin, '/series_user/series-test-article-slug');
      });
    });

    it('also permits deleting comment with confirmation', () => {
      cy.findByText('Comment deleted').should('not.exist');

      navigateToCommentFlagPage().then(() => {
        cy.on('window:confirm', () => true);

        cy.findByRole('button', { name: /Delete Comment/ }).click();

        cy.url().should('include', '/series_user/series-test-article-slug');
        cy.findByText('Comment deleted').should('exist');
      });
    });
  });
});
