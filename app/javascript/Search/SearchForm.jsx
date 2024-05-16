import { h } from 'preact';
import { forwardRef, useState, useEffect, useRef } from 'preact/compat';
import PropTypes from 'prop-types';
import algoliasearch from 'algoliasearch/lite';
import { locale } from '../utilities/locale';
import { ButtonNew as Button } from '@crayons';
import SearchIcon from '@images/search.svg';
import AlgoliaIcon from '@images/algolia.svg';

export const SearchForm = forwardRef(
  (
    { searchTerm, onSubmitSearch, branding, algoliaId, algoliaSearchKey },
    ref,
  ) => {
    const env = 'production';
    const client = algoliaId
      ? algoliasearch(algoliaId, algoliaSearchKey)
      : null;
    const index = client ? client.initIndex(`Article_${env}`) : null;
    const [inputValue, setInputValue] = useState(searchTerm);
    const [suggestions, setSuggestions] = useState([]);
    const [showSuggestions, setShowSuggestions] = useState(false);
    const [activeSuggestionIndex, setActiveSuggestionIndex] = useState(-1);
    const suggestionsRef = useRef();

    // Fetch suggestions from Algolia if client is initialized
    useEffect(() => {
      if (inputValue && index) {
        index.search(inputValue, { hitsPerPage: 5 }).then(({ hits }) => {
          setSuggestions(hits); // Assuming 'title' is the field to display
        });
      } else {
        setSuggestions([]);
      }
    }, [inputValue, index]);

    // Handle input changes
    const handleInputChange = (e) => {
      setInputValue(e.target.value);
      setShowSuggestions(true);
      setActiveSuggestionIndex(-1);
    };

    // Handle keyboard navigation and selection
    const handleKeyDown = (e) => {
      if (activeSuggestionIndex !== -1) {
        InstantClick.preload(suggestions[activeSuggestionIndex].path);
      }
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        const nextIndex =
          activeSuggestionIndex < suggestions.length - 1
            ? activeSuggestionIndex + 1
            : -1;
        setActiveSuggestionIndex(nextIndex);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        const prevIndex =
          activeSuggestionIndex > -1
            ? activeSuggestionIndex - 1
            : suggestions.length - 1;
        setActiveSuggestionIndex(prevIndex);
      } else if (e.key === 'Enter' && activeSuggestionIndex !== -1) {
        e.preventDefault();
        setInputValue(suggestions[activeSuggestionIndex].title);
        setShowSuggestions(false);
        setActiveSuggestionIndex(-1);
        InstantClick.display(suggestions[activeSuggestionIndex].path);
      }
    };

    // Handle clicks outside the dropdown
    const handleClickOutside = (event) => {
      if (
        suggestionsRef.current &&
        !suggestionsRef.current.contains(event.target) &&
        !ref.current.contains(event.target)
      ) {
        setShowSuggestions(false);
      }
    };

    useEffect(() => {
      document.addEventListener('mousedown', handleClickOutside);
      return () => {
        document.removeEventListener('mousedown', handleClickOutside);
      };
    }, []);

    return (
      <form
        action="/search"
        acceptCharset="UTF-8"
        method="get"
        onSubmit={() => {
          onSubmitSearch(inputValue);
          setShowSuggestions(false);
        }}
        role="search"
      >
        <input name="utf8" type="hidden" value="✓" />
        <div class="crayons-fields crayons-fields--horizontal">
          <div class="crayons-field flex-1 relative">
            <input
              id="search-input"
              ref={ref}
              className="crayons-header--search-input crayons-textfield"
              type="text"
              name="q"
              placeholder={`${locale('core.search')}...`}
              autoComplete="off"
              aria-label="Search term"
              value={inputValue}
              onChange={handleInputChange}
              onFocus={() => {
                document
                  .getElementById('search-typeahead')
                  .classList.remove('hidden');
                setShowSuggestions(true);
              }}
              onKeyDown={handleKeyDown}
            />
            {showSuggestions &&
              algoliaId &&
              algoliaId.length > 0 &&
              suggestions.length > 0 && (
                <ul
                  id="search-typeahead"
                  className="crayons-header--search-typeahead"
                  ref={suggestionsRef}
                >
                  {suggestions.map((suggestion, index) => (
                    // eslint-disable-next-line jsx-a11y/no-noninteractive-element-interactions
                    <li
                      key={index}
                      className={
                        index === activeSuggestionIndex
                          ? 'crayons-header--search-typeahead-item-selected'
                          : ''
                      }
                    >
                      <a href={suggestion.path}>
                        <div class="crayons-header--search-typeahead-item-preheader">
                          @{suggestion.user.username}
                        </div>
                        <strong>{suggestion.title}</strong>
                        <div class="crayons-header--search-typeahead-item-subheader">
                          {suggestion.readable_publish_date}
                        </div>
                      </a>
                    </li>
                  ))}
                  <div class="crayons-header--search-typeahead-footer">
                    <span>
                      Displaying Posts — Submit search to filter by Users,
                      Comments, etc.
                    </span>
                    <a
                      href="https://www.algolia.com/developers/?utm_source=devto&utm_medium=referral"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Powered by Algolia
                    </a>
                  </div>
                </ul>
              )}
            <Button
              type="submit"
              icon={SearchIcon}
              className="absolute inset-px right-auto mt-0 py-0"
              aria-label="Search"
            />
            {branding === 'algolia' ? (
              <a
                class="crayons-header--search-brand-indicator"
                href="https://www.algolia.com/developers/?utm_source=devto&utm_medium=referral"
                target="_blank"
                rel="noopener noreferrer"
              >
                Powered by <AlgoliaIcon /> Algolia
              </a>
            ) : (
              ''
            )}
          </div>
        </div>
      </form>
    );
  },
);

SearchForm.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  onSubmitSearch: PropTypes.func.isRequired,
};
