import { h } from 'preact';
import { useState, useRef, useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { CommentListItem } from './CommentListItem';
import { Button } from '@crayons';
import { articlePropTypes } from '../../common-prop-types';

/* global sendFetch, getCsrfToken, showLoginModal, userData, filterXSS */

export const QuickieCommentSection = ({
  article,
  comments = [],
  totalCount = 0,
  maxVisibleComments = 2,
  isOpen = false,
  onClose,
  onCommentCreated,
  currentUserId,
}) => {
  const [commentText, setCommentText] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const textareaRef = useRef(null);

  useEffect(() => {
    if (isOpen && textareaRef.current) {
      textareaRef.current.focus();
    }
  }, [isOpen]);

  const currentUser = typeof userData === 'function' ? userData() : null;

  const isUserSignedIn = () => {
    if (document.body?.dataset?.userStatus === 'logged-out') {
      return false;
    }
    if (currentUserId || article.current_user_signed_in || currentUser) {
      return true;
    }
    return Boolean(document.body?.dataset?.user);
  };

  const adjustTextareaHeight = (element) => {
    if (!element) return;
    element.style.height = 'auto';
    element.style.height = `${Math.max(element.scrollHeight, 56)}px`;
  };

  const handleSubmit = async (event) => {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    const trimmed = commentText.trim();
    if (!trimmed || isSubmitting) {
      return;
    }

    if (!isUserSignedIn()) {
      if (typeof showLoginModal === 'function') {
        showLoginModal({
          referring_source: 'post_index_toolbar',
          trigger: 'comment',
        });
      }
      return;
    }

    setIsSubmitting(true);
    setErrorMessage('');

    try {
      const csrfToken =
        typeof getCsrfToken === 'function'
          ? await getCsrfToken()
          : window.csrfToken || 'csrf-token';

      if (!csrfToken || typeof sendFetch !== 'function') {
        setIsSubmitting(false);
        return;
      }

      const payload = JSON.stringify({
        comment: {
          body_markdown: trimmed,
          commentable_id: article.id,
          commentable_type: 'Article',
        },
      });

      const fetchCallback = sendFetch('comment-creation', payload);
      const response = await fetchCallback(csrfToken);
      const data =
        response && typeof response.json === 'function'
          ? await response.json()
          : null;

      if (data && (data.status === 'created' || data.id)) {
        const sanitizedFallback = `<p>${
          typeof filterXSS === 'function' ? filterXSS(trimmed) : trimmed
        }</p>`;

        let commentPath = `${article.path || article.url}#comment-${
          data.id_code || data.id
        }`;
        if (data.url) {
          try {
            commentPath = new URL(data.url, window.location.origin).pathname;
          } catch (_err) {
            commentPath = data.url;
          }
        }

        const createdComment = {
          id: data.id,
          comment_id: data.id,
          name:
            data.user?.name ||
            currentUser?.name ||
            currentUser?.username ||
            'Community Member',
          username: data.user?.username || currentUser?.username || '',
          profile_image_90:
            data.user?.profile_pic ||
            currentUser?.profile_image_90 ||
            '/assets/default-avatar.png',
          published_at_int: Math.floor(Date.now() / 1000),
          published_timestamp:
            data.published_timestamp || new Date().toISOString(),
          safe_processed_html: data.body_html || sanitizedFallback,
          path: commentPath,
        };

        setCommentText('');
        if (textareaRef.current) {
          textareaRef.current.style.height = '56px';
        }
        if (typeof onCommentCreated === 'function') {
          onCommentCreated(createdComment);
        }
      } else {
        setErrorMessage(
          data?.error || 'Could not post reply. Please try again.',
        );
      }
    } catch (_error) {
      setErrorMessage('Could not post reply. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const hasComments = comments && comments.length > 0;
  if (!isOpen && !hasComments) {
    return null;
  }

  const visibleComments = comments.slice(0, maxVisibleComments);

  return (
    <div
      className="quickie-inline-comments"
      onClick={(event) => event.stopPropagation()}
      role="presentation"
    >
      {isOpen && (
        <form
          className="quickie-comment-composer"
          onSubmit={handleSubmit}
          data-testid="quickie-comment-form"
        >
          <div className="quickie-comment-composer__row">
            {currentUser?.profile_image_90 && (
              <span className="crayons-avatar crayons-avatar--m shrink-0 mt-1">
                <img
                  src={currentUser.profile_image_90}
                  alt={currentUser.name || 'Your avatar'}
                  className="crayons-avatar__image"
                />
              </span>
            )}
            <div className="quickie-comment-composer__input-wrap">
              <textarea
                ref={textareaRef}
                className="crayons-textfield quickie-comment-composer__textarea"
                placeholder="Write a quick reply..."
                aria-label={`Write a reply to ${
                  article.user?.name || 'this quickie'
                }`}
                rows={2}
                maxLength={25000}
                value={commentText}
                disabled={isSubmitting}
                data-testid="quickie-comment-textarea"
                onInput={(event) => {
                  setCommentText(event.target.value);
                  adjustTextareaHeight(event.target);
                }}
                onKeyDown={(event) => {
                  event.stopPropagation();
                  if (
                    (event.metaKey || event.ctrlKey) &&
                    (event.key === 'Enter' || event.keyCode === 13)
                  ) {
                    handleSubmit(event);
                  } else if (
                    event.key === 'Escape' &&
                    commentText.trim() === '' &&
                    typeof onClose === 'function'
                  ) {
                    onClose();
                  }
                }}
              />
              {errorMessage && (
                <p
                  className="quickie-comment-composer__error fs-xs color-accent-danger mt-1"
                  role="alert"
                >
                  {errorMessage}
                </p>
              )}
              <div className="quickie-comment-composer__actions">
                <span className="quickie-comment-composer__hint fs-xs color-base-60 hidden s:inline">
                  Press <kbd>⌘</kbd>/<kbd>Ctrl</kbd> + <kbd>Enter</kbd> to reply
                </span>
                <div className="quickie-comment-composer__buttons">
                  <button
                    type="button"
                    className="crayons-btn crayons-btn--s crayons-btn--ghost"
                    onClick={(event) => {
                      event.preventDefault();
                      event.stopPropagation();
                      if (typeof onClose === 'function') {
                        onClose();
                      }
                    }}
                    disabled={isSubmitting}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="crayons-btn crayons-btn--s crayons-btn--primary"
                    disabled={isSubmitting || commentText.trim().length === 0}
                    data-testid="quickie-comment-submit"
                  >
                    {isSubmitting ? 'Posting...' : 'Reply'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </form>
      )}

      {hasComments && (
        <div className="crayons-story__comments">
          {visibleComments.map((comment) => (
            <CommentListItem
              key={comment.id || comment.comment_id || comment.path}
              comment={comment}
            />
          ))}

          {totalCount > maxVisibleComments && (
            <div className="crayons-story__comments__actions">
              <Button
                variant="ghost"
                size="s"
                tagName="a"
                className="-ml-2"
                url={`${article.url}#comments-container`}
                data-testid="see-all-comments"
              >
                See all {totalCount} comments
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

QuickieCommentSection.propTypes = {
  article: articlePropTypes.isRequired,
  comments: PropTypes.arrayOf(PropTypes.object),
  totalCount: PropTypes.number,
  maxVisibleComments: PropTypes.number,
  isOpen: PropTypes.bool,
  onClose: PropTypes.func,
  onCommentCreated: PropTypes.func,
  currentUserId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
};

QuickieCommentSection.displayName = 'QuickieCommentSection';
