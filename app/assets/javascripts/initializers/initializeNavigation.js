function listenHamburgerTriggers() {
  document.body.classList.toggle('hamburger-open');
}

const hamburgerTriggers = document.getElementsByClassName(
  'js-hamburger-trigger',
);

Array.from(hamburgerTriggers).forEach((trigger) => {
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
