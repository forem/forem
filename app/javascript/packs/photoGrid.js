// eslint-disable-next-line no-unused-vars
import { createElement as h, render, Component } from 'preact';
// import Photogrid from "react-facebook-photo-grid";
import { ImageGrid } from "react-fb-image-video-grid";

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
    const photoGrids = document.querySelectorAll('.photo-grid');

    const pic = (c) => {
      return (
        <img
          style={{ objectFit: "cover" }}
          src={c}
          alt=""
        />
      );
    };

    for (let i = 0; i < photoGrids.length; i++) {
      const photoGrid = photoGrids[i];
      const { images } = photoGrid.dataset;
      const imagesArr = images.split(',').filter(n => n);
      const id = Math.random() //or some such identifier 
      const d = document.createElement("div")
      d.id = id
      photoGrid.appendChild(d)

      if (images!= "") {
        render(
          <ImageGrid>
            {imagesArr
              .filter((arg, i) => ((i <= imagesArr.length)))
              .map((a) => pic(a))}
          </ImageGrid>,
          photoGrid,
          photoGrid.firstElementChild,
        );
      }
    }
}

document.ready.then(() => {
    loadForm();
    window.InstantClick.on('change', () => {
        loadForm();
    });
});
