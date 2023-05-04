import { h } from 'preact';
import PropTypes from 'prop-types';

/* global timeAgo */

function userProfilePage(username) {
  const str = `/${username}`;
  return str;
}

function contentAwareComments(comment) {
  const parser = new DOMParser();
  const htmlDoc = parser.parseFromString(
    comment.safe_processed_html,
    'text/html',
  );
  const nodes = htmlDoc.body.childNodes;
  let text = '';
  let nodesSelected = 0;
  nodes.forEach((node) => {
    if (
      node.outerHTML &&
      node.tagName === 'P' &&
      nodesSelected < 2 &&
      node.outerHTML.length > 250
      && !node.outerHTML.includes('article-body-image-wrapper')
    ) {
      text = `${text} ${node.outerHTML.substring(0, 230)} ...`;
      nodesSelected = 2;
    } else if (node.outerHTML && nodesSelected < 2) {
      text = text + node.outerHTML;
      nodesSelected++;
    } else if (node.outerHTML && nodesSelected < 3) {
      text = `${text} <div class="crayons-comment__readmore">See more</div>`;
      nodesSelected++;
    }
  });
  return text;
}

export const CommentListItem = ({ comment }) => (
  <div
    className="crayons-comment cursor-pointer"
    role="presentation"
    onClick={(_event) => {
      if (_event.target.closest('a')) {
        return;
      }
      if (_event.which > 1 || _event.metaKey || _event.ctrlKey) {
        // Indicates should open in _blank
        window.open(comment.path, '_blank');
      } else {
        const fullUrl = window.location.origin + comment.path; // InstantClick deals with full urls
        InstantClick.preload(fullUrl);
        InstantClick.display(fullUrl);
      }
    }}
  >
    <div className="crayons-comment__meta">
      <a
        href={userProfilePage(comment.username)}
        className="crayons-story__secondary fw-medium"
      >
        <span className="crayons-avatar mr-2">
          <img
            src={comment.profile_image_90}
            className="crayons-avatar__image"
            alt="{comment.username} avatar"
          />
        </span>
      </a>
    </div>
    <div className="crayons-comment__body">
      <div class="crayons-comment__metainner">
        <span class="fw-medium">{comment.name}</span>
        <a href={comment.path} className="crayons-story__tertiary ml-1">
          <time>
            {timeAgo({
              oldTimeInSeconds: comment.published_at_int,
              formatter: (x) => x,
              maxDisplayedAge: NaN,
            })}
          </time>
        </a>
      </div>
      <div
        data-testid="comment-content"
        className="crayons-comment__inner"
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{ __html: contentAwareComments(comment) }}
      />
    </div>
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
