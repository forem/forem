describe('Home page feed events', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  const scrollBackAndForth = () => {
    // The delay is necessary for Cypress to give `IntersectionObserver` time to actually work.
    // Also, we scroll twice so we can confirm we don't send extraneous events.
    cy.scrollTo('bottom', { duration: 700 });
    cy.scrollTo('top', { duration: 700 });
  };

  context('when a user is not logged in', () => {
    beforeEach(() => {
      const spy = cy.spy().as('feedEventsSpy');
      cy.intercept('/feed_events', spy);
      cy.clock(new Date(), ['setInterval']);

      cy.visit('/');
      cy.tick(500); // Allow regular page load timers to run
    });

    it('does not send feed events', () => {
      scrollBackAndForth();
      // Again for good measure
      scrollBackAndForth();

      // More than autosubmit threshold
      cy.tick(7000);
      cy.get('@feedEventsSpy').should('not.have.been.called');
    });
  });

  context('when a user is logged in', () => {
    beforeEach(() => {
      cy.fixture('users/articleEditorV1User.json').as('user');
      cy.intercept('/feed_events').as('feedEventsSubmission');
      cy.get('@user').then((user) => cy.loginUser(user));
    });

    const visitAndWaitForLoad = (url, { expectedPostCount }) => {
      cy.visit(url);
      cy.get('[data-feed-position]').should('have.length', expectedPostCount);
    };

    const findAndDetermineImpressions = (callback) => {
      cy.get('[data-feed-content-id]').then((posts) => {
        const ids = posts
          .map(function () {
            return this.dataset.feedContentId;
          })
          .get();

        const expectedEvents = ids.map((id, index) => ({
          article_id: `${id}`,
          article_position: `${index + 1}`,
          category: 'impression',
          context_type: 'home',
        }));
        callback(expectedEvents);
      });
    };

    it('submits click events immediately', () => {
      visitAndWaitForLoad('/', { expectedPostCount: 11 });

      // The first/featured article is `test-article-slug`
      cy.get('#featured-story-marker').within((post) => {
        const id = post.data('feedContentId');

        cy.findByRole('heading').click();
        // Less than auto-submit threshold of 5 seconds.
        cy.wait('@feedEventsSubmission', { timeout: 1000 })
          .its('request.body.feed_events')
          .should('deep.contain', {
            // For some reason Cypress leaves the integers in the request body as strings.
            article_id: `${id}`,
            article_position: '1',
            category: 'click',
            context_type: 'home',
          });
      });
    });

    it('auto-submits incomplete batches of events after a few seconds', () => {
      visitAndWaitForLoad('/', { expectedPostCount: 11 });

      // There are 11 articles currently in the seeder! If this line is failing
      // and a seeded article has recently been added or removed, just bump
      // this number.
      findAndDetermineImpressions((events) => {
        scrollBackAndForth();

        cy.wait('@feedEventsSubmission')
          .its('request.body.feed_events')
          .should('have.deep.members', events);
      });
    });

    it('submits impression events in batches of 20', () => {
      const createArticles = [...Array(15)].map((_, index) =>
        cy.createArticle({
          title: `Feed post ${index}`,
          content: `Content for feed post ${index}`,
        }),
      );
      cy.all(createArticles).then(() => {
        visitAndWaitForLoad('/', { expectedPostCount: 26 });

        findAndDetermineImpressions((events) => {
          const firstBatch = events.slice(0, 20);
          const secondBatch = events.slice(20);
          scrollBackAndForth();

          cy.wait('@feedEventsSubmission')
            .its('request.body.feed_events')
            .should('have.deep.members', firstBatch);

          cy.wait('@feedEventsSubmission')
            .its('request.body.feed_events')
            .should('have.deep.members', secondBatch);
        });
      });
    });
  });
});
