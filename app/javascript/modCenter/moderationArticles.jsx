import { h, Component } from 'preact';
import { SingleArticle } from './singleArticle';

export class ModerationArticles extends Component {
  state = {
    articles: JSON.parse(
      document.getElementById('mod-index-list').dataset.articles,
    ),
    prevSelectedArticleId: undefined,
  };

  toggleArticle = (id, title, path) => {
    const { prevSelectedArticleId } = this.state;
    const selectedArticle = document.getElementById(`article-iframe-${id}`);
    const selectedDetailsPanel = document.getElementById(`mod-article-${id}`);

    if (prevSelectedArticleId > 0) {
      if (selectedDetailsPanel.getAttribute('open') !== null) {
        if (prevSelectedArticleId !== id) {
          document
            .getElementById(`mod-article-${prevSelectedArticleId}`)
            ?.removeAttribute('open');
        }
      } else {
        document.getElementById(`article-iframe-${id}`).innerHTML = '';
      }
    }

    if (selectedDetailsPanel.getAttribute('open') !== null) {
      selectedArticle.innerHTML = `
      <div class="article-referrer-heading">
        <a class="article-title-link fw-bold" href=${path}>
          ${title}
        </a>
      </div>
      <div class="iframes-container">
        <iframe class="article-iframe" src="${path}"></iframe>
        <iframe data-testid="mod-iframe-${id}" id="mod-iframe-${id}" class="actions-panel-iframe" id="mod-iframe-${id}" src="${path}/actions_panel/?is_mod_center=true"></iframe>
      </div>`;

      this.setState({ prevSelectedArticleId: id });
    } else {
      document
        .getElementById(`article-iframe-${id}`)
        .classList.remove('opened');
    }
  };

  render() {
    const { articles, prevSelectedArticleId } = this.state;

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
              articleOpened={id === prevSelectedArticleId}
              toggleArticle={this.toggleArticle}
            />
          );
        })}
      </div>
    );
  }
}
