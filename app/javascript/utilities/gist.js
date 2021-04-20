export function embedGists() {
  const waitingOnPostscribe = setInterval(() => {
    clearInterval(waitingOnPostscribe);
    const gistTags = document.querySelectorAll('.ltag_gist-liquid-tag');

    // Only load scripts for gists if needed
    if (gistTags.length > 0) {
      import('postscribe').then(({ default: postscribe }) => {
        for (const gistTag of gistTags) {
          postscribe(gistTag, gistTag.firstElementChild.outerHTML, {
            beforeWrite: (function (context) {
              return function (text) {
                if (context.childElementCount > 3) {
                  return '';
                }
                return text;
              };
            })(gistTag),
          });
        }
      });
    }
  }, 500);
}

export function embedGistsInComments() {
  // allows for getting the gist embed after new comment submit/preview/dismiss
  document
    .getElementById('new_comment')
    ?.addEventListener('submit', (_event) => {
      embedGists();
    });
  document
    .querySelector('.preview-toggle')
    ?.addEventListener('click', (_event) => {
      embedGists();
    });
  document
    .querySelector('.dismiss-comment')
    ?.addEventListener('click', (_event) => {
      embedGists();
    });
}
