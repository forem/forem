export function checkUserLoggedIn() {
  const { body } = document;
  if (!body) {
    return false;
  }

  return body.getAttribute('data-user-status') === 'logged-in';
}
