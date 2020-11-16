export default function mainNavigation() {
  function listenNavMoreTrigger(e) {
    e.target.nextElementSibling.classList.remove('hidden');
    e.target.classList.add('hidden');
  }

  const navMoreTriggers = document.getElementsByClassName(
    'js-nav-more-trigger',
  );

  Array.from(navMoreTriggers).forEach((trigger) => {
    trigger.addEventListener('click', listenNavMoreTrigger);
  });
}
