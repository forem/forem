describe('New article has empty flags, quality reactions and score', () => {
  let articleId;
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is another test article's contents.`,
          published: true,
        }).then((response) => {
          articleId = response.body.id;
          cy.visit(`/admin/content_manager/articles/${articleId}`);
        });
      });
    });
  });

  it('should update url on flag tab click', () => {
    cy.findByRole('link', { name: 'Flags' }).click();
    cy.url().should(
      'contains',
      `/admin/content_manager/articles/${articleId}?tab=flags`,
    );
  });

  it('should update url on quality reactions tab click', () => {
    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.url().should(
      'contains',
      `/admin/content_manager/articles/${articleId}?tab=quality_reactions`,
    );
  });

  it('should not contain any flags and quality reactions', () => {
    cy.findByText('Article has no flags.').should('exist');

    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.findByText('Article has no quality reactions by trusted users.').should(
      'exist',
    );
  });

  it('should display the correct values for privileged reactions and score', () => {
    // Thumbs-up count
    cy.get('.flex .crayons-card:nth-child(1) .fs-s').should('contain', '0');

    // Thumbs-down count
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '0');

    // Vomit/flag count
    cy.get('.flex .crayons-card:nth-child(3) .fs-s').should('contain', '0');

    //Score
    cy.get('.flex .crayons-card:nth-child(4) .fs-s').should('contain', '0');
  });
});

describe('Article flagged by an admin user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin/content_manager/articles');

        cy.contains('.crayons-subtitle-1 a', 'Punctuation user article')
          .parents('.js-individual-article')
          .find('a[href*="/admin/content_manager/articles/"]')
          .click();
      });
    });
  });

  it('should display the correct default data for flag reaction', () => {
    // Vomit/flag count
    cy.get('.flex .crayons-card:nth-child(3) .fs-s').should('contain', '1');

    // Reaction username
    cy.get('.flex .crayons-subtitle-3').should('contain', 'Admin McAdmin');

    // Shows "Valid" status
    cy.get('.flex .c-indicator').should('be.visible').as('flagStatus');
    cy.get('@flagStatus')
      .should('have.class', 'c-indicator--danger')
      .and('contain', 'Valid');

    // Reeaction score
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '-100');
  });

  it('should open the dropdown on button click and close the dropdown on same button click', () => {
    // Opens the dropdown
    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('be.visible');

    // Closes the dropdown on same button click
    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('not.visible');
  });

  it('should update status to Invalid on click of "Mark as Invalid"', () => {
    cy.intercept('PATCH', '/admin/reactions/**', (req) => {
      req.reply((res) => {
        const { id } = req.body;
        const response = {
          statusCode: 200,
          body: {
            outcome: 'Success',
          },
        };

        if (req.body.removeElement === true) {
          cy.get(`#${id}`).then(($element) => {
            $element.remove();
          });
          cy.get(`#js__reaction__div__hr__${id}`).then(($element) => {
            $element.remove();
          });
        }

        res.send(response);
      });
    }).as('request');

    cy.get('.c-btn--icon-alone:first').click();

    cy.get('.crayons-dropdown')
      .find('ul.list-none')
      .should('contain', 'Mark as Invalid')
      .click();

    cy.wait('@request');

    cy.get('.flex .c-indicator').as('flagStatus');
    cy.get('@flagStatus').should('be.visible');
    cy.get('@flagStatus').should('contain', 'Invalid');
  });
});

describe('Article flagged by a trusted user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin/content_manager/articles');

        cy.contains('.crayons-subtitle-1 a', 'Notification article')
          .parents('.js-individual-article')
          .find('a[href*="/admin/content_manager/articles/"]')
          .click();
      });
    });
  });

  it('should display the open flag status and correct score', () => {
    // Open flag status
    cy.get('.flex .c-indicator').should('be.visible').as('flagStatus');
    cy.get('@flagStatus')
      .should('have.class', 'c-indicator--warning')
      .and('contain', 'Open');

    // Score
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '-50');
  });

  it('should display both "Mark as Valid" and "Mark as Invalid" options in the dropdown', () => {
    cy.get('.c-btn--icon-alone').click();

    cy.get('.crayons-dropdown')
      .find('ul.list-none')
      .should('contain', 'Mark as Valid')
      .and('contain', 'Mark as Invalid');
  });

  it('should close dropdown on click of "Mark as Valid"', () => {
    cy.get('.c-btn--icon-alone:first').click();

    cy.get('.crayons-dropdown')
      .find('ul.list-none')
      .should('contain', 'Mark as Valid')
      .click();

    cy.get('.crayons-dropdown').as('dropdown');
    cy.get('@dropdown').should('not.be.visible');
  });

  it('should update status to Invalid on click of "Mark as Invalid"', () => {
    cy.intercept('PATCH', '/admin/reactions/**', (req) => {
      req.reply((res) => {
        const { id } = req.body;
        const response = {
          statusCode: 200,
          body: {
            outcome: 'Success',
          },
        };

        if (req.body.removeElement === true) {
          cy.get(`#${id}`).then(($element) => {
            $element.remove();
          });
          cy.get(`#js__reaction__div__hr__${id}`).then(($element) => {
            $element.remove();
          });
        }

        res.send(response);
      });
    }).as('request');

    cy.get('.c-btn--icon-alone:first').click();

    cy.get('.crayons-dropdown')
      .find('ul.list-none')
      .should('contain', 'Mark as Invalid')
      .click();

    cy.wait('@request');

    cy.get('.flex .c-indicator').as('flagStatus');
    cy.get('@flagStatus').should('be.visible');
    cy.get('@flagStatus')
      .should('have.class', 'c-indicator--relaxed')
      .and('contain', 'Invalid');
  });

  it('should update status to Valid on click of "Mark as Valid"', () => {
    cy.intercept('PATCH', '/admin/reactions/**', (req) => {
      req.reply((res) => {
        const { id } = req.body;
        const response = {
          statusCode: 200,
          body: {
            outcome: 'Success',
          },
        };

        if (req.body.removeElement === true) {
          cy.get(`#${id}`).then(($element) => {
            $element.remove();
          });
          cy.get(`#js__reaction__div__hr__${id}`).then(($element) => {
            $element.remove();
          });
        }

        res.send(response);
      });
    }).as('request');

    cy.get('.c-btn--icon-alone:first').click();

    cy.get('.crayons-dropdown')
      .find('ul.list-none')
      .findByTestId('mark-as-valid')
      .should('contain', 'Mark as Valid')
      .click();

    cy.wait('@request');

    cy.get('.flex .c-indicator').should('be.visible').as('flagStatus');
    cy.get('@flagStatus').should('contain', 'Valid');
  });
});
