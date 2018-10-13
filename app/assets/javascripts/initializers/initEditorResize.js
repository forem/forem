/**
 * This auto-resize function is made for textarea in /new.
 * It is a slightly modified version of the solution found here.
 * stackoverflow.com/questions/18262729/ how-to-stop-window-jumping-when-typing-in-autoresizing-textarea
 */
function initEditorResize() {
  var observe;
  var scrollLeft;
  var scrollTop;
  var textarea = document.getElementById('article_body_markdown');
  var oldEditor = document.getElementById('markdown-editor-main');

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
    textarea.style.height = textarea.scrollHeight - 29 + 'px';
    window.scrollTo(scrollLeft, scrollTop);
    if (oldEditor) {
      return;
    }
    var len = textarea.value.length;
    // If character entered is at the end of the textarea (therefore cursor)
    if (
      textarea.selectionEnd > len - 15 &&
      len > 400 &&
      document.activeElement === textarea
    ) {
      window.scrollTo(scrollLeft, 10000);
    } else {
      window.scrollTo(scrollLeft, scrollTop);
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
  // textarea.focus();
  resize();
}
