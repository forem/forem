function userData() {
  if (document.getElementsByTagName('body')[0].getAttribute('data-user') === null) {
    return null;
  }
  return JSON.parse(document.getElementsByTagName('body')[0].getAttribute('data-user'));
}
