import { h } from 'preact';
import PropTypes from 'prop-types';

/* global timeAgo */

function createMarkup(comment) {
  return { __html: comment.safe_processed_html };
}

function userProfilePage(username) {
  const str = `/${username}`;
  return str;
}

export const CommentListItem = ({ comment }) => (
  <div className="crayons-comment pl-2">
    <div className="crayons-comment__meta">
      <a
        href={userProfilePage(comment.username)}
        className="crayons-story__secondary fw-medium"
      >
        <span className="crayons-avatar mr-2">
          <img
            src={comment.profile_image_90}
            className="crayons-avatar__image"
            alt={`{comment.username} avatar`}
          />
        </span>
        {comment.name}
      </a>
      <a href={comment.path} className="crayons-story__tertiary ml-1">
        {timeAgo({
          oldTimeInSeconds: comment.published_at_int,
          formatter: (x) => x,
          maxDisplayedAge: NaN,
        })}
      </a>
    </div>
    <div
      className="crayons-comment__body"
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={createMarkup(comment)}
    />
  </div>
);

CommentListItem.displayName = 'CommentsListItem';

CommentListItem.propTypes = {
  comment: PropTypes.shape({
    name: PropTypes.string.isRequired,
    profile_image_90: PropTypes.string.isRequired,
    published_at_int: PropTypes.number.isRequired,
    safe_processed_html: PropTypes.string.isRequired,
    path: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
  }).isRequired,
};
