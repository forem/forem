describe('Home Feed Navigation', () => {
  describe('Drawer navigation for smallest screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      // Explicitly set the viewport to make sure we're in the full desktop view for these tests
      cy.viewport('iphone-7');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/');
      });
    });

    it('should show a modal drawer of feed options', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).as(
        'feedOptionsButton',
      );

      // Open the modal drawer, check focus is handled and the navigation appears
      cy.get('@feedOptionsButton').click();
      cy.findByRole('link', { name: 'Trending' }).should('have.focus');
      cy.findByRole('dialog', { name: 'Feed options' }).within(() => {
        cy.findByRole('navigation', { name: 'View posts by' });
        cy.findByRole('link', { name: 'Trending' }).should('have.focus');
      });

      // Close by clicking the overlay and check modal drawer closes
      cy.get('body').click('topLeft');
      cy.findByRole('dialog', { name: 'Feed options' }).should('not.exist');
      cy.get('@feedOptionsButton').should('have.focus');
    });

    it('should show Trending by default', () => {
      cy.findByRole('heading', { name: 'Trending' });

      cy.findByRole('button', { name: 'Change feed view' }).as(
        'feedOptionsButton',
      );
      cy.get('@feedOptionsButton').click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'Trending' }).as('trending');
        cy.findByRole('link', { name: 'This Week' }).as('week');
        cy.findByRole('link', { name: 'This Month' }).as('month');
        cy.findByRole('link', { name: 'This Year' }).as('year');
        cy.findByRole('link', { name: 'All Time' }).as('allTime');

        cy.get('@trending').should('have.attr', 'aria-current', 'page');

        cy.get('@week').should('not.have.attr', 'aria-current');
        cy.get('@month').should('not.have.attr', 'aria-current');
        cy.get('@year').should('not.have.attr', 'aria-current');
        cy.get('@allTime').should('not.have.attr', 'aria-current');
      });
    });

    it('should navigate to Week view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Week' }).as('week');
        cy.get('@week').should('not.have.attr', 'aria-current');
        cy.get('@week').click();
      });

      cy.url().should('contain', '/top/this-week');
      cy.findByRole('heading', { name: 'This Week' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Week' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to Month view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Month' }).as('month');
        cy.get('@month').should('not.have.attr', 'aria-current');
        cy.get('@month').click();
      });

      cy.url().should('contain', '/top/this-month');
      cy.findByRole('heading', { name: 'This Month' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Month' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to Year view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Year' }).as('year');
        cy.get('@year').should('not.have.attr', 'aria-current');
        cy.get('@year').click();
      });

      cy.url().should('contain', '/top/this-year');
      cy.findByRole('heading', { name: 'This Year' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Year' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to All Time view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'All Time' }).as('allTime');
        cy.get('@allTime').should('not.have.attr', 'aria-current');
        cy.get('@allTime').click();
      });

      cy.url().should('contain', '/top/all-time');
      cy.findByRole('heading', { name: 'All Time' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'All Time' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to Most Recent view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'Most Recent' }).as('mostRecent');
        cy.get('@mostRecent').should('not.have.attr', 'aria-current');
        cy.get('@mostRecent').click();
      });

      cy.url().should('contain', '/top/most-recent');
      cy.findByRole('heading', { name: 'Most Recent' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'Most Recent' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });
  });

  describe('Navigation for larger screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      // Explicitly set the viewport to make sure we're in the full desktop view for these tests
      cy.viewport('macbook-15');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/');
      });
    });

    it('should show a toggleable dropdown of feed options', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).as(
        'feedOptionsButton',
      );

      // Open the dropdown, check focus is handled and the navigation appears
      cy.get('@feedOptionsButton').click();
      cy.findByRole('link', { name: 'Trending' }).should('have.focus');
      cy.findByRole('navigation', { name: 'View posts by' });

      // Close with Escape key and check dropdown closes
      cy.get('body').type('{esc}');
      cy.findByRole('navigation', { name: 'View posts by' }).should(
        'not.exist',
      );
      cy.get('@feedOptionsButton').should('have.focus');

      // Toggle open/close with button click
      cy.get('@feedOptionsButton').click();
      cy.findByRole('navigation', { name: 'View posts by' });
      cy.get('@feedOptionsButton').click();
      cy.findByRole('navigation', { name: 'View posts by' }).should(
        'not.exist',
      );
    });

    it('should show Trending by default', () => {
      cy.findByRole('heading', { name: 'Trending' });

      cy.findByRole('button', { name: 'Change feed view' }).as(
        'feedOptionsButton',
      );
      cy.get('@feedOptionsButton').click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'Trending' }).as('trending');
        cy.findByRole('link', { name: 'This Week' }).as('week');
        cy.findByRole('link', { name: 'This Month' }).as('month');
        cy.findByRole('link', { name: 'This Year' }).as('year');
        cy.findByRole('link', { name: 'All Time' }).as('allTime');

        cy.get('@trending').should('have.attr', 'aria-current', 'page');

        cy.get('@week').should('not.have.attr', 'aria-current');
        cy.get('@month').should('not.have.attr', 'aria-current');
        cy.get('@year').should('not.have.attr', 'aria-current');
        cy.get('@allTime').should('not.have.attr', 'aria-current');
      });
    });

    it('should navigate to Week view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Week' }).as('week');
        cy.get('@week').should('not.have.attr', 'aria-current');
        cy.get('@week').click();
      });

      cy.url().should('contain', '/top/this-week');
      cy.findByRole('heading', { name: 'This Week' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Week' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to Month view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Month' }).as('month');
        cy.get('@month').should('not.have.attr', 'aria-current');
        cy.get('@month').click();
      });

      cy.url().should('contain', '/top/this-month');
      cy.findByRole('heading', { name: 'This Month' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Month' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to Year view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Year' }).as('year');
        cy.get('@year').should('not.have.attr', 'aria-current');
        cy.get('@year').click();
      });

      cy.url().should('contain', '/top/this-year');
      cy.findByRole('heading', { name: 'This Year' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'This Year' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to All Time view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'All Time' }).as('allTime');
        cy.get('@allTime').should('not.have.attr', 'aria-current');
        cy.get('@allTime').click();
      });

      cy.url().should('contain', '/top/all-time');
      cy.findByRole('heading', { name: 'All Time' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'All Time' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('should navigate to Most Recent view', () => {
      cy.findByRole('heading', { name: 'Trending' });
      cy.findByRole('button', { name: 'Change feed view' }).click();

      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'Most Recent' }).as('mostRecent');
        cy.get('@mostRecent').should('not.have.attr', 'aria-current');
        cy.get('@mostRecent').click();
      });

      cy.url().should('contain', '/top/most-recent');
      cy.findByRole('heading', { name: 'Most Recent' });

      // Check that the dropdown now indicates the new page
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
        cy.findByRole('link', { name: 'Most Recent' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      });
    });

    it('shows the sidebar on all feed views', () => {
      // Default Feed view (Trending)
      cy.findByRole('heading', { name: '#tag1' });
      cy.findByRole('heading', { name: 'Listings' });

      // Week view
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('link', { name: 'This Week' }).click();
      cy.url().should('contain', '/top/this-week');
      cy.findByRole('heading', { name: 'This Week' });
      cy.findByRole('heading', { name: '#tag1' });
      cy.findByRole('heading', { name: 'Listings' });

      // Month view
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('link', { name: 'This Month' }).click();
      cy.url().should('contain', '/top/this-month');
      cy.findByRole('heading', { name: 'This Month' });
      cy.findByRole('heading', { name: '#tag1' });
      cy.findByRole('heading', { name: 'Listings' });

      // Year view
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('link', { name: 'This Year' }).click();
      cy.url().should('contain', '/top/this-year');
      cy.findByRole('heading', { name: 'This Year' });
      cy.findByRole('heading', { name: '#tag1' });
      cy.findByRole('heading', { name: 'Listings' });

      // All Time view
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('link', { name: 'All Time' }).click();
      cy.url().should('contain', '/top/all-time');
      cy.findByRole('heading', { name: 'All Time' });
      cy.findByRole('heading', { name: '#tag1' });
      cy.findByRole('heading', { name: 'Listings' });

      // Most Recent view
      cy.findByRole('button', { name: 'Change feed view' }).click();
      cy.findByRole('link', { name: 'Most Recent' }).click();
      cy.url().should('contain', '/top/most-recent');
      cy.findByRole('heading', { name: 'Most Recent' });
      cy.findByRole('heading', { name: '#tag1' });
      cy.findByRole('heading', { name: 'Listings' });
    });
  });
});
