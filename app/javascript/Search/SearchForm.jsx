import PropTypes from 'prop-types';
import { h } from 'preact';
import { forwardRef } from 'preact/compat';

export const SearchForm = forwardRef(
  ({ searchTerm, onSearch, onSubmitSearch }, ref) => (
    <form
      action="/search"
      acceptCharset="UTF-8"
      method="get"
      onSubmit={onSubmitSearch}
      role="search"
    >
      <input name="utf8" type="hidden" value="✓" />
      <div class="crayons-fields crayons-fields--horizontal">
        <div class="crayons-field flex-1">
          <input
            ref={ref}
            className="crayons-header--search-input crayons-textfield"
            type="text"
            name="q"
            placeholder="Search..."
            autoComplete="off"
            aria-label="search"
            onKeyDown={onSearch}
            value={searchTerm}
          />
        </div>
        <div class="crayons-field">
          <button type="submit" class="crayons-btn">
            Search
          </button>
        </div>
      </div>
    </form>
  ),
);

SearchForm.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  onSearch: PropTypes.func.isRequired,
  onSubmitSearch: PropTypes.func.isRequired,
};
