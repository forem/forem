import { h, Component } from 'preact';
import { SingleArticle } from './singleArticle';

export class ModerationArticles extends Component {
  state = {
    articles: JSON.parse(
      document.getElementById('mod-index-list').dataset.articles,
    ),
    prevSelectedArticleId: undefined,
    selectedArticleId: undefined,
  };

  toggleArticle = (id, path) => {
    const { prevSelectedArticleId } = this.state;
    const selectedArticle = document.getElementById(`article-iframe-${id}`);

    if (prevSelectedArticleId > 0) {
      document.getElementById(
        `article-iframe-${prevSelectedArticleId}`,
      ).innerHTML = '';
    }

    this.setState({ selectedArticleId: id, prevSelectedArticleId: id });

    if (
      id === prevSelectedArticleId &&
      document.getElementsByClassName('opened').length > 0
    ) {
      selectedArticle.classList.remove('opened');
      return;
    }

    selectedArticle.classList.add('opened');
    selectedArticle.innerHTML = `<iframe class="article-iframe" src="${path}"></iframe><iframe data-testid="mod-iframe-${id}" class="actions-panel-iframe" id="mod-iframe-${id}" src="${path}/actions_panel"></iframe>`;
  };

  render() {
    const { articles, selectedArticleId } = this.state;

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
              articleOpened={id === selectedArticleId}
              toggleArticle={this.toggleArticle}
            />
          );
        })}
      </div>
    );
  }
}
