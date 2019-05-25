import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import OnboardingArticle, { ARTICLE_PROP_TYPE } from './OnboardingArticle';

class OnboardingArticles extends Component {
  constructor(props) {
    super(props);
    this.handleAllClick = this.handleAllClick.bind(this);
  }

  handleAllClick() {
    this.props.handleSaveAllArticles();
  }

  render() {
    const { articles, savedArticles, handleSaveArticle } = this.props;
    const onboardingArticles = articles.map(article => (
      <OnboardingArticle
        article={article}
        isSaved={savedArticles.indexOf(article) > -1}
        // eslint-disable-next-line react/jsx-no-bind
        onSaveArticle={handleSaveArticle.bind(this, article)}
      />
    ));
    const areAllSaved = savedArticles.length === articles.length;

    return (
      <div className="onboarding-user-container">
        <div className="onboarding-user-cta">
          When you see an interesting post, you can
          {' '}
          <strong className="purple">SAVE</strong>
          {' '}
it. To get started, here are
          pre-selected suggestions.
        </div>
        <div className="onboarding-user-list">
          <div className="onboarding-user-list-header onboarding-user-list-row">
            <div className="onboarding-user-list-key">Save All</div>
            <div className="onboarding-user-list-checkbox">
              <button
                onClick={this.handleAllClick}
                className={`article save-all ${areAllSaved ? 'saved' : ''}`}
              >
                {areAllSaved ? '✓' : '+'}
              </button>
            </div>
          </div>
          <div className="onboarding-user-list-body">{onboardingArticles}</div>
        </div>
      </div>
    );
  }
}

OnboardingArticles.propTypes = {
  articles: PropTypes.arrayOf(PropTypes.shape(ARTICLE_PROP_TYPE)).isRequired,
  savedArticles: PropTypes.arrayOf(PropTypes.shape(ARTICLE_PROP_TYPE))
    .isRequired,
  handleSaveArticle: PropTypes.func.isRequired,
  handleSaveAllArticles: PropTypes.func.isRequired,
};

export default OnboardingArticles;
