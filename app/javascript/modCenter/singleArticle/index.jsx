import PropTypes from 'prop-types';
import { h, Component, Fragment } from 'preact';
import { createPortal } from 'preact/compat';
import { FlagUserModal } from '../../packs/flagUserModal';
import { formatDate } from './util';

export class SingleArticle extends Component {
  activateToggle = () => {
    const { id, title, path, toggleArticle } = this.props;

    toggleArticle(id, title, path);
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
        <details
          id={`mod-article-${id}`}
          data-testid={`mod-article-${id}`}
          className="moderation-single-article"
          onToggle={this.activateToggle}
        >
          <summary>
            <div className="article-details-container">
              <span className="article-title">
                <header>
                  <h3 className="fs-base fw-bold lh-tight article-title-heading">
                    {title}
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
            </div>
          </summary>
          <div
            className={`article-iframes-container${
              articleOpened ? ' opened' : ''
            }`}
            id={`article-iframe-${id}`}
          />
        </details>
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
