function makeRightSidebarStickyBottom() {
  const rightSidebar = document.getElementById(
    'article-show-primary-sticky-nav',
  );
  const profileCard = document.getElementById('profile-card');
  const lastChild = getLastSuggestedArticleElement(rightSidebar);
  const sidebarShowsEntirelyInViewport = elementInViewport(rightSidebar);
  const isMobileDevice = window.orientation !== 'undefined';

  if (!sidebarShowsEntirelyInViewport && !isMobileDevice) {
    let lastScrollTop = 0;
    let rightSidebarTop = 0;
    let fixedElements = false;
    let sidebarWidth = lastChild.getBoundingClientRect().width;
    console.debug('Adding scroll event listener'); // eslint-disable-line no-console
    window.addEventListener('scroll', () => {
      var st = window.scrollY;
      const scrollingDown = st > lastScrollTop;

      if (scrollingDown) {
        if (elementInViewport(lastChild)) {
          rightSidebarTop = rightSidebar.getBoundingClientRect().top;
          if (!fixedElements) {
            rightSidebar.style.top = `${rightSidebarTop}px`;
            rightSidebar.style.position = 'fixed';
            rightSidebar.style.width = `${sidebarWidth}px`;
            fixedElements = true;
          }
        }
      } else {
        if (fixedElements) {
          const distanceMoved = st - lastScrollTop;
          rightSidebarTop -= distanceMoved;
          rightSidebar.style.top = `${rightSidebarTop}px`;

          if (elementInViewport(profileCard)) {
            fixedElements = false;
          }
        }
      }

      lastScrollTop = st <= 0 ? 0 : st; // For Mobile or negative scrolling
    });
  }
}

function getLastSuggestedArticleElement(rightSidebar) {
  let lastChild = rightSidebar;
  while (lastChild.hasChildNodes()) {
    lastChild = lastChild.lastElementChild;
    if (lastChild.className == 'crayons-card crayons-card--secondary') {
      break;
    }
  }
  return lastChild;
}

function elementInViewport(el) {
  var top = el.offsetTop;
  var left = el.offsetLeft;
  var width = el.offsetWidth;
  var height = el.offsetHeight;

  while (el.offsetParent) {
    el = el.offsetParent;
    top += el.offsetTop;
    left += el.offsetLeft;
  }

  const bottomPadding = 10;
  return (
    top >= window.pageYOffset &&
    left >= window.pageXOffset &&
    top + height + bottomPadding <= window.pageYOffset + window.innerHeight &&
    left + width <= window.pageXOffset + window.innerWidth
  );
}
