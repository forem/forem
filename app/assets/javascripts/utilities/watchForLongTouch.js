// Watch @param element for a "long touch" (800ms) and dispatch a custom "longTouch" event,
// which you are presumably listening for elsewhere. Note that this also disables context menu
// for the element, as otherwise device will default to opening a context menu instead.
function watchForLongTouch(element) {
  const longTouchEvent = new Event('longTouch');
  const minDuration = 800;
  let timer;

  // In the event of a long touch, dispatch the "longTouch" event
  const dispatcher = function () {
    element.dispatchEvent(longTouchEvent);
  };

  // Observe "touchstart", if it's still going after a duration, dispatch "longTouch"
  const onTouchStart = function (event) {
    if (!timer) {
      timer = setTimeout(dispatcher, minDuration);
    }
  };

  // Observe "touchend", if they've stopped touching, it won't become a longTouch anytime soon
  const onTouchEnd = function () {
    if (timer) {
      clearTimeout(timer);
      timer = false;
    }
  };

  if (element) {
    // Disable contextmenu on device, otherwise they'll get a device OS menu instead of ours
    element.oncontextmenu = function (event) {
      event.preventDefault();
      event.stopPropagation(); // not necessary in my case, could leave in case stopImmediateProp isn't available?
      event.stopImmediatePropagation();
      return false;
    };
    element.addEventListener('touchstart', onTouchStart);
    element.addEventListener('touchend', onTouchEnd);
  }
}
