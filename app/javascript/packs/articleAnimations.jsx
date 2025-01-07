const animatedImages = document.querySelectorAll('[data-animated="true"]');
if (animatedImages.length > 0) {
  import('@utilities/animatedImageUtils').then(
    ({ initializePausableAnimatedImages }) => {
      initializePausableAnimatedImages(animatedImages);
    },
  );
}
