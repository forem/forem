// Sidebar tags for item list page
import { h } from 'preact';
import PropTypes from 'prop-types';

export const ItemListTags = ({ availableTags, selectedTags, onClick }) => {
  const tagsHTML = availableTags.map((tag) => (
    <a
      className={`crayons-link crayons-link--block ${
        selectedTags.indexOf(tag) > -1 ? 'crayons-link--current' : ''
      }`}
      href={`/t/${tag}`}
      data-no-instant
      onClick={(e) => onClick(e, tag)}
    >
      {`#${tag}`}
    </a>
  ));
  return (
    <nav className="crayons-layout__sidebar-left" data-testid="tags">
      {tagsHTML}
    </nav>
  );
};

ItemListTags.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  onClick: PropTypes.func.isRequired,
};
