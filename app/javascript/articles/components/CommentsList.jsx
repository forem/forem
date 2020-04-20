import { h } from 'preact';
import PropTypes from 'prop-types';
import { CommentListItem } from './CommentListItem';

export const CommentsList = ({ comments, totalCount }) => {
  if (comments.length > 0) {
    return (
      <div className="crayons-story__comments">
        <p className="crayons-story__comments__headline">Top comments:</p>

        {comments.slice(0, 2).map((comment) => {
          return <CommentListItem comment={comment} />;
        })}

        <div className="crayons-story__comments__actions">
          <a href="/" className="crayons-btn crayons-btn--secondary fs-s mr-2">
            See all 
            {' '}
            {totalCount}
            {' '}
            comments
          </a>
          <button
            className="crayons-btn crayons-btn--secondary fs-s"
            type="button"
          >
            Subscribe
          </button>
        </div>
      </div>
    );
  }
  return <div />;
};

CommentsList.displayName = 'CommentsList';

Comment.propTypes = PropTypes.shape({
  name: PropTypes.string.isRequired,
  profile_image_90: PropTypes.string.isRequired,
  published_at_int: PropTypes.number.isRequired,
});

CommentsList.propTypes = {
  comments: PropTypes.arrayOf(Comment.propTypes).isRequired,
  totalCount: PropTypes.number.isRequired,
};
