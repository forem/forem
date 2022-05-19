describe('Creator Settings Page', () => {
  const { baseUrl } = Cypress.config();

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/creatorUser.json').as('creator');
    cy.get('@creator').then((creator) => {
      cy.loginCreator(creator);
    });

    cy.visit(`${baseUrl}admin/creator_settings/new`);
  });

  it('should submit the creator settings form', () => {
    // should display a welcome message
    cy.findByText("Lovely! Let's set up your Forem.").should('be.visible');
    cy.findByText('No stress, you can always change it later.').should(
      'be.visible',
    );

    // should contain a community name and update the field properly
    cy.findByRole('textbox', { name: /community name/i })
      .as('communityName')
      .invoke('attr', 'placeholder')
      .should('eq', 'Climbing Life');
    cy.get('@communityName').type('Climbing Life');

    // should contain a logo upload field and upload a logo upon click
    cy.findByLabelText(/logo/i, { selector: 'input' }).attachFile(
      '/images/admin-image.png',
    );
    cy.findByRole('img', { name: /preview of logo selected/i }).should(
      'be.visible',
    );

    // should contain a brand color field, enhanced with popover picker
    cy.findByRole('button', { name: /^Brand color/ }).should('be.visible');
    cy.findByRole('textbox', { name: /^Brand color/ }).enterIntoColorInput(
      '#BC1A90',
    );

    // should contain a 'Who can join this community?' radio selector field and allow selection upon click
    cy.findByRole('group', { name: /^Who can join this community/i })
      .as('joinCommunity')
      .should('be.visible');

    cy.get('@joinCommunity').within(() => {
      cy.findByRole('radio', { name: /everyone/i })
        .check()
        .should('be.checked');

      cy.findByRole('radio', { name: /invite only/i }).should('not.be.checked');
    });

    // should contain a 'Who can view content in this community?' radio selector field and allow selection upon click
    cy.findByRole('group', {
      name: /^Who can view content in this community/i,
    })
      .as('viewCommunity')
      .should('be.visible');

    cy.get('@viewCommunity').within(() => {
      cy.findByRole('radio', { name: /members only/i })
        .check()
        .should('be.checked');

      cy.findByRole('radio', { name: /everyone/i }).should('not.be.checked');
    });

    // should contain a 'I agree to uphold our Code of Conduct' checkbox field and allow selection upon click
    cy.findByRole('group', {
      name: /^finally, please agree to the following:/i,
    }).within(() => {
      cy.findByRole('checkbox', {
        name: 'I agree to uphold our Code of Conduct.',
      }).check();
      cy.findByRole('checkbox', {
        name: 'I agree to our Terms and Conditions.',
      }).check();
    });

    // should redirect the creator to the home page when the form is completely filled out and 'Finish' is clicked
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should('equal', baseUrl);
  });

  it('should not submit the creator settings form if any of the fields are not filled out', () => {
    // TODO: Circle back around to testing this once the styling for the form is complete
    cy.findByRole('textbox', { name: /community name/i }).should(
      'have.attr',
      'required',
    );

    // should not redirect the creator to the home page when the form is not completely filled out and 'Finish' is clicked
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should('equal', `${baseUrl}admin/creator_settings/new`);
  });

  context('color contrast ratios', () => {
    it('should show an error when the contrast ratio of a brand color is too low', () => {
      const lowContrastColor = '#a6e8a6';

      // The rich color picker should render with a button as well as an input
      cy.findByRole('button', { name: /^Brand color/ });
      cy.findByRole('textbox', { name: /^Brand color/ }).enterIntoColorInput(
        lowContrastColor,
      );

      cy.findByText(
        /^The selected color must be darker for accessibility purposes./,
      ).should('be.visible');
    });

    it('should not show an error when the contrast ratio of a brand color is good', () => {
      const adequateContrastColor = '#25544b';

      // The rich color picker should render with a button as well as an input
      cy.findByRole('button', { name: /^Brand color/ });
      cy.findByRole('textbox', { name: /^Brand color/ }).enterIntoColorInput(
        adequateContrastColor,
      );

      cy.findByText(
        /^The selected color must be darker for accessibility purposes./,
      ).should('not.exist');
    });
  });

  context('brand color updates', () => {
    it('should not update the brand color if the color contrast ratio is low', () => {
      const lowContrastColor = '#a6e8a6';
      const lowContrastRgbColor = 'rgb(166, 232, 166)';

      // The rich color picker should render with a button as well as an input
      cy.findByRole('button', { name: /^Brand color/ });
      cy.findByRole('textbox', { name: /^Brand color/ }).enterIntoColorInput(
        lowContrastColor,
      );

      cy.findByText(
        /^The selected color must be darker for accessibility purposes./,
      ).should('be.visible');

      cy.findByRole('button', { name: 'Finish' }).should(
        'not.have.css',
        'background-color',
        lowContrastRgbColor,
      );
    });

    it('should update the colors on the form when a new brand color is selected', () => {
      const color = '#25544b';
      const rgbColor = 'rgb(37, 84, 75)';

      // The rich color picker should render with a button as well as an input
      cy.findByRole('button', { name: /^Brand color/ });
      cy.findByRole('textbox', { name: /^Brand color/ }).enterIntoColorInput(
        color,
      );

      cy.findByRole('button', { name: 'Finish' }).should(
        'have.css',
        'background-color',
        rgbColor,
      );

      cy.findAllByRole('radio', { name: /members only/i })
        .check()
        .should('have.css', 'background-color', rgbColor)
        .should('have.css', 'border-color', rgbColor);

      cy.findByRole('link', { name: /Forem Admin Guide/i }).should(
        'have.css',
        'background-color',
        rgbColor,
      );

      cy.findByRole('textbox', { name: /community name/i })
        .clear()
        .focus()
        .type('Climbing Life')
        .should('have.css', 'border-color', rgbColor);
    });
  });
});

