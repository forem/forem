import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../src/components/common-prop-types';

export class SaveButton extends Component {
  componentDidMount() {
    const { isBookmarked } = this.props;
    this.setState({ buttonText: isBookmarked ? 'Saved' : 'Save' });
  }

  render() {
    const { buttonText } = this.state;
    const { article, isBookmarked, onClick } = this.props;
    const mouseOut = _e => {
      this.setState({ buttonText: isBookmarked ? 'Saved' : 'Save' });
    };
    const mouseOver = _e => {
      if (isBookmarked) {
        this.setState({ buttonText: 'Unsave' });
      }
    };

    if (article.class_name === 'Article') {
      return (
        <button
          type="button"
          className={`crayons-btn crayons-btn--secondary crayons-btn--icon-left fs-s ${
            isBookmarked ? 'selected' : ''
          }`}
          data-initial-feed
          data-reactable-id={article.id}
          onClick={onClick}
          onMouseOver={mouseOver}
          onFocus={mouseOver}
          onMouseout={mouseOut}
          onBlur={mouseOut}
        >
          <svg class="crayons-icon" width="24" height="24" xmlns="http://www.w3.org/2000/svg"><path d="M6.75 4.5h10.5a.75.75 0 01.75.75v14.357a.375.375 0 01-.575.318L12 16.523l-5.426 3.401A.375.375 0 016 19.607V5.25a.75.75 0 01.75-.75zM16.5 6h-9v11.574l4.5-2.82 4.5 2.82V6z" /></svg>
          {buttonText}
        </button>
      );
    }
    if (article.class_name === 'User') {
      return (
        <button
          type="button"
          className="crayons-btn crayons-btn--secondary crayons-btn--icon-left fs-s"
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
