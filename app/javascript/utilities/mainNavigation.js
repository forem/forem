export default function mainNavigation() {
  function listenNavMoreTrigger(e) {
    e.target.nextElementSibling.classList.remove('hidden');
    e.target.classList.add('hidden');
  }

  document.querySelectorAll('.js-nav-more-trigger').forEach(function (trigger) {
    trigger.addEventListener('click', listenNavMoreTrigger);
  });
}
