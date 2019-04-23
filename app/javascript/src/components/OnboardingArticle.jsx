import { h } from 'preact';
import PropTypes from 'prop-types';
import { userPropTypes } from './common-prop-types';

const MAX_ARTICLE_DESCRIPTION_LENGTH = 75;

export const ARTICLE_PROP_TYPE = {
  user: userPropTypes,
  title: PropTypes.string.isRequired,
  description: PropTypes.string.isRequired,
  positive_reactions_count: PropTypes.number.isRequired,
  comments_count: PropTypes.number.isRequired,
};

const OnboardingArticle = ({ article, isSaved, onSaveArticle }) => (
  <div className="onboarding-user-list-row" key={article.user.id}>
    <div className="onboarding-user-list-key article">
      <h3>{article.title}</h3>
      <img src={article.user.profile_image_url} alt={article.user.name} />
      <span>{article.user.name}</span>
      <p>
        {article.description.length < MAX_ARTICLE_DESCRIPTION_LENGTH
          ? article.description
          : `${article.description.substring(
              0,
              MAX_ARTICLE_DESCRIPTION_LENGTH,
            )}...`}
      </p>
      <div className="onboarding-article-engagement">
        <img
          src="https://practicaldev-herokuapp-com.freetls.fastly.net/assets/reactions-stack-4bb9c1e4b3e71b7aa135d6f9a5ef29a6494141da882edd4fa971a77abe13dbe7.png"
          alt="Reactions"
        />
        {' '}
        {article.positive_reactions_count}
        <img
          src="https://practicaldev-herokuapp-com.freetls.fastly.net/assets/comments-bubble-7448082accd39cfe9db9b977f38fa6e8f8d26dc43e142c5d160400d6f952ee47.png"
          alt="Comments"
        />
        {' '}
        {article.comments_count}
      </div>
    </div>
    <div className="onboarding-user-list-checkbox article">
      <button
        onClick={onSaveArticle}
        className={`article save-single ${isSaved ? 'saved' : ''}`}
      >
        {isSaved ? 'SAVED' : 'SAVE'}
      </button>
    </div>
  </div>
);

OnboardingArticle.propTypes = {
  article: PropTypes.shape(ARTICLE_PROP_TYPE).isRequired,
  isSaved: PropTypes.bool.isRequired,
  onSaveArticle: PropTypes.func.isRequired,
};

export default OnboardingArticle;
