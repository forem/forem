import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class OnboardingSingleTag extends Component {
  constructor(props) {
    super(props);
    this.onClick = this.onClick.bind(this);
  }

  onClick() {
    this.props.onTagClick(this.props.tag);
  }

  render() {
    return (
      <div className={`onboarding-tag-container${this.props.tag.following ? ' followed-tag' : ''}`} id={`onboarding-tag-container-${this.props.tag.name}`} style={`background: ${this.props.tag.bg_color_hex}`}>
        <a
          className="onboarding-tag-link"
          href="#"
          style={`color:${this.props.tag.text_color_hex}`}
          onClick={this.onClick}
        >
          {this.props.tag.name}
        </a>
        <a
          className="onboarding-tag-link-follow"
          href="#"
          id={`onboarding-tag-link-follow-${this.props.tag.name}`}
          onClick={this.onClick}
        >
          {this.props.tag.following ? '✓' : '+'}
        </a>
      </div>
    );
  }
}

OnboardingSingleTag.propTypes = {
  onTagClick: PropTypes.func.isRequired,
  tag: PropTypes.object.isRequired,
};

export default OnboardingSingleTag;
