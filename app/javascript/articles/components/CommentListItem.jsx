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
      (node.tagName === 'P' || node.className.includes('highlight')) &&
      nodesSelected < 2 &&
      node.outerHTML.length > 250
      && !node.outerHTML.includes('article-body-image-wrapper')
    ) {
      node.innerHTML = `${node.innerHTML.substring(0, 230)}...`;
      text = `${text} ${node.outerHTML}`;
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
    className="crayons-comment"
    style={{ position: 'relative' }}
  >
    <a
      href={comment.path}
      className="crayons-comment__stretched-link"
      style={{
        position: 'absolute',
        top: 0,
        right: 0,
        bottom: 0,
        left: 0,
        zIndex: 1,
      }}
      onClick={(event) => {
        // Only intercept for InstantClick on normal clicks
        if (!(event.which > 1 || event.metaKey || event.ctrlKey || event.shiftKey)) {
          event.preventDefault();
          const fullUrl = window.location.origin + comment.path;
          InstantClick.preload(fullUrl);
          InstantClick.display(fullUrl);
        }
        // For modified clicks (ctrl/cmd/middle), browser handles naturally
      }}
      aria-label={`View comment by ${comment.name}`}
    >
      <span className="sr-only">View comment</span>
    </a>
    <div className="crayons-comment__meta" style={{ position: 'relative', zIndex: 2 }}>
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
    <div className="crayons-comment__body" style={{ position: 'relative', zIndex: 2 }}>
      <div class="crayons-comment__metainner">
        <span class="fw-medium">{comment.name}</span>
        <a href={comment.path} className="crayons-story__tertiary ml-1" style={{ position: 'relative', zIndex: 2 }}>
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
