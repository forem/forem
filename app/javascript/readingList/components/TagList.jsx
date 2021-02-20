import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 *
 * @param {object} props
 * @param {Array<string>} props.availableTags A list of available tags.
 * @param {string} [props.selectedTag=''] The currently selected tag.
 * @param {function} A handler for when the selected tag changes.
 */
export function TagList({ availableTags, selectedTag = '', onSelectTag }) {
  return (
    <select
      class="crayons-select"
      aria-label="Filter by tag"
      onBlur={(event) => {
        // We need blur for a11y, but we also don't want to make the same search query twice
        // if the tag hasn't changed since the previous onChange.
        const { value } = event.target;

        if (value === selectedTag) {
          return;
        }

        onSelectTag(event);
      }}
      onChange={onSelectTag}
    >
      {selectedTag === '' && <option>Select a tag...</option>}
      {availableTags.map((tag) => (
        <option
          selected={tag === selectedTag}
          className={`crayons-link crayons-link--block ${
            tag === selectedTag ? 'crayons-link--current' : ''
          }`}
          value={tag}
        >
          {tag}
        </option>
      ))}
    </select>
  );
}

TagList.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedTag: PropTypes.string,
  onSelectTag: PropTypes.func.isRequired,
};
