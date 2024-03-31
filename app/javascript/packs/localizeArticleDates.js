/* Show article date/time according to user's locale */
import { addLocalizedDateTimeToElementsTitles } from '../utilities/localDateTime';

const initializeArticleDate = () => {
  const articlesDates = document.querySelectorAll(
    '.crayons-story time, article time',
  );

  addLocalizedDateTimeToElementsTitles(articlesDates, 'datetime');
};

initializeArticleDate();
