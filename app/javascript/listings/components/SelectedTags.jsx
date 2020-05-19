import { h } from 'preact';
import { selectedTagsPropTypes } from '../../common-prop-types';

const SelectedTags = ({ tags, onClick, onKeyPress }) => {
  return (
    <section>
      {tags.map((tag) => (
        <span
          className="listing-tag"
          key={tag.id}
          id={`selected-tag-${tag.id}`}
        >
          <a
            href="/listings?tags="
            className="tag-name"
            onClick={onClick}
            data-no-instant
          >
            <span>{tag}</span>
            <button
              className="tag-close"
              t
              type="button"
              data-no-instant
              onKeyPress={onKeyPress}
            >
              ×
            </button>
          </a>
        </span>
      ))}
    </section>
  );
};

SelectedTags.propTypes = selectedTagsPropTypes;

export default SelectedTags;
