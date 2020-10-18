import { h } from 'preact';
import PropTypes from 'prop-types';

const ArticleFormTitle = ({ show }) => {
  if (show) {
    return (
      <div
        data-testid="title-help"
        className="crayons-article-form__help crayons-article-form__help--title"
      >
        <h4 className="mb-2 fs-l">Writing a Great Post Title</h4>
        <ul className="list-disc pl-6 color-base-70">
          <li>
            Think of your post title as a super short (but compelling!)
            description — like an overview of the actual post in one short
            sentence.
          </li>
          <li>
            Use keywords where appropriate to help ensure people can find your
            post by search.
          </li>
        </ul>
      </div>
    );
  }
  return null;
};

ArticleFormTitle.propTypes = {
  show: PropTypes.bool.isRequired,
};

export default ArticleFormTitle;
