function listenHamburgerTriggers() {
  document.body.classList.toggle('hamburger-open');
}

const triggers = document.getElementsByClassName('js-hamburger-trigger');

Array.from(triggers).forEach((trigger) => {
  trigger.addEventListener('click', listenHamburgerTriggers);
});
