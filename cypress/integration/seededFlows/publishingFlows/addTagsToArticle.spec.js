describe('Add tags to article', () => {
  const exampleTopTags = [
    { name: 'tagone' },
    {
      name: 'tagtwo',
      rules_html:
        '<p>Here are some rules <a href="//www.test.com">link here</a></p>\n',
    },
  ];

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/new');
    });
  });

  it('automatically suggests top tags when field is focused', () => {
    cy.intercept('/tags/suggest', exampleTopTags);
    cy.findByRole('textbox', { name: 'Post Tags' }).focus();

    cy.findByRole('button', { name: 'tagone' }).should('exist');
    cy.findByRole('button', {
      name: 'tagtwo',
    }).should('exist');
  });

  it('automatically suggests top tags again after tag insertion', () => {
    cy.intercept('/tags/suggest', exampleTopTags);
    cy.findByRole('textbox', { name: 'Post Tags' }).clear().type('something,');

    // Search is in progress, top tags which don't match shouldn't be shown
    cy.findByRole('button', { name: 'tagone' }).should('not.exist');
    cy.findByRole('button', {
      name: 'tagtwo',
    }).should('not.exist');

    // Users initiating fresh search after comma
    cy.findByRole('textbox', { name: 'Post Tags' }).focus();
    cy.findByRole('button', { name: 'tagone' }).should('exist');
    cy.findByRole('button', {
      name: 'tagtwo',
    }).should('exist');
  });

  it("doesn't suggest top tags already added", () => {
    cy.intercept('/tags/suggest', exampleTopTags);
    cy.findByRole('textbox', { name: 'Post Tags' }).focus();
    cy.findByRole('button', { name: 'tagone' }).click();

    cy.findByRole('button', { name: 'tagone' }).should('not.exist');
    cy.findByRole('button', {
      name: 'tagtwo',
    }).should('exist');
  });
});
