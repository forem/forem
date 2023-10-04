/**
 * Cypress takes extensive control of browser scrolling in order to facilitate
 * its automation and testing; unfortunately that means that various scrolling
 * behaviours (such as smooth scrolling or firing `IntersectionObserver` events)
 * don't work consistently.
 * This makes these tests flaky, but they are still useful to run locally and
 * update if you are modifying feed event functionality.
 */
describe.skip('Home page feed events', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  // Cypress full-page scrolling is so janky that it sometimes does not trigger
  // IntersectionObserver, so we are doing a bit of a manual scroll
  const scrollAll = (posts) => {
    posts.each((_, post) => {
      cy.wrap(post).scrollIntoView({ duration: 50 });
    });
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
      cy.scrollTo('bottom', { duration: 600 });
      cy.scrollTo('top', { duration: 600 });
      cy.scrollTo('bottom', { duration: 600 });

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
      return cy
        .get('[data-feed-position]')
        .should('have.length', expectedPostCount)
        .then((posts) => {
          posts.ea;
        });
    };

    const determineImpressions = (posts) => {
      const ids = posts
        .map(function () {
          return this.dataset.feedContentId;
        })
        .get();

      return ids.map((id, index) => ({
        article_id: `${id}`,
        article_position: `${index + 1}`,
        category: 'impression',
        context_type: 'home',
      }));
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
      // There are 11 articles currently in the seeder! If this line is failing
      // and a seeded article has recently been added or removed, just bump
      // this number.
      visitAndWaitForLoad('/', { expectedPostCount: 11 }).then((posts) => {
        const events = determineImpressions(posts);

        scrollAll(posts);
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
        visitAndWaitForLoad('/', { expectedPostCount: 26 }).then((posts) => {
          const events = determineImpressions(posts);

          const firstBatch = events.slice(0, 20);
          const secondBatch = events.slice(20);
          scrollAll(posts);

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
