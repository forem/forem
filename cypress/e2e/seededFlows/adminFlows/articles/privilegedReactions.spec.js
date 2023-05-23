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

  it('should not contain any flags', () => {
    cy.findByText('Article has no flags.').should('exist');
  });

  it('should not contain quality reactions', () => {
    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.findByText('Article has no quality reactions by trusted users.').should(
      'exist',
    );
  });

  it('should display the correct thumb up count', () => {
    cy.get('.flex .crayons-card:nth-child(1) .fs-s').should('contain', '0');
  });

  it('should display the correct thumb down count', () => {
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '0');
  });

  it('should display the correct vomit count', () => {
    cy.get('.flex .crayons-card:nth-child(3) .fs-s').should('contain', '0');
  });

  it('should display the correct score', () => {
    cy.get('.flex .crayons-card:nth-child(4) .fs-s').should('contain', '0');
  });
});

describe('Article flagged by a user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.intercept('POST', '/admin/reactions/*', (req) => {
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
        } else {
          cy.reload();
        }

        res.send(response);
      });
    });

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

  it('should display the correct default data', () => {
    cy.get('.flex .crayons-card:nth-child(3) .fs-s').should('contain', '1');
  });

  it('should display the correct user name', () => {
    cy.get('.flex .crayons-subtitle-3').should(
      'contain',
      'Trusted User 1 \\:/',
    );
  });

  it('should display the open flag status', () => {
    cy.get('.flex .c-indicator').should('be.visible').as('flagStatus');
    cy.get('@flagStatus')
      .should('have.class', 'c-indicator--warning')
      .and('contain', 'Open');
  });

  it('should display the correct score for open flag', () => {
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '-50');
  });

  it('should open the dropdown on button click', () => {
    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('be.visible');
  });

  it('should open the dropdown on button click and close the dropdown on same button click', () => {
    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('be.visible');

    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('not.visible');
  });

  it('should open the dropdown on button click', () => {
    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('be.visible');
  });

  it('should open the dropdown on button click and close the dropdown on same button click', () => {
    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('be.visible');

    cy.get('.c-btn--icon-alone').click();
    cy.get('.crayons-dropdown').should('not.visible');
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

    cy.get('.crayons-dropdown').should('not.be.visible');
  });

  it('should close dropdown on click of "Mark as Invalid"', () => {
    cy.get('.c-btn--icon-alone:first').click();

    cy.get('.crayons-dropdown')
      .find('ul.list-none')
      .should('contain', 'Mark as Invalid')
      .click();

    cy.get('.crayons-dropdown').should('not.be.visible');
  });
});
