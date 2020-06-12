import { h, Component } from 'preact';
// import { request } from "../utilities/http"
import SingleArticle from './singleArticle';

export class ModerationArticles extends Component {
  state = {
    articles: [],
  };

  componentWillMount() {
    const container = document.getElementById('mod-index-list');
    const articles = JSON.parse(container.dataset.articles);
    this.setState({
      articles,
    });
  }

  render() {
    const { articles } = this.state;

    return (
      <div className="moderation-articles-list">
        {articles.map((article) => {
          const {
            title,
            path,
            cached_tag_list: cachedTagList,
            published_at: publishedAt,
            user,
          } = article;
          return (
            <SingleArticle
              title={title}
              path={path}
              cachedTagList={cachedTagList}
              publishedAt={publishedAt}
              user={user}
            />
          );
        })}
      </div>
    );
  }
}
