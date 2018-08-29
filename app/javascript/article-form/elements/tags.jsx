import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class Tags extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div className="articleform__tagswrapper">
        <textarea
          id="tag-input"
          type="text"
          className="articleform__tags"
          placeholder="tags"
          value={this.props.defaultValue}
          onInput={this.props.onInput}
          onKeyDown={this.props.onKeyDown}
          onBlur={this.props.onFocusChange}
          onFocus={this.props.onFocusChange}
        />
        {this.props.options}
      </div>
    );
  }
}

Tags.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  options: PropTypes.array.isRequired,
};

export default Tags;
