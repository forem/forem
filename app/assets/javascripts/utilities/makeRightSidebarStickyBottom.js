function makeRightSidebarStickyBottom() {
  const sidebar = document.getElementById('article-show-primary-sticky-nav');
  const isMobileDevice = screen.width <= 480;
  const sidebarShowsEntirelyInViewport = elementInViewport(sidebar);
  const lastChild = getLastSuggestedArticleElement(sidebar);
  const sidebarWidth = lastChild.getBoundingClientRect().width;

  let lastScrollPositionTop = 0;
  let sidebarPositionTop = 0;
  let sidebarIsPositionFixed = false;

  if (!sidebarShowsEntirelyInViewport && !isMobileDevice) {
    sidebar.classList.remove('crayons-article-sticky');
    window.addEventListener('scroll', throttle(handleScroll));
  }

  function handleScroll() {
    console.debug('Handling scroll'); // eslint-disable-line no-console
    var st = window.scrollY;
    const scrollingDown = st > lastScrollPositionTop;

    if (scrollingDown) {
      if (!sidebarIsPositionFixed) {
        const reachedBottomOfSidebar =
          window.innerHeight - lastChild.getBoundingClientRect().bottom > 8;

        if (reachedBottomOfSidebar) {
          sidebarPositionTop = sidebar.getBoundingClientRect().top;
          if (!sidebarIsPositionFixed) {
            sidebar.style.top = `${sidebarPositionTop}px`;
            sidebar.style.position = 'fixed';
            sidebar.style.width = `${sidebarWidth}px`;
            sidebarIsPositionFixed = true;
          }
        }
      }
    } else {
      if (sidebarIsPositionFixed) {
        const distanceMoved = st - lastScrollPositionTop;
        sidebarPositionTop -= distanceMoved;
        sidebar.style.top = `${sidebarPositionTop}px`;

        // this ensures that the right sidebar will not be moving beyond the top of the article
        const headerHeight = 56;
        const layoutPadding = 24;
        const sidebarStickyTopVal = headerHeight + layoutPadding;
        const reachedTopOfArticle =
          Math.abs(sidebarPositionTop) <= sidebarStickyTopVal;

        if (reachedTopOfArticle) {
          sidebar.style.removeProperty('position');
          sidebar.style.removeProperty('top');
          sidebarIsPositionFixed = false;
        }
      }
    }

    lastScrollPositionTop = st <= 0 ? 0 : st; // For Mobile or negative scrolling
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
    top >= window.scrollY &&
    left >= window.scrollX &&
    top + height + bottomPadding <= window.scrollY + window.innerHeight &&
    left + width <= window.scrollX + window.innerWidth
  );
}

function throttle(callback, limit = 1) {
  var wait = false;
  return function () {
    if (!wait) {
      callback.call();
      wait = true;
      setTimeout(function () {
        wait = false;
      }, limit);
    }
  };
}
