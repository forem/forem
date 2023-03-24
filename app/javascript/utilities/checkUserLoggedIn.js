export function checkUserLoggedIn() {
  const body = document.body;
  if (!body) {
    return false;
  }

  return body.getAttribute('data-user-status') === 'logged-in';
}
