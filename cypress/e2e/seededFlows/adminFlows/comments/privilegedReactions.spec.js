describe('View details link on comments list page in admin area', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit(`/admin/content_manager/comments`);
      });
    });
  });

  it('should contain view details link with correct href', () => {
    cy.findAllByRole('link', { name: 'View Details' }).each(($link) => {
      const href = $link.attr('href');
      const regex = /\/(\d+)/; // Regular expression to match any number in the URL
      expect(href).to.match(regex);
    });
  });
});

describe('New comment with empty flags and reactions', () => {
  let commentId;
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/').then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.createComment({
            content: 'This is a test comment.',
            commentableId: response.body.id,
            commentableType: 'Article',
          }).then((commentResponse) => {
            commentId = commentResponse.body.id;
            cy.visit(`/admin/content_manager/comments/${commentId}`);
          });
        });
      });
    });
  });

  it('should not contain view details link on individual comments page', () => {
    cy.findAllByRole('link', { name: 'View Details' }).should('not.exist');
  });

  it('should update url on flag tab click', () => {
    cy.findByRole('link', { name: 'Flags' }).click();
    cy.url().should(
      'contains',
      `/admin/content_manager/comments/${commentId}?tab=flags`,
    );
  });

  it('should update url on quality reactions tab click', () => {
    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.url().should(
      'contains',
      `/admin/content_manager/comments/${commentId}?tab=quality_reactions`,
    );
  });

  it('should not contain any flags and quality reactions', () => {
    cy.findByText('Comment has no flags.').should('exist');

    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.findByText('Comment has no quality reactions by trusted users.').should(
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

describe('Comment with flags and reactions', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit(`/admin/content_manager/comments`);

        cy.contains('Contains various privileged reactions.')
          .parents('.crayons-card')
          .within(() => {
            cy.contains('View Details').click();
          });
      });
    });
  });

  it('should display the correct values for privileged reactions and score', () => {
    // Thumbs-up count
    cy.get('.flex .crayons-card:nth-child(1) .fs-s').should('contain', '0');

    // Thumbs-down count
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '1');

    // Vomit/flag count
    cy.get('.flex .crayons-card:nth-child(3) .fs-s').should('contain', '1');

    //Score
    cy.get('.flex .crayons-card:nth-child(4) .fs-s').should('contain', '0');
  });
});
