import { h } from 'preact';
import PropTypes from 'prop-types';

export const Article = ({ resource: article }) => (
  <div className="activechatchannel__activeArticle">
    <iframe
      id="activecontent-iframe"
      src={article.path}
      title={article.title}
    />
  </div>
);

Article.propTypes = {
  resource: PropTypes.shape({
    id: PropTypes.string,
  }).isRequired,
};
