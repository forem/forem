function loadScript(src, done) {
  var js = document.createElement('script');
  js.src = src;
  js.onload = function() {
    done();
  };
  js.onerror = function() {
    done(new Error('Failed to load script ' + src));
  };
  document.head.appendChild(js);
}

if (!window.clipboard && !window.Clipboard && !navigator.clipboard && !navigator.Clipboard) {
  loadScript("https://cdnjs.cloudflare.com/ajax/libs/clipboard-polyfill/2.8.6/clipboard-polyfill.js")
}

window.WebComponents.waitFor(() => {
  import('@github/clipboard-copy-element');
});
