import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';
import { Toolbar } from './Toolbar';

export class Body extends Component {
  state = {
    hasFocus: false
  }

  render() {
    const { onChange, defaultValue } = this.props;
    const { hasFocus } = this.state;
    return (
      <div
        className="crayons-article-form__body"
        tabIndex={0} // eslint-disable-line
        onFocus={(_event) => {
          this.setState({ hasFocus: true });
        }}
        onBlur={(_event) => {
          this.setState({ hasFocus: false });
        }}
      >
        <Toolbar visible={hasFocus} />

        <Textarea
          className="crayons-textfield crayons-textfield--ghost fs-l ff-accent min-h-100"
          id="article_body_markdown"
          placeholder="Write your post content here..."
          value={defaultValue}
          onInput={onChange}
          onFocus={(_event) => {
            this.setState({ hasFocus: true });
          }}
          onBlur={(_event) => {
            this.setState({ hasFocus: false });
          }}
          name="body_markdown"
        />
      </div>
    );
  }
}

Body.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

Body.displayName = 'Body';
