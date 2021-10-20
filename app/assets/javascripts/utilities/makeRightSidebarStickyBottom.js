function makeRightSidebarStickyBottom() {
  const isMobileDevice = screen.width <= 480;
  const sidebar = document.getElementById('sidebar-content');
  const sidebarShowsEntirelyInViewport = isCompletelyVisible(sidebar);

  if (sidebarShowsEntirelyInViewport || isMobileDevice) {
    return;
  }

  window.addEventListener('scroll', handleScroll);

  const containerPadding = 28;
  const navBarHeight = 56;
  const articleColumnDiv = document.getElementById('main-content');
  const sidebarPlaceholder = document.getElementById('sidebar-placeholder');

  // these values are used for calculating when to apply marginTop to the sidebar-placeholde
  // and when to set the sidebar position as fixed or sticky
  const initialShownSidebarHeight = window.innerHeight - sidebar.offsetTop;
  const pixelsToReachBottomOfSidebar =
    sidebar.offsetHeight - initialShownSidebarHeight;
  const pixelsToReachBottomOfArticle =
    articleColumnDiv.offsetHeight -
    window.innerHeight +
    articleColumnDiv.offsetTop;
  const pixelsToOffsetToScrollTop = sidebar.offsetHeight - window.innerHeight;
  const marginTopWhenReachedBottomOfArticle =
    pixelsToReachBottomOfArticle -
    pixelsToOffsetToScrollTop -
    navBarHeight -
    containerPadding;

  sidebar.style.width = `${sidebar.offsetWidth}px`;
  sidebar.classList.remove('crayons-article-sticky');

  // variables to be set by scroll event listener
  let lastScrollPosition = 0;
  let setSidebarPosition = false;
  let setSidebarStickyTop = false;
  let distanceMovedDown = 0;

  function handleScroll() {
    const windowScrollY = window.pageYOffset;
    const scrollingDown = windowScrollY > lastScrollPosition;
    const distanceMovedDuringScroll = windowScrollY - lastScrollPosition;
    distanceMovedDown += distanceMovedDuringScroll;

    if (scrollingDown) {
      setSidebarStickyTop = false;
      const reachedBottomOfSidebar =
        distanceMovedDown >= pixelsToReachBottomOfSidebar;
      if (reachedBottomOfSidebar) {
        if (!setSidebarPosition) {
          setSidebarPosition = true;
          sidebar.style.position = 'fixed';
          sidebar.style.bottom = `10px`; // so that it looks consistent from bottom
          setSidebarPosition = true;
        }
      }

      const reachedBottomOfArticle =
        windowScrollY >= pixelsToReachBottomOfArticle;
      if (reachedBottomOfArticle) {
        sidebarPlaceholder.style.marginTop = `${marginTopWhenReachedBottomOfArticle}px`;
        sidebar.style.position = '';
      }
    } else {
      if (setSidebarPosition) {
        if (!setSidebarStickyTop) {
          distanceMovedDown = 0;

          // this condition is for handling the scenario when user scrolls back up when they reached the bottom of the article
          // we don't want the resultant marginTop to cause the sidebar's div height to become longer than the original height.
          const marginTop =
            windowScrollY - pixelsToOffsetToScrollTop <
            marginTopWhenReachedBottomOfArticle
              ? windowScrollY - pixelsToOffsetToScrollTop
              : marginTopWhenReachedBottomOfArticle;
          sidebarPlaceholder.style.marginTop = `${marginTop}px`;
          sidebar.style.position = '';
          sidebar.style.bottom = '';
          sidebar.style.top = '';
          setSidebarPosition = false;
        }
      } else {
        if (setSidebarStickyTop) {
          sidebarPlaceholder.style.marginTop = `${windowScrollY}px`;
          distanceMovedDown = 0;
        } else {
          const sidebarPlaceholderMarginTop =
            -distanceMovedDown + navBarHeight + containerPadding;
          const reachedTopOfSidebar =
            sidebarPlaceholderMarginTop >= pixelsToReachBottomOfSidebar;

          if (reachedTopOfSidebar) {
            distanceMovedDown = 0;
            sidebar.style.position = 'sticky';
            setSidebarStickyTop = true;
          }
        }
      }
    }

    lastScrollPosition = windowScrollY <= 0 ? 0 : windowScrollY; // For Mobile or negative scrolling
  }
}

function isCompletelyVisible(el) {
  return el.offsetHeight < window.innerHeight;
}
