describe('Moderation Tools for Comments', () => {
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
        cy.intercept('/notifications/counts').as('notificationCount');
        cy.intercept('/async_info/base_data').as('baseData');
        cy.intercept('/ahoy/visits').as('ahoy');
        cy.get('#comments').within(() => {
          cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
          cy.findByRole('link', { name: 'Moderate' }).click();
        });
        cy.wait(['@notificationCount', '@baseData', '@ahoy']);
      });
    });

    it('flags and unflags only the comment when clicked', () => {
      cy.intercept('POST', '/reactions').as('flagRequest');

      findButton('Flag to Admins', { as: 'contentFlag' });
      findButton(`Flag questionable_user`, { as: 'userFlag' });

      clickButton('@contentFlag');

      cy.get('@contentFlag').should('have.class', 'reacted');
      cy.get('@userFlag').should('not.have.class', 'reacted');

      clickButton('@contentFlag');

      cy.get('@contentFlag').should('not.have.class', 'reacted');
      cy.get('@userFlag').should('not.have.class', 'reacted');
    });

    it('flags and unflags only the user when clicked', () => {
      cy.intercept('POST', '/reactions').as('flagRequest');

      findButton('Flag to Admins', { as: 'contentFlag' });
      findButton(`Flag questionable_user`, { as: 'userFlag' });

      clickButton('@userFlag');

      cy.get('@contentFlag').should('not.have.class', 'reacted');
      cy.get('@userFlag').should('have.class', 'reacted');

      clickButton('@userFlag');

      cy.get('@contentFlag').should('not.have.class', 'reacted');
      cy.get('@userFlag').should('not.have.class', 'reacted');
    });

    it('visually toggles contradictory mod reactions off', () => {
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

  context('when the user is an admin', () => {
    beforeEach(() => {
      cy.fixture('users/adminUser.json').as('admin');

      cy.get('@admin').then((admin) => {
        cy.loginAndVisit(admin, '/series_user/series-test-article-slug');
        cy.get('#comments').within(() => {
          cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
          cy.findByRole('link', { name: 'Moderate' }).click();
        });
      });
    });

    it('also permits deleting comment with confirmation', () => {
      cy.findByText('Comment deleted').should('not.exist');

      cy.on('window:confirm', () => true);

      cy.findByRole('button', { name: /Delete Comment/ }).click();

      cy.url().should('include', '/series_user/series-test-article-slug');
      cy.findByText('Comment deleted').should('exist');
    });
  });
});
