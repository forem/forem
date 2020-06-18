import PropTypes from 'prop-types';
import { h, Component } from 'preact';
import { formatDate } from './util';

export default class SingleArticle extends Component {
  constructor(props) {
    super(props);

    this.state = {
      articleOpened: false,
    };
  }

  toggleArticle = (e) => {
    e.preventDefault();

    const { id, path } = this.props;
    const { articleOpened } = this.state;
    if (articleOpened) {
      this.setState({ articleOpened: false });
      document.getElementById(`article-iframe-${id}`).innerHTML = '';
    } else {
      this.setState({ articleOpened: true });
      document.getElementById(
        `article-iframe-${id}`,
      ).innerHTML = `<iframe class="article-iframe" src="${path}"></iframe><iframe class="actions-panel-iframe" src="${path}/actions_panel"></iframe>`;
    }
  };

  render() {
    const { id, title, publishedAt, cachedTagList, user } = this.props;
    const tags = cachedTagList.split(', ').map((tag) => {
      return (
        <span className="mod-article-tag fs-s ff-accent lh-base">
          <span className="article-hash-tag">#</span>
          {tag}
        </span>
      );
    });

    const newAuthorNotification = user.articles_count <= 3 ? '👋 ' : '';

    return (
      <button
        type="button"
        className="moderation-single-article"
        onClick={this.toggleArticle}
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
          {formatDate(publishedAt)}
        </span>
        <div
          className="article-iframes-container"
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
};
