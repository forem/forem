export function initializeGifVideos(root = document) {
  const videos = root.querySelectorAll('video[data-gif-video]');
  videos.forEach((video) => {
    if (video.dataset.gifInitialized === 'true') return;
    video.dataset.gifInitialized = 'true';

    // Ensure attributes in case HTML sanitizer removed boolean styles
    video.setAttribute('muted', '');
    video.setAttribute('loop', '');
    video.setAttribute('autoplay', '');
    video.setAttribute('playsinline', '');
    video.removeAttribute('controls');

    // Autoplay might be blocked; attempt play and ignore errors
    const tryPlay = () => {
      const p = video.play();
      if (p && typeof p.catch === 'function') {
        p.catch(() => {});
      }
    };

    if (video.readyState >= 2) {
      tryPlay();
    } else {
      video.addEventListener('canplay', tryPlay, { once: true });
    }

    video.addEventListener('click', () => {
      if (video.paused) {
        tryPlay();
      } else {
        video.pause();
      }
    });
  });
}


