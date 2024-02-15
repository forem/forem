describe('Adjust post tags', () => {
  describe('from /mod page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/mod');
      });
    });

    it('should add a tag to a post', () => {
      cy.findByRole('heading', { name: 'Tag test article' }).click();
      cy.getIframeBody('.article-iframe')
        .findByRole('link', { name: /# tag2/ })
        .should('not.exist');

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', { name: 'Open adjust tags section' }).click();
        cy.findByTestId('add-tag-button').click();
        cy.findByPlaceholderText('Add a tag').type('tag2');
        cy.findByPlaceholderText('Reason to add tag (optional)').type(
          'testing',
        );
        cy.findByRole('button', { name: 'Add tag' }).click();
      });

      cy.getIframeBody('.article-iframe').within(() => {
        cy.findByText('The #tag2 tag was added.');
        cy.findByRole('link', { name: /# tag2/ });
      });
    });

    it('should remove a tag from a post', () => {
      cy.findByRole('heading', { name: 'Tag test article' }).click();
      cy.getIframeBody('.article-iframe').findByRole('link', {
        name: /# tag1/,
      });

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', { name: 'Open adjust tags section' }).click({
          force: true,
        });
        cy.findByText('tag1').click();
        cy.findByPlaceholderText('Reason to remove tag (optional)').type(
          'testing',
        );

        cy.findByRole('button', { name: 'Remove tag' }).click();
      });

      cy.getIframeBody('.article-iframe').within(() => {
        cy.findByText('The #tag1 tag was removed.');
        cy.findByRole('link', { name: /# tag1/ }).should('not.exist');
      });
    });

    // Helper function for pipe command
    const click = ($el) => $el.click();

    // Disabling for now as the flake rate from timeouts and missed elements is affecting
    // the pace of reviewing and merging other work.
    it.skip('should show previous tag adjustments', () => {
      cy.intercept('/tag_adjustments').as('tagAdjustmentRequest');
      cy.findByRole('heading', { name: 'Tag test article' }).click();
      // cy.findByRole('main').as('main');

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        // Click listeners are attached async so we use pipe() to retry click until condition met
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByTestId('add-tag-button').click();
        cy.findByPlaceholderText('Add a tag').type('tag2');
        cy.findByPlaceholderText('Reason to add tag (optional)').type(
          'testing',
        );
        cy.findByRole('button', { name: 'Add tag' }).click();
      });

      cy.wait('@tagAdjustmentRequest');

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByText('tag1').click();
        cy.get('#tag-removal-reason-tag1').type('testing');

        cy.findByRole('button', { name: 'Remove tag' }).click();
      });

      cy.wait('@tagAdjustmentRequest');
      // these reloads 'make the test work for now' but inconsistently,
      // which may be contributing to flaky timeouts and missed/uninteractive elements as cy runs
      cy.reload();
      cy.findByRole('heading', { name: 'Tag test article' }).click();

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('heading', {
          name: 'Previous tag adjustments',
        }).scrollIntoView();
        cy.get('#tag-moderation-history')
          .find('.tag-adjustment')
          .should(($div) => {
            expect($div[0].innerText).to.contain(
              '# tag1 removed by Admin McAdmin\ntesting',
            );
            expect($div[1].innerText).to.contain(
              '# tag2 added by Admin McAdmin\ntesting',
            );
          });
      });
    });
  });

  describe('from /mod/tagname page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/mod/tag1');
      });
    });

    it('should add a tag to a post', () => {
      cy.findByRole('heading', { name: 'Tag test article' }).click();
      cy.getIframeBody('.article-iframe')
        .findByRole('link', { name: /#tag2/ })
        .should('not.exist');

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', { name: 'Open adjust tags section' }).click();
        cy.findByTestId('add-tag-button').click();
        cy.findByPlaceholderText('Add a tag').type('tag2');
        cy.findByPlaceholderText('Reason to add tag (optional)').type(
          'testing',
        );
        cy.findByRole('button', { name: 'Add tag' }).click();
      });

      cy.getIframeBody('.article-iframe').within(() => {
        cy.findByText('The #tag2 tag was added.');
        cy.findByRole('link', { name: /# tag2/ });
      });
    });

    it('should remove a tag from a post', () => {
      cy.findByRole('heading', { name: 'Tag test article' }).click();
      cy.getIframeBody('.article-iframe').findByRole('link', {
        name: /# tag1/,
      });

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', { name: 'Open adjust tags section' }).click({
          force: true,
        });

        cy.findByText('tag1').click();
        cy.findByPlaceholderText('Reason to remove tag (optional)').type(
          'testing',
        );

        cy.findByRole('button', { name: 'Remove tag' }).click();
      });

      cy.getIframeBody('.article-iframe').within(() => {
        cy.findByText('The #tag1 tag was removed.');
        cy.findByRole('link', { name: /# tag1/ }).should('not.exist');
      });
    });

    // Helper function for pipe command
    const click = ($el) => $el.click();

    // Disabling these for now as the flake rate from timeouts and missed elements is affecting
    // the pace of reviewing and merging other work.
    it.skip('should show previous tag adjustments', () => {
      cy.intercept('/tag_adjustments').as('tagAdjustmentRequest');
      cy.findByRole('heading', { name: 'Tag test article' }).click();
      // cy.findByRole('main').as('main');

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        // Click listeners are attached async so we use pipe() to retry click until condition met
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByTestId('add-tag-button').click();
        cy.findByPlaceholderText('Add a tag').type('tag2');
        cy.findByPlaceholderText('Reason to add tag (optional)').type(
          'testing',
        );
        cy.findByRole('button', { name: 'Add tag' }).click();
      });

      cy.wait('@tagAdjustmentRequest');

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByText('tag1').click();
        cy.get('#tag-removal-reason-tag1').type('testing');

        cy.findByRole('button', { name: 'Remove tag' }).click();
      });

      cy.wait('@tagAdjustmentRequest');
      cy.visit('/mod/tag2');
      cy.findByRole('heading', { name: 'Tag test article' }).click();

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('heading', {
          name: 'Previous tag adjustments',
        }).scrollIntoView();
        cy.get('#tag-moderation-history')
          .find('.tag-adjustment')
          .should(($div) => {
            expect($div[0].innerText).to.contain(
              '# tag1 removed by Admin McAdmin\ntesting',
            );
            expect($div[1].innerText).to.contain(
              '# tag2 added by Admin McAdmin\ntesting',
            );
          });
      });
    });
  });

  describe('from article page', () => {
    // Helper function for pipe command
    const click = ($el) => $el.click();

    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/tag-test-article');
      });
    });

    it('should add a tag to a post', () => {
      cy.findByRole('heading', { name: 'Tag test article' });
      cy.findByRole('main').as('main');

      cy.findByRole('link', { name: /# tag2/ }).should('not.exist');

      cy.findByRole('button', { name: 'Moderation' }).click();
      cy.getIframeBody('#mod-container').within(() => {
        // Click listeners are attached async so we use pipe() to retry click until condition met
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByTestId('add-tag-button').click();
        cy.findByPlaceholderText('Add a tag').type('tag2');
        cy.findByPlaceholderText('Reason to add tag (optional)').type(
          'testing',
        );
        cy.findByRole('button', { name: 'Add tag' }).click();
      });

      cy.get('@main').within(() => {
        cy.findByRole('link', { name: /# tag2/ });
      });
    });

    it('should remove a tag from a post', () => {
      cy.findByRole('heading', { name: 'Tag test article' });
      cy.findByRole('main').as('main');

      cy.findByRole('link', { name: /# tag1/ }).should('exist');
      cy.findByRole('button', { name: 'Moderation' }).click();

      cy.getIframeBody('#mod-container').within(() => {
        // Click listeners are attached async so we use pipe() to retry click until condition met
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByText('tag1').click();
        cy.findByPlaceholderText('Reason to remove tag (optional)').type(
          'testing',
        );

        cy.findByRole('button', { name: 'Remove tag' }).click();
      });

      cy.get('@main').within(() => {
        cy.findByRole('link', { name: /# tag1/ }).should('not.exist');
      });
    });

    // Disabling these for now as the flake rate from timeouts and missed elements is affecting
    // the pace of reviewing and merging other work.
    it.skip('should show previous tag adjustments', () => {
      cy.intercept('/tag_adjustments').as('tagAdjustmentRequest');
      cy.findByRole('heading', { name: 'Tag test article' });

      cy.findByRole('button', { name: 'Moderation' }).click();
      cy.getIframeBody('#mod-container').within(() => {
        // Click listeners are attached async so we use pipe() to retry click until condition met
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByTestId('add-tag-button').click();
        cy.findByPlaceholderText('Add a tag').type('tag2');
        cy.findByPlaceholderText('Reason to add tag (optional)').type(
          'testing',
        );
        cy.findByRole('button', { name: 'Add tag' }).click();
      });

      cy.wait('@tagAdjustmentRequest');
      //  Manually reloading here to clear up async race conditions in cypress as the page is reloaded.
      // Currently, we manually reload the page as an adjustment occurs, which seems to cause
      // indeterminate waits for the javascript to be present on the reloaded page,
      // so some elements end up existing but not interactive on click.
      cy.reload();

      cy.findByRole('button', { name: 'Moderation' }).click();
      cy.getIframeBody('#mod-container').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByText('tag1').click();
        cy.get('#tag-removal-reason-tag1').type('testing');

        cy.findByRole('button', { name: 'Remove tag' }).click();
      });

      cy.wait('@tagAdjustmentRequest');
      cy.reload();

      cy.findByRole('button', { name: 'Moderation' }).click();
      cy.getIframeBody('#mod-container').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('heading', {
          name: 'Previous tag adjustments',
        }).scrollIntoView();
        cy.get('#tag-moderation-history')
          .find('.tag-adjustment')
          .should(($div) => {
            expect($div[0].innerText).to.contain(
              '# tag1 removed by Admin McAdmin\ntesting',
            );
            expect($div[1].innerText).to.contain(
              '# tag2 added by Admin McAdmin\ntesting',
            );
          });
      });
    });
  });
});
