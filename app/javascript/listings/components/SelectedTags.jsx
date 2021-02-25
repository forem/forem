import { h } from 'preact';
import { selectedTagsPropTypes } from '../../common-prop-types';

export const SelectedTags = ({ tags, onRemoveTag, onKeyPress }) => {
  return (
    <section class="pt-2">
      {tags.map((tag) => (
        <span
          className="listing-tag mr-1"
          key={tag.id}
          id={`selected-tag-${tag}`}
        >
          <a
            href={`/listings?t=${tag}`}
            className="tag-name crayons-tag"
            data-no-instant
          >
            <span className="crayons-tag__prefix">#</span>
            <span role="button" tabIndex="0">
              {tag}
            </span>
            <span
              role="button"
              tabIndex="0"
              className="px-1"
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
