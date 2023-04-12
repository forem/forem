const campaignHtml = `
<div>
  <h1>This is a test campaign</h1>
  <button id="js-hero-banner__x">Dismiss</button>
</div>
`;

describe('Home Feed Hero Area', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createHtmlVariant({
          name: 'TestCampaignHtml',
          html: campaignHtml,
          approved: true,
        }).then(() => {
          cy.setCampaign({
            display_name: 'Test Campaign',
            hero_html_variant_name: 'TestCampaignHtml',
          }).then(() => {
            cy.visit('/');
          });
        });
      });
    });
  });

  context('when there is an active campaign', () => {
    it('displays a banner that can be dismissed', () => {
      cy.get('[aria-label="Campaign banner"]')
        .as('heroArea')
        .contains('This is a test campaign')
        .should('exist');

      cy.get('@heroArea').within(() => {
        cy.get('#js-hero-banner__x').click();
      });

      cy.get('@heroArea').should('not.be.visible');
    });

    it('does not display the banner if the campaign has been dismissed', () => {
      cy.get('[aria-label="Campaign banner"]').within(() => {
        cy.get('#js-hero-banner__x').click();
      });

      cy.reload();

      cy.get('[aria-label="Campaign banner"]').should('not.be.visible');
    });
  });
});
