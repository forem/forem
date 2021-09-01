import { h } from 'preact';
import PropTypes from 'prop-types';

function LargeScreenTagList({ availableTags, selectedTag, onSelectTag }) {
  return (
    <nav aria-label="Filter by tag">
      <ul className="list-none grid grid-cols-1 gap-2">
        <li>
          <a
            className={`crayons-link crayons-link--block${
              !selectedTag ? ' crayons-link--current' : ''
            }`}
            data-no-instant
            onClick={onSelectTag}
            href="/t"
          >
            all tags
          </a>
        </li>
        {availableTags.map((tag) => (
          <li>
            <a
              className={`crayons-link crayons-link--block${
                selectedTag === tag ? ' crayons-link--current' : ''
              }`}
              data-no-instant
              data-tag={tag}
              onClick={onSelectTag}
              key={tag}
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
