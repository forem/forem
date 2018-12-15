import 'preact/devtools';
import PropTypes from 'prop-types';
import { h } from 'preact';

export const SearchForm = ({
  searchTerm,
  onSearch,
  onSubmitSearch,
  searchBoxId,
}) => (
  <div className="nav-search-form">
    <form
      action="/search"
      acceptCharset="UTF-8"
      method="get"
      onSubmit={onSubmitSearch}
    >
      <input name="utf8" type="hidden" value="✓" />
      <input
        className="nav-search-form__input"
        type="text"
        name="q"
        id={searchBoxId}
        placeholder="search"
        autoComplete="off"
        aria-label="search"
        onKeyDown={onSearch}
        value={searchTerm}
      />
    </form>
  </div>
);

SearchForm.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  searchBoxId: PropTypes.string.isRequired,
  onSearch: PropTypes.func.isRequired,
  onSubmitSearch: PropTypes.func.isRequired,
};
