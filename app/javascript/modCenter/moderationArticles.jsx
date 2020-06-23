import { h, Component } from 'preact';
import SingleArticle from './singleArticle';

export class ModerationArticles extends Component {
  state = {
    articles: JSON.parse(
      document.getElementById('mod-index-list').dataset.articles,
    ),
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
              key={id}
              publishedAt={publishedAt}
              user={user}
            />
          );
        })}
      </div>
    );
  }
}
