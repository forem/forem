import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';

export const SaveButton = ({
  article,
  isBookmarked: isBookmarkedProps,
  onClick,
  saveable = true,
}) => {
  const [buttonText, setButtonText] = useState(
    isBookmarkedProps ? 'Saved' : 'Save',
  );
  const [isBookmarked, setIsBookmarked] = useState(isBookmarkedProps);

  const mouseMove = (_e) => {
    setButtonText(isBookmarked ? 'Unsave' : 'Save');
  };

  const mouseOut = (_e) => {
    setButtonText(isBookmarked ? 'Saved' : 'Save');
  };

  const handleClick = (_e) => {
    onClick(_e);
    setButtonText(isBookmarked ? 'Save' : 'Saved');
    setIsBookmarked((prevState) => !prevState);
  };

  if (article.class_name === 'Article' && saveable) {
    return (
      <button
        type="button"
        id={`article-save-button-${article.id}`}
        className={`crayons-btn crayons-btn--s ${
          isBookmarked ? 'crayons-btn--ghost' : 'crayons-btn--secondary'
        }`}
        data-initial-feed
        data-reactable-id={article.id}
        onClick={handleClick}
        onMouseMove={mouseMove}
        onFocus={mouseMove}
        onMouseout={mouseOut}
        onBlur={mouseOut}
      >
        {buttonText}
      </button>
    );
  }
  if (article.class_name === 'User') {
    return (
      <button
        type="button"
        className="crayons-btn crayons-btn--secondary fs-s"
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
  onClick: PropTypes.func.isRequired,
  saveable: PropTypes.bool.isRequired,
};

SaveButton.displayName = 'SaveButton';
