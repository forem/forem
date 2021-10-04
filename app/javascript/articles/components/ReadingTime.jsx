import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '../../i18n/l10n';

export const ReadingTime = ({ readingTime }) => {
  // we have ` ... || null` for the case article.reading_time is undefined
  return (
    <small className="crayons-story__tertiary mr-2">
      {i18next.t('articles.reading_time', {
        count: readingTime < 1 ? 1 : readingTime,
      })}
    </small>
  );
};

ReadingTime.defaultProps = {
  readingTime: null,
};

ReadingTime.propTypes = {
  readingTime: PropTypes.number,
};

ReadingTime.displayName = 'ReadingTime';
