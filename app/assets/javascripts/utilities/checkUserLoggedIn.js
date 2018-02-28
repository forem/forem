function checkUserLoggedIn() {
  return document.getElementsByTagName('body')[0].getAttribute('data-user-status') == "logged-in"
}