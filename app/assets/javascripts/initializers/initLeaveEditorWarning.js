function initLeaveEditorWarning() {
  var textarea = document.getElementById('article_body_markdown');
  var articleForm = document.getElementById('article_markdown_form');
  var formIsSubmitting = false;

  if (textarea && articleForm) {
    if (window.location.pathname == '/articles') {
      /**
       * this is when user tried to save already but there was an markdown
       * error.
       */
      window.editorIsDirty = true;
    } else {
      window.editorIsDirty = window.editorIsDirty || false;
    }
    textarea.oninput = function (e) {
      window.editorIsDirty = true;
    }
    articleForm.onsubmit = function (e) {
      formIsSubmitting = true;
    }
  }

  window.onbeforeunload = function (e) {
    var isAtTheRightPage = window.location.href.includes('/new') ||
                           window.location.href.includes('/edit') ||
                           window.location.pathname == '/articles';
    if (window.editorIsDirty && isAtTheRightPage && !formIsSubmitting) {
      /**
       * Message may not appear as it depends on the browser
       */
      return "Changes you've made will be lost.";
    }
  };
}
