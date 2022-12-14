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
    const root = document.querySelector('#photo-grid');
    const { images } = root.dataset;
    const imagesArr = images.split(',').filter(n => n);

    const pic = (c) => {
      return (
        <img
          style={{ objectFit: "cover" }}
          src={c}
          alt=""
        />
      );
    };

    if (images!= "") {
      render(
        // <Photogrid images={imagesArr} //required
        //   maxWidth={800} //optional according to your need
        // />,
        <ImageGrid>
          {imagesArr
            .filter((arg, i) => ((i <= imagesArr.length)))
            .map((a) => pic(a))}
        </ImageGrid>,
        root,
        root.firstElementChild,
      );
    }
}

document.ready.then(() => {
    loadForm();
    window.InstantClick.on('change', () => {
        loadForm();
    });
});
