import 'preact/devtools';
import PropTypes from 'prop-types';
import { h } from 'preact';

export const SearchForm = ({
  searchTerm,
  onSearch,
  onSubmitSearch,
  searchBoxSelector,
}) => (
  <form
    action="/search"
    acceptCharset="UTF-8"
    method="get"
    onSubmit={onSubmitSearch}
  >
    <input name="utf8" type="hidden" value="✓" />
    <input
      className={`crayons-textfield ${searchBoxSelector}`}
      type="text"
      name="q"
      placeholder="Search..."
      autoComplete="off"
      aria-label="search"
      onKeyDown={onSearch}
      value={searchTerm}
    />
  </form>
);

SearchForm.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  searchBoxSelector: PropTypes.string.isRequired,
  onSearch: PropTypes.func.isRequired,
  onSubmitSearch: PropTypes.func.isRequired,
};
