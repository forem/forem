import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../src/components/common-prop-types';

export const SaveButton = ({ article, isBookmarked }) => {
  if (article.class_name === 'Article') {
    return (
      <button
        type="button"
        className={`article-engagement-count engage-button bookmark-button ${
          isBookmarked ? 'selected' : ''
        }`}
        data-reactable-id={article.id}
      >
        <span className="bm-initial">SAVE</span>
        <span className="bm-success">SAVED</span>
      </button>
    );
  }
  if (article.class_name === 'User') {
    return (
      <button
        type="button"
        style={{ width: '122px' }}
        className="article-engagement-count engage-button follow-action-button"
        data-info={`{"id":${article.id},"className":"User"}`}
        data-follow-action-button
      >
        &nbsp;
      </button>
    );
  }

  return null;
};

SaveButton.propTypes = {
  article: articlePropTypes.isRequired,
  isBookmarked: PropTypes.bool.isRequired,
};

SaveButton.displayName = 'SaveButton';
