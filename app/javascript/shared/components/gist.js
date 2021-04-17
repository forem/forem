import postscribe from 'postscribe';

export function embedGists() {
  const waitingOnPostscribe = setInterval(() => {
    clearInterval(waitingOnPostscribe);
    const els = document.getElementsByClassName("ltag_gist-liquid-tag");
    for (let i = 0; i < els.length; i += 1 ) {
      const current = els[i];
      postscribe(current, current.firstElementChild.outerHTML, {
        beforeWrite: function (context) {
          return function (text) {
            if (context.childElementCount > 3) {
              return "";
            }
            return text;
          }
        }(current)
      });
    }
  }, 500);
}
