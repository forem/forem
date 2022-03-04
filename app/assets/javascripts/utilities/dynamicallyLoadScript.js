function dynamicallyLoadScript(url) {
  if (document.querySelector(`script[src='${url}']`)) return;

  const script = document.createElement('script');
  script.src = url;

  document.head.appendChild(script);
}
