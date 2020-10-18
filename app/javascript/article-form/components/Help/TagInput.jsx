import { h } from 'preact';
import PropTypes from 'prop-types';

const TagInput = ({ show }) => {
  if (show) {
    return (
      <div
        data-testid="basic-tag-input-help"
        className="crayons-article-form__help crayons-article-form__help--tags"
      >
        <h4 className="mb-2 fs-l">Tagging Guidelines</h4>
        <ul className="list-disc pl-6 color-base-70">
          <li>Tags help people find your post.</li>
          <li>
            Think of tags as the topics or categories that best describe your
            post.
          </li>
          <li>
            Add up to four tags per post. Combine tags to reach the appropriate
            subcommunities.
          </li>
          <li>Use existing tags whenever possible.</li>
          <li>
            Some tags, such as “help” or “healthydebate”, have special posting
            guidelines.
          </li>
        </ul>
      </div>
    );
  }

  return null;
};

TagInput.propTypes = {
  show: PropTypes.bool.isRequired,
};

export default TagInput;
