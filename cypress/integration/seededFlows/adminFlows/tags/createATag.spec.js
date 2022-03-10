describe('Create a tag', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/content_manager/tags/new');
    });
  });

  it('should create a tag', () => {
    const tagName = 'newtag';
    const aliasFor = 'tag1';
    const prettyName = 'new tag';
    const shortSummary = 'summary of tag';
    const rulesMarkdown = '# Some rules';
    const submissionTemplate = 'Template';
    const wikiBodyMarkdown = '# Some markdown';
    const tagColor = '#ababab';

    cy.findByRole('heading', { name: 'New Tag' });
    cy.findByRole('textbox', { name: 'Name' }).type(tagName);
    cy.findByRole('textbox', { name: 'Alias for' }).type(aliasFor);
    cy.findByRole('textbox', { name: 'Pretty name' }).type(prettyName);
    cy.findByRole('checkbox', { name: 'Requires approval' }).check();
    cy.findByRole('textbox', { name: 'Short summary' }).type(shortSummary);
    cy.findByRole('textbox', { name: 'Rules markdown' }).type(rulesMarkdown);
    cy.findByRole('textbox', { name: 'Submission template' }).type(
      submissionTemplate,
    );
    cy.findByRole('textbox', { name: 'Wiki body markdown' }).type(
      wikiBodyMarkdown,
    );

    // A button should exist in addition to the input
    cy.findByRole('button', { name: 'Tag color' });
    cy.findByRole('textbox', { name: 'Tag color' }).enterIntoColorInput(
      tagColor,
    );
    cy.findByRole('button', { name: 'Create Tag' }).click();

    cy.findByText('newtag has been created!').should('exist');

    // Check values were created successfully
    cy.findByRole('heading', { name: `#${tagName}` });
    cy.findByRole('textbox', { name: 'Alias for' }).should(
      'have.value',
      aliasFor,
    );
    cy.findByRole('textbox', { name: 'Pretty name' }).should(
      'have.value',
      prettyName,
    );
    cy.findByRole('checkbox', { name: 'Requires approval' }).should(
      'be.checked',
    );
    cy.findByRole('textbox', { name: 'Short summary' }).should(
      'have.value',
      shortSummary,
    );
    cy.findByRole('textbox', { name: 'Rules markdown' }).should(
      'have.value',
      rulesMarkdown,
    );
    cy.findByRole('textbox', { name: 'Submission template' }).should(
      'have.value',
      submissionTemplate,
    );
    cy.findByRole('textbox', { name: 'Wiki body markdown' }).should(
      'have.value',
      wikiBodyMarkdown,
    );
    cy.findByRole('textbox', { name: 'Tag color' }).should(
      'have.value',
      tagColor,
    );
  });
});
