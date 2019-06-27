function checkUserLoggedIn() {
  const body = document.getElementsByTagName('body')[0];
  if (!body) {
    return false;
  }

  return body.getAttribute('data-user-status') === 'logged-in';
}
