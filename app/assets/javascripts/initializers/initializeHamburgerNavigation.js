function listenHamburgerTriggers() {
  document.querySelector('body').classList.toggle('hamburger-open');
}

document.querySelectorAll('.js-hamburger-trigger').forEach(function (trigger) {
  trigger.addEventListener('click', listenHamburgerTriggers);
});
