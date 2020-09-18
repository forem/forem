import PropTypes from 'prop-types';
import { h, Component, Fragment } from 'preact';
import { createPortal } from 'preact/compat';
import { toggleFlagUserModal, FlagUserModal } from '../../packs/flagUserModal';
import { formatDate } from './util';

export default class SingleArticle extends Component {
  activateToggle = (e) => {
    e.preventDefault();
    const { id, path, toggleArticle } = this.props;

    toggleArticle(id, path);
  };

  render() {
    const {
      id,
      title,
      publishedAt,
      cachedTagList,
      user,
      key,
      articleOpened,
      path,
    } = this.props;
    const tags = cachedTagList.split(', ').map((tag) => {
      if (tag) {
        return (
          <span className="crayons-tag" key={key}>
            <span className="crayons-tag__prefix">#</span>
            {tag}
          </span>
        );
      }
    });

    const newAuthorNotification = user.articles_count <= 3 ? '👋 ' : '';
    const modContainer = id
      ? document.getElementById(`mod-iframe-${id}`)
      : document.getElementById('mod-container');

    // Check whether context is ModCenter or Friday-Night-Mode
    if (modContainer) {
      modContainer.addEventListener('load', () => {
        modContainer.contentWindow.document
          .getElementById('open-flag-user-modal')
          .addEventListener('click', toggleFlagUserModal);
      });
    }

    return (
      <Fragment>
        {modContainer &&
          createPortal(
            <FlagUserModal moderationUrl={path} authorId={user.id} />,
            document.querySelector('.flag-user-modal-container'),
          )}
        <button
          data-testid={`mod-article-${id}`}
          type="button"
          className="moderation-single-article"
          onClick={this.activateToggle}
        >
          <span className="article-title">
            <header>
              <h3 className="fs-base fw-bold lh-tight">{title}</h3>
            </header>
            {tags}
          </span>
          <span className="article-author fs-s lw-medium lh-tight">
            {newAuthorNotification}
            {user.name}
          </span>
          <span className="article-published-at fs-s fw-bold lh-tight">
            <time dateTime={publishedAt}>{formatDate(publishedAt)}</time>
          </span>
          <div
            className={`article-iframes-container ${
              articleOpened ? 'opened' : ''
            }`}
            id={`article-iframe-${id}`}
          />
        </button>
      </Fragment>
    );
  }
}

SingleArticle.propTypes = {
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired,
  publishedAt: PropTypes.string.isRequired,
  cachedTagList: PropTypes.isRequired,
  user: PropTypes.isRequired,
  key: PropTypes.number.isRequired,
};
