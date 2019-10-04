'use strict';

/* eslint-disable no-undef */

function handleSwipeLeft(e) {
  if (!document.getElementById('on-page-nav-controls')) {
    return;
  }
  if (swipeState === 'middle') {
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
  if (swipeState === 'middle') {
    swipeState = 'left';
    slideSidebar('left', 'intoView');
  } else {
    swipeState = 'middle';
    slideSidebar('right', 'outOfView');
  }
}

function initializeSwipeGestures() {
  initializeSwipeGestures.called = true;
  swipeState = 'middle';
  setTimeout(() => {
    // window.onload=function(){
    (d => {
      var ce = (e, n) => {
        var a = document.createEvent('CustomEvent');
        a.initCustomEvent(n, true, true, e.target);
        e.target.dispatchEvent(a);
        a = null;
        return false;
      };
      var nm = true;
      var sp = { x: 0, y: 0 };
      var ep = { x: 0, y: 0 };
      var touch = {
        touchstart: e => {
          sp = {
            x: e.touches[0].pageX,
            y: e.touches[0].pageY,
            scrollY: window.scrollY,
          };
        },
        touchmove: e => {
          nm = false;
          ep = {
            x: e.touches[0].pageX,
            y: e.touches[0].pageY,
            scrollY: window.scrollY,
          };
        },
        touchend: e => {
          if (nm) {
            ce(e, 'fc');
          } else {
            var x = ep.x - sp.x;
            var xr = Math.abs(x);
            var y = ep.y - sp.y;
            var yr = Math.abs(y);
            var absScroll = Math.abs(sp.scrollY - ep.scrollY);
            if (Math.max(xr, yr) > 15) {
              var shouldScroll = xr / 2 > yr && absScroll < 5;
              if (shouldScroll) {
                shouldScroll = x < 0 ? 'swl' : 'swr';
              } else {
                shouldScroll = y < 0 ? 'swu' : 'swd';
              }
              ce(e, shouldScroll);
            }
          }
          nm = true;
        },
        touchcancel: e => {
          nm = false;
        },
      };
      Object.keys(touch).forEach(key => {
        d.addEventListener(a, touch[a], false);
      });
    })(document);
    var h = e => {
      console.log(e.type, e);
    };
    document.body.addEventListener('swl', handleSwipeLeft, false);
    document.body.addEventListener('swr', handleSwipeRight, false);
  }, 50);
}
