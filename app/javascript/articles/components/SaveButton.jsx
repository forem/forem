import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';

export class SaveButton extends Component {
  constructor(props) {
    super(props);

    const { isBookmarked } = props;

    this.state = {
      buttonText: isBookmarked ? 'Saved' : 'Save',
      hovering: false,
    };
  }

  render() {
    //const { hovering } = this.state.hovering;

    const { article, isBookmarked, onClick } = this.props;

    const mouseOver = (_e) => {
      this.setState({ hovering: true });
    };

    const mouseOut = (_e) => {
      this.setState({ hovering: false });
    };

    const handleClick = (_e) => {
      onClick(_e);
      this.setState({ buttonText: isBookmarked ? 'Unsave' : 'Saved' });
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
          onMouseOver={mouseOver}
          onFocus={mouseOver}
          onMouseout={mouseOut}
          onBlur={mouseOut}
        >
          {this.state.hovering
            ? isBookmarked
              ? 'Unsave'
              : 'Save'
            : isBookmarked
            ? 'Saved'
            : 'Save'}
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
