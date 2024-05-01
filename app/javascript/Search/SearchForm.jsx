import PropTypes from 'prop-types';
import { h } from 'preact';
import { forwardRef } from 'preact/compat';
import { locale } from '../utilities/locale';
import { ButtonNew as Button } from '@crayons';
import SearchIcon from '@images/search.svg';
import AlgoliaIcon from '@images/algolia.svg'

export const SearchForm = forwardRef(({ searchTerm, onSubmitSearch, branding }, ref) => (
  <form
    action="/search"
    acceptCharset="UTF-8"
    method="get"
    onSubmit={onSubmitSearch}
    role="search"
  >
    <input name="utf8" type="hidden" value="✓" />
    <div class="crayons-fields crayons-fields--horizontal">
      <div class="crayons-field flex-1 relative">
        <input
          ref={ref}
          className="crayons-header--search-input crayons-textfield"
          type="text"
          name="q"
          placeholder={`${locale(branding === 'algolia' ? 'core.algolia_search' : 'core.search')}...`}
          autoComplete="off"
          aria-label="Search term"
          value={searchTerm}
        />
        <Button
          type="submit"
          icon={branding === 'algolia' ? AlgoliaIcon : SearchIcon}
          className="absolute inset-px left-auto mt-0 py-0"
          aria-label="Search"
        />
      </div>
    </div>
  </form>
));

SearchForm.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  onSubmitSearch: PropTypes.func.isRequired,
};
