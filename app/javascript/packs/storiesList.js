/**
 * @file A custom event that gets dispatched to notify search forms to synchronize their state.
 */
window.dispatchEvent(
  new CustomEvent('syncSearchForms', {
    detail: { querystring: location.search },
  }),
);
