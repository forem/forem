'use strict';

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
  setTimeout(function swipeGesturesTimeout() {
    // window.onload=function(){
    (function swipeGesturesTimeoutCallback(d) {
      var ce = function ce(e, n) {
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
        touchstart: function touchstart(e) {
          sp = {
            x: e.touches[0].pageX,
            y: e.touches[0].pageY,
            scrollY: window.scrollY,
          };
        },
        touchmove: function touchmove(e) {
          nm = false;
          ep = {
            x: e.touches[0].pageX,
            y: e.touches[0].pageY,
            scrollY: window.scrollY,
          };
        },
        touchend: function touchend(e) {
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
              ce(
                e,
                shouldScroll ? (x < 0 ? 'swl' : 'swr') : y < 0 ? 'swu' : 'swd',
              );
            }
          }
          nm = true;
        },
        touchcancel: function touchcancel(e) {
          nm = false;
        },
      };
      for (var a in touch) {
        d.addEventListener(a, touch[a], false);
      }
    })(document);
    var h = function h(e) {
      console.log(e.type, e);
    };
    document.body.addEventListener('swl', handleSwipeLeft, false);
    document.body.addEventListener('swr', handleSwipeRight, false);
  }, 50);
}
