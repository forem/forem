import { h, render } from 'preact';
import { ListNavigation } from '../shared/components/listNavigation';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.querySelector('#articles-list');
  render(
    <ListNavigation
      itemContainerSelector=".crayons-story"
      focusableSelector="a[id^=article-link-]"
      waterfallItemContainerSelector="div.paged-stories,div.substories"
    />,
    root,
  );
});
