/**
 * @file Manages logic to add active class on items when it's a touch device
 */
const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
if (isTouchDevice) {
  const activeLinks = document.getElementsByClassName('active');
  Array.prototype.forEach.call(activeLinks, (el) => {
    el.classList.remove('active');
  });

  document.getElementById('main-content').addEventListener('click', (event) => {
    const clickedEl = event.target;
    if (
      clickedEl.classList.contains('bm-initial') ||
      clickedEl.classList.contains('bm-success')
    ) {
      //do nothing
    } else if (clickedEl.parentNode.classList.contains('crayons-story')) {
      clickedEl.parentNode.classList.add('active');
    } else if (
      clickedEl.parentNode.parentNode.classList.contains('crayons-story')
    ) {
      clickedEl.parentNode.parentNode.classList.add('active');
    } else if (
      clickedEl.parentNode.parentNode.parentNode.classList.contains(
        'crayons-story',
      )
    ) {
      clickedEl.parentNode.parentNode.parentNode.classList.add('active');
    }
  });
}

// A custom event that gets dispatched to notify search forms to synchronize their state.
window.dispatchEvent(
  new CustomEvent('syncSearchForms', {
    detail: { querystring: location.search },
  }),
);
