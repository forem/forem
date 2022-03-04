'use strict';

var $fetchedImageUrls = [];
function getImageForLink(elem) {
  var imageUrl = elem.getAttribute('data-preload-image');
  if (imageUrl && $fetchedImageUrls.indexOf(imageUrl) === -1) {
    var img = new Image();
    img.src = imageUrl;
    $fetchedImageUrls.push(imageUrl);
  }
}
