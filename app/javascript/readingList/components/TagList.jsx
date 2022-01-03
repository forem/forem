import { h } from 'preact';
import PropTypes from 'prop-types';

function LargeScreenTagList({ availableTags, selectedTag, onSelectTag }) {
  return (
    <nav aria-label="Filter by tag">
      <ul className="list-none">
        <li>
          <a
            className={`crayons-link crayons-link--block${
              !selectedTag ? ' crayons-link--current' : ''
            }`}
            data-no-instant
            onClick={onSelectTag}
            href="/t"
          >
            All tags
          </a>
        </li>
        {availableTags.map((tag) => (
          <li key={tag}>
            <a
              className={`crayons-link crayons-link--block${
                selectedTag === tag ? ' crayons-link--current' : ''
              }`}
              data-no-instant
              data-tag={tag}
              onClick={onSelectTag}
              href={`t/${tag}`}
            >
              #{tag}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}

/**
 *
 * @param {object} props
 * @param {Array<string>} props.availableTags A list of available tags.
 * @param {string} [props.selectedTag=''] The currently selected tag.
 * @param {function} props.onSelectTag A handler for when the selected tag changes.
 * @param {boolean} [props.isMobile=false] Whether or not we're displaying the mobile view.
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
      onChange={onSelectTag}
    >
      <option>all tags</option>
      {availableTags.map((tag) => (
        <option
          selected={tag === selectedTag}
          key={tag}
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
