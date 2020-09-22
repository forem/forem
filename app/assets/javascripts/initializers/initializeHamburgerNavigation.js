function listenTriggers(trigger) {
  const body = document.querySelector('body');

  if (trigger) {
    trigger.addEventListener('click', (event) => {
      event.preventDefault();
      body.classList.toggle('hamburger-open');
    });
  }
}

function initializeHamburgerNavigation() {
  var hamburgerTrigger = document.querySelector('.js-hamburger-trigger');

  listenTriggers(hamburgerTrigger);
}
