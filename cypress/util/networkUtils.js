/**
 * Helper function to intercept any network requests which may interfere with user state between user log in/out.
 * Any intercepts which should be awaited are aliased and returned in an array.
 *
 * @param {Boolean} userLoggedIn Whether or not the user state is transitioning to logged in - defaults to false
 * @returns {Array} Array of aliased Cypress intercepts which may be awaited to ensure they run to completion
 */
export const getInterceptsForLingeringUserRequests = (userLoggedIn = false) => {
  // Stub these as response not needed to test app functionality
  cy.intercept('/api/analytics/historical**', {});
  cy.intercept('/api/analytics/referrers**', {});

  // Await these requests as response may affect app behavior
  cy.intercept('/async_info/base_data').as('baseDataRequest');

  if (!userLoggedIn) {
    return ['@baseDataRequest'];
  }

  cy.intercept('/chat_channels**').as('chatRequest');
  cy.intercept('/notifications/counts').as('countsRequest');
  cy.intercept('/notifications?i=i').as('notificationsRequest');

  return [
    '@baseDataRequest',
    '@chatRequest',
    '@countsRequest',
    '@notificationsRequest',
  ];
};
