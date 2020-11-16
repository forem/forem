function listenHamburgerTriggers() {
  document.body.classList.toggle('hamburger-open');
}

const triggers = document.getElementsByClassName('js-hamburger-trigger');

Array.from(triggers).forEach((trigger) => {
  trigger.addEventListener('click', listenHamburgerTriggers);
});

function listenNavMoreTrigger(e) {
  e.target.nextElementSibling.classList.remove('hidden');
  e.target.classList.add('hidden');
}

const navMoreTriggers = document.getElementsByClassName('js-nav-more-trigger');

Array.from(navMoreTriggers).forEach((trigger) => {
  trigger.addEventListener('click', listenNavMoreTrigger);
});
