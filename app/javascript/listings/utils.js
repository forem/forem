export function resizeMasonryItem(item) {
  /* Get the grid object, its row-gap, and the size of its implicit rows */
  const grid = document.getElementsByClassName('classifieds-columns')[0];
  const rowGap = parseInt(
    window.getComputedStyle(grid).getPropertyValue('grid-row-gap'),
    10,
  );
  const rowHeight = parseInt(
    window.getComputedStyle(grid).getPropertyValue('grid-auto-rows'),
    10,
  );

  const rowSpan = Math.ceil(
    (item.querySelector('.listing-content').getBoundingClientRect().height +
      rowGap) /
      (rowHeight + rowGap),
  );

  /* Set the spanning as calculated above (S) */
  // eslint-disable-next-line no-param-reassign
  item.style.gridRowEnd = `span ${rowSpan}`;
}
