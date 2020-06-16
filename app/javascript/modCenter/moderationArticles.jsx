import { h, Component } from 'preact';
// import { request } from "../utilities/http"
import SingleArticle from './singleArticle';

export class ModerationArticles extends Component {
  state = {
    articles: [],
    articleOpened: false,
  };

  componentWillMount() {
    const container = document.getElementById('mod-index-list');
    const articles = JSON.parse(container.dataset.articles);
    this.setState({
      articles,
    });
  }

  toggleArticle = (e, id, path) => {
    e.preventDefault();

    const { articleOpened } = this.state;
    if (articleOpened) {
      this.setState({ articleOpened: false });
      document.getElementById(`article-iframe-${id}`).innerHTML = '';
    } else {
      this.setState({ articleOpened: true });
      document.getElementById(`article-iframe-${id}`).innerHTML = `
  <iframe class="article-iframe" src="${path}"></iframe><iframe class="actions-panel-iframe" src="${path}/actions_panel"></iframe>
      `;
    }
  };

  render() {
    const { articles } = this.state;

    return (
      <div className="moderation-articles-list">
        {articles.map((article) => {
          const {
            id,
            title,
            path,
            cached_tag_list: cachedTagList,
            published_at: publishedAt,
            user,
          } = article;
          return (
            <SingleArticle
              id={id}
              title={title}
              path={path}
              cachedTagList={cachedTagList}
              publishedAt={publishedAt}
              user={user}
              toggleArticle={this.toggleArticle}
            />
          );
        })}
      </div>
    );
  }
}
