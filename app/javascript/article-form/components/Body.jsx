import { h } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';
import { Toolbar } from './Toolbar';

export const Body = ({
  onChange, 
  defaultValue, 
  switchHelpContext
}) => {
  return (
    <div className="crayons-article-form__body">
      <Toolbar />

      <Textarea
        className="crayons-textfield crayons-article-form__body__field crayons-textfield--ghost fs-l ff-accent whitespace-prewrap"
        id="article_body_markdown"
        placeholder="Write your post content here..."
        value={defaultValue}
        onInput={onChange}
        onFocus={(_event) => {
          switchHelpContext(_event);
        }}
        name="body_markdown"
      />
    </div>
  );
}

Body.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
};

Body.displayName = 'Body';
