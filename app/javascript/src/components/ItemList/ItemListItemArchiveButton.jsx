// Archive / unarchive button for item list

// NOTE: although this element should clearly be a button and not an anchor,
// I think I've stumbled on a (p)React bug similar to this:
// <https://github.com/facebook/react/issues/9023>
// where if I transform it in a button, `e.preventDefault()` in the parent
// handler or `e.stopPropagation` are just ignored
import { h } from 'preact';
import { PropTypes } from 'preact-compat';

export const ItemListItemArchiveButton = ({ text, onClick }) => {
  const onKeyUp = e => {
    if (e.key === 'Enter') {
      onClick(e);
    }
  };

  return (
    // eslint-disable-next-line jsx-a11y/anchor-is-valid
    <a
      className="archive-button"
      onClick={onClick}
      onKeyUp={onKeyUp}
      tabIndex="0"
      aria-label="archive item"
      role="button"
    >
      {text}
    </a>
  );
};

ItemListItemArchiveButton.propTypes = {
  text: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
};
