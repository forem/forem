function userData() {
  const dataUser = document
    .getElementsByTagName('body')[0]
    .getAttribute('data-user');

  if (dataUser === null) {
    return null;
  }
  return JSON.parse(dataUser);
}
