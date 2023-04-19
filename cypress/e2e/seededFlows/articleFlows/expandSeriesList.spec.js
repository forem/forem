describe('Series article list on article page', () => {
  const createSeriesArticle = (title) => {
    return cy.createArticle({
      title,
      content: `${title} in New Series`,
      series: 'New Series',
      published: true,
    });
  };

  const findVisibleLink = (innerText, { as = 'nothing' } = {}) => {
    cy.findByText(innerText).parent().as(as).should('have.attr', 'href');
  };

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/seriesUser.json').as('user');

    cy.get('@user')
      .then((user) => cy.loginAndVisit(user, '/'))
      .then(() => createSeriesArticle('First Post'))
      .then(() => createSeriesArticle('Second Post'))
      .then(() => createSeriesArticle('Third Post'))
      .then(() => createSeriesArticle('Fourth Post'))
      .then(() => createSeriesArticle('Fifth Post'))
      .then((response) => {
        cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
      });
  });

  context('when there are 5 articles or less', () => {
    it('shows links to all of them', () => {
      cy.get('nav.series-switcher').within(() => {
        findVisibleLink('First Post');
        findVisibleLink('Second Post');
        findVisibleLink('Third Post');
        findVisibleLink('Fourth Post');
        findVisibleLink('Fifth Post');
      });
    });
  });

  context('when there are more than 5 articles', () => {
    beforeEach(() => {
      createSeriesArticle('Sixth Post').then((response) => {
        cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
      });
    });

    it('hides the middle articles behind an expander', () => {
      cy.get('nav.series-switcher').within(() => {
        findVisibleLink('First Post', { as: 'firstPostLink' });
        findVisibleLink('Second Post', { as: 'secondPostLink' });
        cy.findByText('Third Post', { hidden: true }).should('not.be.visible');
        cy.findByText('Fourth Post', { hidden: true }).should('not.be.visible');
        findVisibleLink('Fifth Post', { as: 'fifthPostLink' });
        findVisibleLink('Sixth Post', { as: 'sixthPostLink' });

        findVisibleLink('2 more parts...', { as: 'expander' });
        cy.get('@expander').click();

        cy.get('@firstPostLink').should('be.visible');
        cy.get('@secondPostLink').should('be.visible');
        findVisibleLink('Third Post');
        findVisibleLink('Fourth Post');
        cy.get('@fifthPostLink').should('be.visible');
        cy.get('@sixthPostLink').should('be.visible');
        cy.get('@expander').should('not.be.visible');
      });
    });
  });
});
