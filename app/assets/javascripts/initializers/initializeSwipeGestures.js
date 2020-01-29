function initializeSwipeGestures() {
  initializeSwipeGestures.called = true;
  swipeState = 'middle';
  setTimeout(function() {
    // window.onload=function(){
    (function(d) {
      const ce = function(e, n) {
        let a = document.createEvent('CustomEvent');
        a.initCustomEvent(n, true, true, e.target);
        e.target.dispatchEvent(a);
        a = null;
        return false;
      };
      let nm = true;
      let sp = { x: 0, y: 0 };
      let ep = { x: 0, y: 0 };
      const touch = {
        touchstart: function(e) {
          sp = {
            x: e.touches[0].pageX,
            y: e.touches[0].pageY,
            scrollY: window.scrollY,
          };
        },
        touchmove: function(e) {
          nm = false;
          ep = {
            x: e.touches[0].pageX,
            y: e.touches[0].pageY,
            scrollY: window.scrollY,
          };
        },
        touchend: function(e) {
          if (nm) {
            ce(e, 'fc');
          } else {
            const x = ep.x - sp.x;
            const xr = Math.abs(x);
            const y = ep.y - sp.y;
            const yr = Math.abs(y);
            const absScroll = Math.abs(sp.scrollY - ep.scrollY);
            if (Math.max(xr, yr) > 15) {
              const shouldScroll = xr / 2 > yr && absScroll < 5;
              ce(
                e,
                shouldScroll ? (x < 0 ? 'swl' : 'swr') : y < 0 ? 'swu' : 'swd',
              );
            }
          }
          nm = true;
        },
        touchcancel: function(e) {
          nm = false;
        },
      };
      for (const a in touch) {
        d.addEventListener(a, touch[a], false);
      }
    })(document);
    const h = function(e) {
      console.log(e.type, e);
    };
    document.body.addEventListener('swl', handleSwipeLeft, false);
    document.body.addEventListener('swr', handleSwipeRight, false);
  }, 50);
}

function handleSwipeLeft(e) {
  if (!document.getElementById('on-page-nav-controls')) {
    return;
  }
  if (swipeState == 'middle') {
    swipeState = 'right';
    slideSidebar('right', 'intoView');
  } else {
    swipeState = 'middle';
    slideSidebar('left', 'outOfView');
  }
}
function handleSwipeRight(e) {
  if (!document.getElementById('on-page-nav-controls')) {
    return;
  }
  if (swipeState == 'middle') {
    swipeState = 'left';
    slideSidebar('left', 'intoView');
  }
    swipeState = 'middle';
    slideSidebar('right', 'outOfView');
}
