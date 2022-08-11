describe('Moderation Tools for Posts', () => {
  // Helper function for pipe command
  const click = ($el) => $el.click();

  beforeEach(() => {
    cy.testSetup();
  });

  it('should not load moderation tools for a post when the logged on user is not a trusted user', () => {
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
        cy.findByRole('button', { name: 'Moderation' }).should('not.exist');
      });
    });
  });

  it('should not load moderation tools for a post when not logged in', () => {
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.visit('/admin_mcadmin/test-article-slug').then(() => {
      cy.findByRole('button', { name: 'Moderation' }).should('not.exist');
    });
  });

  context('as admin user', () => {
    beforeEach(() => {
      cy.fixture('users/adminUser.json').as('adminUser');
    });

    it('should not alter tags from a post if a reason is not specified', () => {
      cy.get('@adminUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/tag-test-article').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).click();

          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            // We use `pipe` here to retry the click, as the animation of the mod tools opening can sometimes cause the button to not be ready yet
            cy.findByRole('button', { name: 'Open adjust tags section' })
              .as('adjustTagsButton')
              .pipe(click)
              .should('have.attr', 'aria-expanded', 'true');

            cy.findByRole('button', { name: '#tag1 Remove tag' }).click();
            cy.findByRole('button', { name: 'Submit' }).click();
          });

          cy.findByTestId('snackbar').should('not.exist');
        });
      });
    });

    it('should show Feature Post button on an unfeatured post', () => {
      cy.get('@adminUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/unfeatured-article-slug').then(
          () => {
            cy.findByRole('button', { name: 'Moderation' }).click();

            cy.getIframeBody('[title="Moderation panel actions"]').within(
              () => {
                cy.findByRole('button', { name: 'Feature Post' }).should(
                  'exist',
                );
              },
            );
          },
        );
      });
    });

    it('should show Unfeature Post button on a featured post', () => {
      cy.get('@adminUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).click();

          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            cy.findByRole('button', { name: 'Unfeature Post' }).should('exist');
          });
        });
      });
    });

    it('should show Unpublish Post button on a published post', () => {
      cy.get('@adminUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).click();

          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            cy.findByRole('button', { name: 'Unpublish Post' }).should('exist');
          });
        });
      });
    });
  });

  describe('moderator user', () => {
    beforeEach(() => {
      cy.fixture('users/moderatorUser.json').as('moderatorUser');
    });

    it('should load moderation tools on a post', () => {
      cy.get('@moderatorUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).should('exist');
        });
      });
    });

    it('should not show Feature Post button on a post', () => {
      cy.get('@moderatorUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/unfeatured-article-slug').then(
          () => {
            cy.findByRole('button', { name: 'Moderation' }).click();

            cy.getIframeBody('[title="Moderation panel actions"]').within(
              () => {
                cy.findByRole('button', { name: 'Feature Post' }).should(
                  'not.exist',
                );
              },
            );
          },
        );
      });
    });

    it('should show Unpublish Post button on a published post', () => {
      cy.get('@moderatorUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).click();

          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            cy.findByRole('button', { name: 'Unpublish Post' }).should('exist');
          });
        });
      });
    });

    it('should show Adjust tags button on a published post', () => {
      cy.get('@moderatorUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).click();

          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            // We use `pipe` here to retry the click, as the animation of the mod tools opening can sometimes cause the button to not be ready yet
            cy.findByRole('button', { name: 'Open adjust tags section' })
              .as('adjustTagsButton')
              .pipe(click)
              .should('have.attr', 'aria-expanded', 'true');
          });
        });
      });
    });

    context('when unpublishing all posts', () => {
      beforeEach(() => {
        cy.get('@moderatorUser').then((user) => {
          cy.loginAndVisit(user, '/series_user/series-test-article-slug');
          cy.findByRole('heading', { level: 1, name: 'Series test article' });
          cy.findByRole('button', { name: 'Moderation' }).click();
        });
      });

      it('unpublishes all posts', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', {
            name: /Unpublish all posts for series_user/i,
          }).click();
        });

        cy.getModal().within(() => {
          cy.findByRole('button', { name: 'Unpublish all posts' }).click();
        });

        cy.findByTestId('snackbar')
          .contains(
            'Posts are being unpublished in the background. The job will complete soon.',
          )
          .should('exist');
      });
    });

    context('when suspending user', () => {
      beforeEach(() => {
        cy.get('@moderatorUser').then((user) => {
          cy.loginAndVisit(user, '/series_user/series-test-article-slug');
          cy.findByRole('heading', { level: 1, name: 'Series test article' });
          cy.findByRole('button', { name: 'Moderation' }).click();
        });
      });

      it('should show Suspend User button', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');

          cy.findByRole('button', {
            name: 'Suspend series_user',
          }).should('exist');
        });
      });

      it('should not suspend the user when no reason given', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');

          cy.findByRole('button', {
            name: 'Suspend series_user',
          }).click();
        });
        cy.getModal().within(() => {
          cy.findByRole('button', { name: 'Submit & Suspend' }).click();

          cy.findByTestId('suspension-reason-error')
            .contains('You must give a reason for this action.')
            .should('exist');
        });
      });

      it('should suspend the user when suspension reason given', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');

          cy.findByRole('button', {
            name: 'Suspend series_user',
          }).click();
        });
        cy.getModal().within(() => {
          cy.findByRole('textbox', { name: 'Note:' }).type(
            'My suspension reason',
          );

          cy.findByRole('button', { name: 'Submit & Suspend' }).click();
        });

        cy.findByTestId('snackbar')
          .contains('Success! series_user has been updated.')
          .should('exist');

        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');

          cy.findByRole('button', {
            name: 'Suspend series_user',
          }).should('not.exist');

          cy.findByRole('button', {
            name: 'Unsuspend series_user',
          }).should('exist');
        });
      });
    });

    context('when unsuspending user', () => {
      beforeEach(() => {
        cy.get('@moderatorUser').then((user) => {
          cy.loginAndVisit(user, '/suspended_user/suspended-user-article-slug');
          cy.findByRole('heading', {
            level: 1,
            name: 'Suspended user article',
          });
          cy.findByRole('button', { name: 'Moderation' }).click();
        });
      });

      it('should not unsuspend the user when no reason given', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', {
            name: 'Unsuspend suspended_user',
          }).click();
        });
        cy.getModal().within(() => {
          cy.findByRole('button', { name: 'Submit & Unsuspend' }).click();
          cy.findByTestId('unsuspension-reason-error')
            .contains('You must give a reason for this action.')
            .should('exist');
        });
      });

      it('should unsuspend the user when reason given', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', {
            name: 'Unsuspend suspended_user',
          }).click();
        });

        cy.getModal().within(() => {
          cy.findByRole('textbox', { name: 'Note:' }).type(
            'My unsuspension reason',
          );
          cy.findByRole('button', { name: 'Submit & Unsuspend' }).click();
        });

        cy.findByTestId('snackbar')
          .contains('Success! suspended_user has been updated.')
          .should('exist');

        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');

          cy.findByRole('button', {
            name: 'Unsuspend suspended_user',
          }).should('not.exist');

          cy.findByRole('button', {
            name: 'Suspend suspended_user',
          }).should('exist');
        });
      });
    });
  });

  context('as trusted user', () => {
    beforeEach(() => {
      cy.fixture('users/trustedUser.json').as('trustedUser');
    });

    it('should load moderation tools on a post', () => {
      cy.get('@trustedUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).should('exist');
        });
      });
    });

    it('should not show Feature Post button on a post', () => {
      cy.get('@trustedUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/unfeatured-article-slug').then(
          () => {
            cy.findByRole('button', { name: 'Moderation' }).click();

            cy.getIframeBody('[title="Moderation panel actions"]').within(
              () => {
                cy.findByRole('button', { name: 'Feature Post' }).should(
                  'not.exist',
                );
              },
            );
          },
        );
      });
    });

    describe('flag-user flow', () => {
      beforeEach(() => {
        cy.get('@trustedUser').then((user) => {
          cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug');
          cy.findByRole('heading', { level: 1, name: 'Test article' });
          cy.findByRole('button', { name: 'Moderation' }).click();
        });
      });

      it('should show error message if flag-user radio is unchecked', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', { name: 'Flag admin_mcadmin' }).click();
        });
        cy.getModal().within(() => {
          cy.findByRole('button', { name: 'Confirm Flag' }).click();
          cy.findByTestId('unselected-radio-error')
            .contains('You must check the radio button first.')
            .should('exist');
        });
      });

      it('should flag the user if flag-user radio is checked', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', { name: 'Flag admin_mcadmin' }).click();
        });

        cy.getModal().within(() => {
          const flagUserRadioName =
            "Make all posts by admin_mcadmin less visible admin_mcadmin consistently posts content that violates DEV(local)'s code of conduct because it is harassing, offensive or spammy.";
          cy.findByRole('radio', {
            name: flagUserRadioName,
          }).check();
          cy.findByRole('button', { name: 'Confirm Flag' }).click();
        });

        cy.findByTestId('snackbar')
          .contains('All posts by this author will be less visible.')
          .should('exist');
      });

      it('should unflag the user if user was previously flagged', () => {
        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', { name: 'Flag admin_mcadmin' }).click();
        });

        cy.getModal().within(() => {
          cy.get('#flag-user-radio-input').check();
          cy.findByRole('button', { name: 'Confirm Flag' }).click();
        });

        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open admin actions' })
            .as('moderatingActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');
          cy.findByRole('button', { name: 'Unflag admin_mcadmin' }).click();
        });

        cy.getModal().within(() => {
          cy.findByRole('button', { name: 'Confirm Unflag' }).click();
        });

        cy.findByTestId('snackbar')
          .contains('You have unflagged this author successfully.')
          .should('exist');
      });
    });
  });
});
