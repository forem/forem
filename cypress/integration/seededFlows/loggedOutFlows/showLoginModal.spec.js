describe('Show log in modal', () => {
  const verifyLoginModalBehavior = (getTriggerElement) => {
    getTriggerElement().click();
    cy.findByTestId('modal-container').as('modal');
    cy.get('@modal').findByText('Log in to continue').should('exist');
    cy.get('@modal').findByLabelText('Log in').should('exist');
    cy.get('@modal').findByLabelText('Create new account').should('exist');
    cy.get('@modal').findByRole('button').first().should('have.focus');

    cy.get('@modal').findByRole('button', { name: /Close/ }).click();
    getTriggerElement().should('have.focus');
    cy.findByTestId('modal-container').should('not.exist');
  };

  beforeEach(() => {
    cy.testSetup();
    cy.visit('/');
  });

  it('should show a log in modal on Feed bookmark click', () => {
    cy.findAllByRole('button', { name: /Save/ }).first().as('bookmarkButton');
    // Wait for the click handler to be attached to the button
    cy.get('@bookmarkButton').should('have.attr', 'data-save-initialized');

    verifyLoginModalBehavior(() => cy.get('@bookmarkButton'));
  });

  it('should show login modal for article reaction clicks', () => {
    cy.findAllByText('Test article').last().click();

    cy.findByRole('button', { name: 'Like' }).as('heartReaction');
    cy.findByRole('button', { name: 'React with unicorn' }).as(
      'unicornReaction',
    );
    cy.findByRole('button', { name: 'Add to reading list' }).as(
      'bookmarkReaction',
    );

    ['@heartReaction', '@unicornReaction', '@bookmarkReaction'].forEach(
      (reaction) => {
        verifyLoginModalBehavior(() => cy.get(reaction));
      },
    );
  });

  it('should show login modal for comment subscription', () => {
    cy.findAllByText('Test article').last().click();

    verifyLoginModalBehavior(() =>
      cy.findByRole('button', { name: /Subscribe/ }),
    );
  });

  it('should show login modal for article follow button click', () => {
    cy.viewport('macbook-16');
    cy.findAllByRole('link', { name: 'Test article' })
      .first()
      .click({ force: true });

    cy.get('[data-follow-clicks-initialized]');

    verifyLoginModalBehavior(() =>
      cy
        .findByRole('complementary', { name: 'Author details' })
        .findByRole('button', { name: 'Follow user: Admin McAdmin' }),
    );
  });

  it('should show login modal for tag follow button click', () => {
    cy.visit('/tags');
    cy.findByRole('heading', { name: 'Top tags' });
    cy.get('[data-follow-clicks-initialized]');

    verifyLoginModalBehavior(() =>
      cy.findByRole('button', { name: 'Follow tag: tag1' }),
    );

    cy.visit('/t/tag1');
    cy.findByRole('heading', { name: '# tag1' });

    verifyLoginModalBehavior(() =>
      cy.findByRole('button', { name: 'Follow tag: tag1' }),
    );
  });

  it('should show login modal for user profile follow button click', () => {
    cy.visit('/admin_mcadmin');
    cy.get('[data-follow-clicks-initialized]');

    cy.findByRole('heading', { name: 'Admin McAdmin' });
    verifyLoginModalBehavior(() =>
      cy.findByRole('button', { name: 'Follow user: Admin McAdmin' }),
    );
  });

  it('should show login modal for podcast follow button click', () => {
    cy.visit('/developeronfire');
    cy.get('[data-follow-clicks-initialized]');

    cy.findByRole('heading', {
      name: 'Developer on Fire Developer on Fire Follow',
    });

    verifyLoginModalBehavior(() =>
      cy.findByRole('button', { name: 'Follow podcast: Developer on Fire' }),
    );
  });
});
