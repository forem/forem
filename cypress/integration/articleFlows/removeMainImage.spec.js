describe('Remove main image v2 editor', () => {
  const title = 'Test Article';
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title,
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
          mainImage:
            'https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/twitter/248/dog-face_1f436.png',
        }).then((response) => {
          cy.visit(`${response.body.current_state_path}/edit`);
        });
      });
    });
  });

  describe("Removing the article's main/cover image", () => {
    it('should successfully remove the image', () => {
      cy.findByText('Remove').click();
      cy.findByText('Save changes').click();
      cy.findByAltText(`Cover image for ${title}`).should('not.exist');
    });
  });
});
