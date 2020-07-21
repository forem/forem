import { h } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';
import { Toolbar } from './Toolbar';

export const EditorBody = ({
  onChange,
  defaultValue,
  switchHelpContext,
  version,
}) => {
  let inputText = document.getElementById('article_body_markdown');

  let wordCount = document.getElementById('count');

  if (inputText) {
    inputText.addEventListener('keyup', function () {
      let words = inputText.value.match(/\b[-?(\w+)?]+\b/gi);
      if (words) {
        wordCount.innerHTML = words.length;
      } else {
        wordCount.innerHTML = 0;
      }
    });
  }

  return (
    <div
      data-testid="article-form__body"
      className="crayons-article-form__body text-padding"
    >
      <Toolbar version={version} />

      <Textarea
        className="crayons-textfield crayons-textfield--ghost crayons-article-form__body__field"
        id="article_body_markdown"
        aria-label="Post Content"
        placeholder="Write your post content here..."
        value={defaultValue}
        onInput={onChange}
        onFocus={(_event) => {
          switchHelpContext(_event);
        }}
        name="body_markdown"
      />

      <div class="crayons-card" style="width:20%; margin-top:30px;">
        <div class="crayons-card crayons-card--secondary">
          <div style="color:grey;">
            {' '}
            Words:{' '}
            <span id="count" style="color:grey;">
              {' '}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

EditorBody.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  version: PropTypes.string.isRequired,
};

EditorBody.displayName = 'EditorBody';
