import { h } from 'preact';
import { selectedTagsPropTypes } from '../../common-prop-types';

const SelectedTags = ({ tags, onRemoveTag, onKeyPress }) => {
  return (
    <section>
      {tags.map((tag) => (
        <span className="listing-tag" key={tag.id} id={`selected-tag-${tag}`}>
          <a href={`/listings?t=${tag}`} className="tag-name" data-no-instant>
            <span role="button" tabIndex="0">
              {tag}
            </span>
            <span
              role="button"
              tabIndex="0"
              onClick={(e) => onRemoveTag(e, tag)}
              onKeyPress={(e) => onKeyPress(e, tag)}
            >
              ×
            </span>
          </a>
        </span>
      ))}
    </section>
  );
};

SelectedTags.propTypes = selectedTagsPropTypes;

export default SelectedTags;