describe('Admin -> Customization -> Config -> Images', () => {
  // NOTE: These tests are here for the moment as we still haven't figured out how to enable
  // feature flags in the context of E2E tests.
  // These test should really live in the seeded flows for admin.
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/creatorUser.json').as('creator');
    cy.get('@creator').then((creator) => {
      cy.loginCreator(creator);
    });
  });

  it('should upload an image from the admin -> customization -> config -> images section', () => {
    cy.visit(`/admin/customization/config`);

    cy.findByText('Images').click();
    cy.findByLabelText(/^Logo$/i).attachFile('/images/admin-image.png');
    cy.findByRole('button', { name: /Update image settings/i }).click();

    cy.findByTestId('snackbar')
      .should('be.visible')
      .should('have.text', 'Successfully updated settings.');

    cy.findByRole('img', { name: /preview of logo selected/i }).then(
      ([previewImage]) => {
        cy.findAllByRole('img', { name: /DEV\(local\)/i }).then((images) => {
          // Some images being picked up are SVGs which we don't want to check
          const logoImages = [...images].filter(
            (image) => image.tagName === 'IMG' && image !== previewImage,
          );

          // Ensure any site logos have te same URL as the preview logo
          for (const image of logoImages) {
            cy.get(image).should('have.attr', 'src', previewImage.src);
          }
        });
      },
    );
  });

  it('should not upload an image from the admin -> customization -> config -> images section', () => {
    cy.visit(`/admin/customization/config`);

    cy.findByText('Images').click();
    cy.findByRole('button', { name: /Update image settings/i }).click();

    cy.findByTestId('snackbar')
      .should('be.visible')
      .should('have.text', 'Successfully updated settings.');

    cy.findByRole('img', { name: /preview of logo selected/i }).should(
      'not.exist',
    );

    cy.findAllByRole('img', { name: /DEV\(local\)/i }).should('not.exist');

    // we should see the community name instead of a logo
    cy.get('.site-logo__community-name')
      .findByText(/DEV\(local\)/i)
      .should('be.visible');
  });
});
