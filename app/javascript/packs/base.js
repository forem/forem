import { setCurrentPageIconLink } from '../topNavigation/utilities';

InstantClick.on('change', function () {
  const { currentPage } = document.getElementById('page-content').dataset;
  setCurrentPageIconLink(currentPage);
});

const { currentPage } = document.getElementById('page-content').dataset;
setCurrentPageIconLink(currentPage);
