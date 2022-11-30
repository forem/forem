import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';
import { ButtonNew as Button } from '@crayons';
import BookmarkSVG from '@images/small-save.svg';
import BookmarkFilledSVG from '@images/small-save-filled.svg';

export const SaveButton = ({
  article,
  isBookmarked: isBookmarkedProps,
  onClick,
  saveable = true,
}) => {
  const [isBookmarked, setIsBookmarked] = useState(isBookmarkedProps);

  const handleClick = (_e) => {
    onClick(_e);
    setIsBookmarked((prevState) => !prevState);
  };

  if (article.class_name === 'Article' && saveable) {
    return (
      <Button
        id={`article-save-button-${article.id}`}
        variant="default"
        title={`Save post ${article.title} to reading list`}
        aria-label={`Save post ${article.title} to reading list`}
        aria-pressed={isBookmarked}
        icon={isBookmarked ? BookmarkFilledSVG : BookmarkSVG}
        data-initial-feed
        data-reactable-id={article.id}
        onClick={handleClick}
      />
    );
  }
  if (article.class_name === 'User') {
    return (
      <Button
        className="crayons-btn crayons-btn--secondary fs-s"
        data-info={`{"id":${article.id},"className":"User"}`}
        data-follow-action-button
      >
        &nbsp;
      </Button>
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
