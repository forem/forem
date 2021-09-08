import PropTypes from 'prop-types';
import { h } from 'preact';
import { forwardRef } from 'preact/compat';
import { locale } from '../utilities/locale';
import { Button } from '@crayons';


const SearchIcon = () => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="M18.031 16.617l4.283 4.282-1.415 1.415-4.282-4.283A8.96 8.96 0 0111 20c-4.968 0-9-4.032-9-9s4.032-9 9-9 9 4.032 9 9a8.96 8.96 0 01-1.969 5.617zm-2.006-.742A6.977 6.977 0 0018 11c0-3.868-3.133-7-7-7-3.868 0-7 3.132-7 7 0 3.867 3.132 7 7 7a6.977 6.977 0 004.875-1.975l.15-.15z" />
  </svg>
);

export const SearchForm = forwardRef(({ searchTerm, onSubmitSearch }, ref) => (
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
          placeholder={`${locale('core.search')}...`}
          autoComplete="off"
          aria-label="Search term"
          value={searchTerm}
        />
        <Button
          type="submit"
          variant="ghost"
          contentType="icon-rounded"
          icon={SearchIcon}
          size="s"
          className="absolute right-2 bottom-0 top-0 m-1"
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
