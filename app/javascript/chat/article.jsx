import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export default class Article extends Component {
  static propTypes = {
    resource: PropTypes.shape({
      id: PropTypes.string,
    }).isRequired,
  };

  render() {
    const { resource: article } = this.props;
    return (
      <div className="activechatchannel__activeArticle">
        <iframe src={article.path} title={article.title} />
      </div>
    );
  }
}
