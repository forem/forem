export function makeRightSidebarStickyBottom() {
  const target = document.getElementById('sidebar-content');

  //   Keep track of last Y coord so we know if we're scrolling down or not
  let lastY;

  const observerCallback = (entries) => {
    entries.forEach((intersectionEntry) => {
      const {
        boundingClientRect: sidebarRect,
        intersectionRect: visibleSidebarRect,
      } = intersectionEntry;

      const scrollingDown = lastY && sidebarRect.y < lastY;
      lastY = sidebarRect.y;

      if (scrollingDown) {
        const isBottomVisible = sidebarRect.bottom <= visibleSidebarRect.bottom;

        //   If the bottom is visible, make the sidebar now sticky in its current position
        if (isBottomVisible && !target.style.top) {
          target.style.top = `${sidebarRect.top}px`;
        }
      }
    });
  };

  const resizeObserverCallback = (entries) => {
    const entry = entries[0];
    const { blockSize: sidebarHeight } = entry.borderBoxSize[0];

    const sidebarExceedsViewportHeight = sidebarHeight > window.innerHeight;

    if (sidebarExceedsViewportHeight) {
      intersectionObserver.observe(target);
    } else {
      intersectionObserver.unobserve(target);
    }
  };

  const intersectionObserver = new IntersectionObserver(observerCallback, {
    threshold: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
  });

  const resizeObserver = new ResizeObserver(resizeObserverCallback);

  resizeObserver.observe(target);
}
