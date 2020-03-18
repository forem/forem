import { h } from 'preact';
import PropTypes from 'prop-types';

const Article = ({ resource: article }) => (
  <div className="activechatchannel__activeArticle">
    <iframe src={article.path} title={article.title} />
  </div>
);

Article.propTypes = {
  resource: PropTypes.shape({
    id: PropTypes.string,
  }).isRequired,
};
export default Article;
