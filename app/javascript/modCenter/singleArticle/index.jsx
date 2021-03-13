import PropTypes from 'prop-types';
import { h, Component, Fragment } from 'preact';
import { createPortal } from 'preact/compat';
import { FlagUserModal } from '../../packs/flagUserModal';
import { formatDate } from './util';

export class SingleArticle extends Component {
  activateToggle = (e) => {
    e.preventDefault();
    const { id, path, toggleArticle } = this.props;

    toggleArticle(id, path);
  };

  tagsFormat = (tag, key) => {
    if (tag) {
      return (
        <span className="crayons-tag" key={key}>
          <span className="crayons-tag__prefix">#</span>
          {tag}
        </span>
      );
    }
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
      this.tagsFormat(tag, key);
    });

    const newAuthorNotification = user.articles_count <= 3 ? '👋 ' : '';
    const modContainer = id
      ? document.getElementById(`mod-iframe-${id}`)
      : document.getElementById('mod-container');

    return (
      <Fragment>
        {modContainer &&
          createPortal(
            <FlagUserModal moderationUrl={path} authorId={user.id} />,
            document.getElementsByClassName('flag-user-modal-container')[0],
          )}
        <button
          data-testid={`mod-article-${id}`}
          type="button"
          className="moderation-single-article"
          onClick={this.activateToggle}
        >
          <span className="article-title">
            <header>
              <h3 className="fs-base fw-bold lh-tight">
                <a className="article-title-link" href={path}>
                  {title}
                </a>
              </h3>
            </header>
            {tags}
          </span>
          <span className="article-author">
            {newAuthorNotification}
            {user.name}
          </span>
          <span className="article-published-at">
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
