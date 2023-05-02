const timeHtml = `
<div>
<h1>This is a test campaign</h1>
  <button id="js-hero-banner__x">Dismiss</button>
  <div class="utc-time" data-datetime=823230245000></div>
  <div class="utc-date" data-datetime=823230245000></div>
  <div class="utc">823230245000</div>
</div>
`;

describe('Time Fixer', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createHtmlVariant({
          name: 'TestTimeHtml',
          html: timeHtml,
          approved: true,
        }).then(() => {
          cy.setCampaign({
            display_name: 'Test Time Campaign',
            hero_html_variant_name: 'TestTimeHtml',
          }).then(() => {
            cy.visit('/');
          });
        });
      });
    });
  });

  afterEach(() => {
    // Dismissing a banner sets a flag in local storage that we want to ensure is removed after each test
    // cy.visit('/404');
    cy.clearLocalStorage();
  });

  context('when utc exist on the page', () => {
    it('displays proper time', () => {
      cy.get('.utc').as('utcTime').should('exist');
    });
  });
});
