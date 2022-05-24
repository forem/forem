describe('Moderation Tools for Posts', () => {
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

  it('should not alter tags from a post if a reason is not specified', () => {
    cy.fixture('users/adminUser.json').as('adminUser');
    cy.get('@adminUser').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/tag-test-article').then(() => {
        cy.findByRole('button', { name: 'Moderation' }).click();

        // Helper function for pipe command
        const click = ($el) => $el.click();

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

  it('should show Feature Post button on an unfeatured post for an admin user', () => {
    cy.fixture('users/adminUser.json').as('adminUser');
    cy.get('@adminUser').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/unfeatured-article-slug').then(
        () => {
          cy.findByRole('button', { name: 'Moderation' }).click();

          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            cy.findByRole('button', { name: 'Feature Post' }).should('exist');
          });
        },
      );
    });
  });

  it('should show Unfeature Post button on a featured post for an admin user', () => {
    cy.fixture('users/adminUser.json').as('adminUser');
    cy.get('@adminUser').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
        cy.findByRole('button', { name: 'Moderation' }).click();

        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Unfeature Post' }).should('exist');
        });
      });
    });
  });

  context('as trusted user', () => {
    beforeEach(() => {
      cy.fixture('users/trustedUser.json').as('trustedUser');
    });

    it('should load moderation tools on a post for a trusted user', () => {
      cy.get('@trustedUser').then((user) => {
        cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug').then(() => {
          cy.findByRole('button', { name: 'Moderation' }).should('exist');
        });
      });
    });

    it('should not show Feature Post button on a post for a trusted user', () => {
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
  });
});
