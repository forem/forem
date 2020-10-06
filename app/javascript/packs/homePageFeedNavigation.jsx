import { registerGlobalListNavigation } from '../utilities/hooks/useGlobalListNavigation';

registerGlobalListNavigation(
  '.crayons-story',
  'a[id^=article-link-]',
  'div.paged-stories,div.substories',
);
