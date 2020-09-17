import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';

export class SaveButton extends Component {
  constructor(props) {
    super(props);

    const { isBookmarked } = props;

    this.state = {
      buttonText: isBookmarked ? 'Saved' : 'Save',
    };
  }

  render() {
    const { buttonText } = this.state;
    const { article, isBookmarked, onClick } = this.props;

    const mouseMove = (_e) => {
      this.setState({ buttonText: isBookmarked ? 'Unsave' : 'Save' });
    };

    const mouseOut = (_e) => {
      this.setState({ buttonText: isBookmarked ? 'Saved' : 'Save' });
    };

    const handleClick = (_e) => {
      onClick(_e);
      this.setState({
        buttonText: isBookmarked ? 'Save' : 'Saved',
        isBookmarked: !isBookmarked,
      });
    };

    if (article.class_name === 'Article') {
      return (
        <button
          type="button"
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
          {buttonText}
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
