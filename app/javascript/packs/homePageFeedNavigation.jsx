import { h, render } from 'preact';
import { ListNavigation } from '../shared/components/useListNavigation';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.querySelector('#articles-list');

  render(
    <ListNavigation
      itemSelector=".crayons-story"
      focusableSelector="a.crayons-story__hidden-navigation-link"
      waterfallItemContainerSelector="div.paged-stories,div.substories"
    />,
    root,
  );
});
