export const isInViewport = (element) => {
  const boundingRect = element.getBoundingClientRect();
  const clientHeight =
    window.innerHeight || document.documentElement.clientHeight;
  const clientWidth = window.innerWidth || document.documentElement.clientWidth;
  return (
    boundingRect.top >= 0 &&
    boundingRect.left >= 0 &&
    boundingRect.bottom <= clientHeight &&
    boundingRect.right <= clientWidth
  );
};
