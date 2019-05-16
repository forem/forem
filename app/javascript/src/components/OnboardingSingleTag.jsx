import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class OnboardingSingleTag extends Component {
  propTypes = {
    onTagClick: PropTypes.func.isRequired,
    tag: PropTypes.objectOf().isRequired,
  };

  constructor(props) {
    super(props);
    this.onClick = this.onClick.bind(this);
  }

  onClick() {
    const { onTagClick, tag } = this.props;
    onTagClick(tag);
  }

  render() {
    const { tag } = this.props;
    const backgroundColor = tag.following ? tag.bg_color_hex : '';
    const textroundColor = tag.following ? tag.text_color_hex : '';
    return (
      <div
        className={`onboarding-tag-container${
          tag.following ? ' followed-tag' : ''
        }`}
        id={`onboarding-tag-container-${tag.name}`}
        style={`background: ${backgroundColor}`}
      >
        <a
          className="onboarding-tag-link"
          href="#0"
          style={`color:${textroundColor}`}
          onClick={this.onClick}
        >
          #{tag.name}
        </a>
        <a
          className="onboarding-tag-link-follow"
          href="#0"
          id={`onboarding-tag-link-follow-${tag.name}`}
          style={`color:${textroundColor}`}
          onClick={this.onClick}
        >
          {tag.following ? '✓' : '+'}
        </a>
      </div>
    );
  }
}

export default OnboardingSingleTag;
