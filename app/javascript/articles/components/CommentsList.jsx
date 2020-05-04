import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';
import { CommentListItem } from './CommentListItem';

function linkToCommentsSection(articlePath) {
  const str = `${articlePath}#comments-container`;
  return str;
}

export const CommentsList = ({ comments, articlePath, totalCount }) => {
  if (comments && comments.length > 0) {
    return (
      <div className="crayons-story__comments">
        {comments.slice(0, 2).map((comment) => {
          return <CommentListItem comment={comment} />;
        })}

        <div className="crayons-story__comments__actions">
          <Button
            variant="secondary"
            className="mr-2"
            size="s"
            tagName="a"
            url={linkToCommentsSection(articlePath)}
          >
            See all 
            {' '}
            {totalCount}
            {' '}
            comments
          </Button>
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
  articlePath: PropTypes.string.isRequired,
  totalCount: PropTypes.number.isRequired,
};
