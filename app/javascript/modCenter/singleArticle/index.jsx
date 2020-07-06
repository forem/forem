import PropTypes from 'prop-types';
import { h, Component } from 'preact';
import initializeFlagUserModal from '../../packs/flagUserModal';
import { formatDate } from './util';

export default class SingleArticle extends Component {

  activateToggle = (e) => {
    e.preventDefault();

    const { id, path, user, toggleArticle } = this.props;
    toggleArticle(id, path);
    initializeFlagUserModal(user.id, path, id);
  };

  render() {
    const { id, title, publishedAt, cachedTagList, user, key, articleOpened } = this.props;
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

    console.log(`Current State of articleOpened: ${articleOpened}`);

    return (
      <button
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
