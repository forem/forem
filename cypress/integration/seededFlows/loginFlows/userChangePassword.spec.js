import { getInterceptsForLingeringUserRequests } from '../../../util/networkUtils';

describe('User Change Password', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/changePasswordUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/settings/account');
    });
  });

  it('should change the password of a user', () => {
    cy.fixture('users/changePasswordUser.json').as('user');

    const newPassword = 'drowssap';

    cy.findByTestId('update-password-form').as('updatePasswordForm');

    cy.get('@user').then((user) => {
      cy.get('@updatePasswordForm')
        .findByText(/^Current Password$/i)
        .type(user.password);
      cy.get('@updatePasswordForm')
        .findByText(/^Password$/i)
        .type(newPassword);
      cy.get('@updatePasswordForm')
        .findByText(/^Confirm new password$/)
        .type(newPassword);

      // Submit the form
      cy.get('@updatePasswordForm').findByText('Set New Password').click();

      cy.findByTestId('login-form').as('loginForm');

      cy.get('@loginForm')
        .findByText(/^Email$/)
        .type(user.email);
      cy.get('@loginForm')
        .findByText(/^Password$/)
        .type(newPassword);
    });

    // We intercept these requests to make sure all async sign-in requests have completed before finishing the test.
    // This ensures async responses do not intefere with subsequent test setup
    const loginNetworkRequests = getInterceptsForLingeringUserRequests(
      '/',
      true,
    );

    // Submit the form
    cy.get('@loginForm').findByText('Continue').click();
    cy.wait(loginNetworkRequests);

    const { baseUrl } = Cypress.config();
    cy.url().should('equal', `${baseUrl}settings/account?signin=true`);
    cy.findByRole('heading', { name: 'Set new password' });
  });

  it('should give an error if the new password/confirm new password fields do not match when changing the password of a user', () => {
    cy.fixture('users/changePasswordUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.findByTestId('update-password-form').as('updatePasswordForm');

      cy.get('@updatePasswordForm')
        .findByText(/^Current Password$/i)
        .type(user.password);
      cy.get('@updatePasswordForm')
        .findByText(/^Password$/i)
        .type('some new password that is not the same');
      cy.get('@updatePasswordForm')
        .findByText(/^Confirm new password$/)
        .type('some other new password that is not the same');
    });

    // Submit the form
    cy.get('@updatePasswordForm')
      .findByText(/^Set New Password$/)
      .click();

    cy.findByTestId('account-errors-panel').findByText(
      /^Password doesn't match password confirmation$/,
    );
  });
});
