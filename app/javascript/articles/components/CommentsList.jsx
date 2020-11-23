import { h } from 'preact';
import PropTypes from 'prop-types';
import { CommentListItem } from './CommentListItem';
import { Button } from '@crayons';

const numberOfCommentsToShow = 2;

function linkToCommentsSection(articlePath) {
  const str = `${articlePath}#comments-container`;
  return str;
}

function moreCommentsButton(comments, articlePath, totalCount) {
  let button = '';
  if (totalCount > numberOfCommentsToShow) {
    button = (
      <div className="crayons-story__comments__actions">
        <Button
          variant="ghost"
          size="s"
          tagName="a"
          className="-ml-2"
          url={linkToCommentsSection(articlePath)}
          data-testid="see-all-comments"
        >
          See all {totalCount} comments
        </Button>
      </div>
    );
  }
  return button;
}

export const CommentsList = ({ comments = [], articlePath, totalCount }) => {
  if (comments && comments.length > 0) {
    return (
      <div className="crayons-story__comments">
        {comments.slice(0, numberOfCommentsToShow).map((comment) => {
          return <CommentListItem comment={comment} />;
        })}

        {moreCommentsButton(comments, articlePath, totalCount)}
      </div>
    );
  }
  return '';
};

CommentsList.displayName = 'CommentsList';

Comment.propTypes = PropTypes.shape({
  name: PropTypes.string.isRequired,
  profile_image_90: PropTypes.string.isRequired,
  published_at_int: PropTypes.number.isRequired,
});

CommentsList.propTypes = {
  comments: PropTypes.arrayOf(Comment.propTypes).isRequired,
  articlePath: PropTypes.string.isRequired,
  totalCount: PropTypes.number.isRequired,
};
