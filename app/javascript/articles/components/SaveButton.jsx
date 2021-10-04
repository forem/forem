import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';
import { i18next } from '../../i18n/l10n';

export class SaveButton extends Component {
  constructor(props) {
    super(props);

    const { isBookmarked } = props;

    this.state = {
      buttonText: isBookmarked ? 'saved' : 'save',
    };
  }

  render() {
    const { buttonText } = this.state;
    const { article, isBookmarked, onClick } = this.props;

    const mouseMove = (_e) => {
      this.setState({ buttonText: isBookmarked ? 'unsave' : 'save' });
    };

    const mouseOut = (_e) => {
      this.setState({ buttonText: isBookmarked ? 'saved' : 'save' });
    };

    const handleClick = (_e) => {
      onClick(_e);
      this.setState({
        buttonText: isBookmarked ? 'save' : 'saved',
        isBookmarked: !isBookmarked,
      });
    };

    if (article.class_name === 'Article') {
      return (
        <button
          type="button"
          id={`article-save-button-${article.id}`}
          className={`crayons-btn crayons-btn--s ${
            isBookmarked ? 'crayons-btn--ghost' : 'crayons-btn--secondary'
          }`}
          data-initial-feed
          data-reactable-id={article.id}
          onClick={handleClick}
          onMouseMove={mouseMove}
          onFocus={mouseMove}
          onMouseout={mouseOut}
          onBlur={mouseOut}
        >
          {i18next.t(`articles.save.${buttonText}`)}
        </button>
      );
    }
    if (article.class_name === 'User') {
      return (
        <button
          type="button"
          className="crayons-btn crayons-btn--secondary fs-s"
          data-info={`{"id":${article.id},"className":"User"}`}
          data-follow-action-button
        >
          &nbsp;
        </button>
      );
    }

    return null;
  }
}

SaveButton.propTypes = {
  article: articlePropTypes.isRequired,
  isBookmarked: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired,
};

SaveButton.displayName = 'SaveButton';
