

function dynamicallyLoadScript(url) {
  if (document.querySelector(`script[src='${url}']`)) return;

  var script = document.createElement('script');
  script.src = url;

  document.head.appendChild(script);
}
