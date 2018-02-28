/**
 * This auto-resize function is made for textarea in /new.
 * It is a slightly modified version of the solution found here.
 * stackoverflow.com/questions/18262729/ how-to-stop-window-jumping-when-typing-in-autoresizing-textarea
 */
function initEditorResize() {
  var observe, scrollLeft, scrollTop;
  var textarea = document.getElementById('article_body_markdown');

  if (!textarea) {
    return;
  }

  if (window.attachEvent) {
    observe = function(element, event, handler) {
      element.attachEvent('on' + event, handler);
    };
  } else {
    observe = function(element, event, handler) {
      element.addEventListener(event, handler, false);
    };
  }

  function getScrollLeft() {
    return (
      window.pageXOffset ||
      (document.documentElement || document.body.parentNode || document.body)
        .scrollLeft
    );
  }

  function getScrollTop() {
    return (
      window.pageYOffset ||
      (document.documentElement || document.body.parentNode || document.body)
        .scrollTop
    );
  }

  function resize() {
    textarea.style.height = 'auto';
    textarea.style.height = textarea.scrollHeight - 24 + 'px';
    resizeHighlightArea(textarea.scrollHeight - 24);
    window.scrollTo(scrollLeft, scrollTop);
  }

  function resizeHighlightArea(height) {
    function getbyClass(name) {
      return document.getElementsByClassName(name);
    }
    if (
      getbyClass('highlightTextarea-container')[0] &&
      getbyClass('highlightTextarea')[0]
    ) {
      getbyClass('highlightTextarea-container')[0].style.height =
        height - 4 + 'px';
      getbyClass('highlightTextarea-highlighter')[0].style.height =
        height + 'px';
      getbyClass('highlightTextarea')[0].style.height = height + 132 + 'px';
    }
  }

  function delayedResize() {
    /**
     * scrollLeft and scrollTop are kept in delayedResize because
     * of a weird browser auto-focused when pressing enter in a textarea.
     * This happens when the carot is either too low or too high based on
     * the screen.
     */
    scrollLeft = getScrollLeft();
    scrollTop = getScrollTop();
    /* 0-timeout to get the already changed text */
    window.setTimeout(resize, 0);
  }

  // observe(textarea, 'change',  resize);
  observe(textarea, 'cut', delayedResize);
  observe(textarea, 'paste', delayedResize);
  observe(textarea, 'drop', delayedResize);
  observe(textarea, 'keydown', delayedResize);
  textarea.focus();
  resize();
}
