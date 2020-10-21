function listenHamburgerTriggers() {
  document.querySelector('body').classList.toggle('hamburger-open');
}

document.querySelectorAll('.js-hamburger-trigger').forEach(function (trigger) {
  trigger.addEventListener('click', listenHamburgerTriggers);
});

function listenNavMoreTrigger(e) {
  e.target.nextElementSibling.classList.remove('hidden');
  e.target.classList.add('hidden');
}

document.querySelectorAll('.js-nav-more-trigger').forEach(function (trigger) {
  trigger.addEventListener('click', listenNavMoreTrigger);
});
