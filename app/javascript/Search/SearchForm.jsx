import { h } from 'preact';
import { forwardRef, useState, useEffect, useRef } from 'preact/compat';
import PropTypes from 'prop-types';
import { locale } from '../utilities/locale';
import { ButtonNew as Button } from '@crayons';
import SearchIcon from '@images/search.svg';
import AlgoliaIcon from '@images/algolia.svg';
import algoliasearch from 'algoliasearch/lite';


export const SearchForm = forwardRef(({ searchTerm, onSubmitSearch, branding }, ref) => {
  const {algoliaId, algoliaSearchKey} = document.body.dataset;
  const client = algoliasearch(algoliaId, algoliaSearchKey);
  const index = client.initIndex('Article_production');
  const [inputValue, setInputValue] = useState(searchTerm);
  const [suggestions, setSuggestions] = useState([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [activeSuggestionIndex, setActiveSuggestionIndex] = useState(-1);
  const suggestionsRef = useRef();

  // Fetch suggestions from Algolia
  useEffect(() => {
    if (inputValue) {
      index.search(inputValue, { hitsPerPage: 5 }).then(({ hits }) => {
        console.log(hits)
        setSuggestions(hits);  // Assuming 'title' is the field to display
      });
    } else {
      setSuggestions([]);
    }
  }, [inputValue]);

  // Handle input changes
  const handleInputChange = (e) => {
    setInputValue(e.target.value);
    setShowSuggestions(true);
    setActiveSuggestionIndex(-1);
  };

  // Handle keyboard navigation and selection
  const handleKeyDown = (e) => {
    if (activeSuggestionIndex !== -1) {
      InstantClick.preload('/doyle_abe/an-instant-in-the-wind-voluptates-qui-5e5m');
      // InstantClick.preload(suggestions[activeSuggestionIndex].path);
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      const nextIndex = activeSuggestionIndex < suggestions.length - 1 ? activeSuggestionIndex + 1 : -1;
      setActiveSuggestionIndex(nextIndex);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      const prevIndex = activeSuggestionIndex > -1 ? activeSuggestionIndex - 1 : suggestions.length - 1;
      setActiveSuggestionIndex(prevIndex);
    } else if (e.key === 'Enter' && activeSuggestionIndex !== -1) {
      e.preventDefault();
      setInputValue(suggestions[activeSuggestionIndex].title);
      setShowSuggestions(false);
      setActiveSuggestionIndex(-1);
      InstantClick.display('/doyle_abe/an-instant-in-the-wind-voluptates-qui-5e5m');
      // InstantClick.preload(suggestions[activeSuggestionIndex].path);
      // InstantClick.display(suggestions[activeSuggestionIndex].path);
    }
  };

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
            placeholder={`${locale(branding === 'algolia' ? 'core.algolia_search' : 'core.search')}...`}
            autoComplete="off"
            aria-label="Search term"
            value={inputValue}
            onChange={handleInputChange}
            onFocus={() => {
              document.getElementById('search-typeahead').classList.remove('hidden');
              setShowSuggestions(true)}
            }
            onKeyDown={handleKeyDown}
          />
          {(showSuggestions && suggestions.length > 0) && (
            <ul id="search-typeahead" className="crayons-header--search-typeahead" ref={suggestionsRef}>
              {suggestions.map((suggestion, index) => (
                <li
                  key={index}
                  className={index === activeSuggestionIndex ? 'crayons-header--search-typeahead-item-selected' : ''}
                  onMouseDown={() => handleSuggestionClick(suggestion)}
                >
                  <a href={suggestion.path}>
                    <div class='crayons-header--search-typeahead-item-preheader'>
                      @{suggestion.user.username }
                    </div>
                    <strong>{suggestion.title}</strong>
                    <div class='crayons-header--search-typeahead-item-subheader'>
                      {suggestion.readable_publish_date}
                    </div>
                  </a>
                </li>
              ))}
              <div class="crayons-header--search-typeahead-footer">
                Powered by Algolia
              </div>
            </ul>
          )}
          <Button
            type="submit"
            icon={branding === 'algolia' ? AlgoliaIcon : SearchIcon}
            className="absolute inset-px left-auto mt-0 py-0"
            aria-label="Search"
          />
        </div>
      </div>
    </form>
  );
});

SearchForm.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  onSubmitSearch: PropTypes.func.isRequired,
};
