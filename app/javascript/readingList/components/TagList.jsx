import { h } from 'preact';
import PropTypes from 'prop-types';

function LargeScreenTagList({ availableTags, selectedTag, onSelectTag }) {
  return (
    <fieldset className="hidden grid grid-cols-1 gap-2">
      <legend className="hidden">Filter by tag</legend>
      {availableTags.map((tag) => (
        <label
          className={`crayons-link crayons-link--block${
            selectedTag === tag ? ' crayons-link--current' : ''
          }`}
          aria-label={`${tag} tag`}
        >
          <input
            type="radio"
            name="filterTag"
            onClick={onSelectTag}
            key={tag}
            className="opacity-0"
            checked={selectedTag === tag}
            value={tag}
          />
          #{tag}
        </label>
      ))}
    </fieldset>
  );
}

/**
 *
 * @param {object} props
 * @param {Array<string>} props.availableTags A list of available tags.
 * @param {string} [props.selectedTag=''] The currently selected tag.
 * @param {function} A handler for when the selected tag changes.
 */
export function TagList({
  availableTags,
  selectedTag = '',
  onSelectTag,
  isMobile = false,
}) {
  return isMobile ? (
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
  ) : (
    <LargeScreenTagList
      availableTags={availableTags}
      selectedTag={selectedTag}
      onSelectTag={onSelectTag}
    />
  );
}

TagList.propTypes = {
  isMobile: PropTypes.boolean,
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedTag: PropTypes.string,
  onSelectTag: PropTypes.func.isRequired,
};
