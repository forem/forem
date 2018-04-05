import { h, render, Component } from 'preact';
import PropTypes from 'prop-types';

class OnboardingArticles extends Component {
  constructor(props) {
    super(props);
    this.handleAllClick = this.handleAllClick.bind(this);
  }


  handleAllClick() {
    this.props.handleSaveAllArticles();
  }

  render() {
    const articles = this.props.articles.map((article) => {
      return (
        <div className="onboarding-user-list-row" key={article.user.id} >
          <div className="onboarding-user-list-key article">
            <h3>{article.title}</h3>
            <img
              src={article.user.profile_image_url}
              alt={article.user.name}
            />
            <span>{article.user.name}</span>
            <p>{article.description.length < 75 ? article.description : `${article.description.substring(0, 75)}...`}</p>
            <div className="onboarding-article-engagement">
              <img
                src="https://practicaldev-herokuapp-com.freetls.fastly.net/assets/reactions-stack-4bb9c1e4b3e71b7aa135d6f9a5ef29a6494141da882edd4fa971a77abe13dbe7.png"
                alt="Reactions"
              /> {article.positive_reactions_count}
              <img
                src="https://practicaldev-herokuapp-com.freetls.fastly.net/assets/comments-bubble-7448082accd39cfe9db9b977f38fa6e8f8d26dc43e142c5d160400d6f952ee47.png"
                alt="Comments"
              /> {article.comments_count}
            </div>
          </div>
          <div className="onboarding-user-list-checkbox article">
            <button
              onClick={this.props.handleSaveArticle.bind(this, article)}
              className={`article save-single ${this.props.savedArticles.indexOf(article) > -1 ? 'saved' : ''}`}
            >
              {this.props.savedArticles.indexOf(article) > -1 ? 'SAVED' : 'SAVE'}
            </button>
          </div>
        </div>
      );
    });

    return (
      <div className="onboarding-user-container">
        <div className="onboarding-user-cta">
          When you see an interesting post, you can <strong className="purple">SAVE</strong> it. To get started, here are pre-selected suggestions.
        </div>
        <div className="onboarding-user-list">
          <div className="onboarding-user-list-header onboarding-user-list-row">
            <div className="onboarding-user-list-key">
              Save All
            </div>
            <div className="onboarding-user-list-checkbox">
              <button
                onClick={this.handleAllClick}
                className={`article save-all ${this.props.savedArticles.length === this.props.articles.length ? 'saved' : ''}`}
              >
                {this.props.savedArticles.length === this.props.articles.length ? '✓' : '+'}
              </button>
            </div>
          </div>
          <div className="onboarding-user-list-body">{articles}</div>
        </div>
      </div>
    );
  }
}

OnboardingArticles.propTypes = {
  handleSaveArticle: PropTypes.func.isRequired,
  handleSaveAllArticles: PropTypes.func.isRequired,
};

export default OnboardingArticles;
