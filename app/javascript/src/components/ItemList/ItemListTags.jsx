// Sidebar tags for item list page
import { h } from 'preact';
import { PropTypes } from 'preact-compat';

export const ItemListTags = ({ availableTags, selectedTags, onClick }) => {
  const tagsHTML = availableTags.map(tag => (
    <a
      className={`tag ${selectedTags.indexOf(tag) > -1 ? 'selected' : ''}`}
      href={`/t/${tag}`}
      data-no-instant
      onClick={e => onClick(e, tag)}
    >
      #{tag}
    </a>
  ));
  return <div className="tags">{tagsHTML}</div>;
};

ItemListTags.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  onClick: PropTypes.func.isRequired,
};
