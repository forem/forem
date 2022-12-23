// eslint-disable-next-line no-unused-vars
import { createElement as h, render, Component } from 'preact';
import ReactImageGrid from "@cordelia273/react-image-grid";

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
    const photoGrids = document.querySelectorAll('.photo-grid:not([data-loaded="true"])');

    for (let i = 0; i < photoGrids.length; i++) {
      const photoGrid = photoGrids[i];
      const { images, loaded } = photoGrid.dataset;
      if (loaded) continue;
      const imagesArr = images.split(',').filter(n => n);
      const id = Math.random() //or some such identifier 
      const d = document.createElement("div")
      d.id = id
      photoGrid.appendChild(d)
      photoGrid.setAttribute('data-loaded', true);

      if (images!= "") {
        render(
          <div style={{ maxWidth: 800, margin: "auto" }}>
          <ReactImageGrid
            images={imagesArr}
            modal={false}
            onClick={(url) => {
              window._onPhotoGridClick(photoGrid.getAttribute('id'), imagesArr.indexOf(url));
            }}
          />
        </div>,
          photoGrid,
          photoGrid.firstElementChild,
        );
      }
      if (i == photoGrids.length - 1) {
        window.dispatchEvent(new CustomEvent('photoGridLoaded'));
      }
    }
}

document.ready.then(() => {
    loadForm();
    window.InstantClick.on('change', () => {
        loadForm();
    });

    window.addEventListener('checkBlockedContent', () => {
      loadForm();
    });
});
