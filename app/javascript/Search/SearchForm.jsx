import { h } from 'preact';
import { forwardRef, useState, useEffect, useRef, useMemo, useCallback } from 'preact/compat';
import PropTypes from 'prop-types';
import { locale } from '../utilities/locale';
import { ButtonNew as Button } from '@crayons';
import SearchIcon from '@images/search.svg';
import AlgoliaIcon from '@images/algolia.svg';
import { debounceAction } from '@utilities/debounceAction';

export const SearchForm = forwardRef(
  (
    { searchTerm, onSubmitSearch, branding, algoliaId, algoliaSearchKey },
    ref,
  ) => {
    const env = 'production';
    const [algoliaClient, setAlgoliaClient] = useState(null);
    const [recommendClient, setRecommendClient] = useState(null);
    const articleContainer = document.getElementById('article-show-container');

    const [inputValue, setInputValue] = useState(searchTerm);
    const [suggestions, setSuggestions] = useState([]);
    const [showSuggestions, setShowSuggestions] = useState(false);
    const [activeSuggestionIndex, setActiveSuggestionIndex] = useState(-1);
    const suggestionsRef = useRef();

    // Load Algolia and recommend dynamically
    const loadAlgoliaClients = useCallback(async () => {
      if (algoliaId && algoliaSearchKey && !algoliaClient) {
        try {
          const [algoliasearchModule, recommendModule] = await Promise.all([
            import('algoliasearch/lite'),
            import('@algolia/recommend'),
          ]);
    
          // Check whether to use .default or the direct import for algoliasearch
          const algoliasearch = algoliasearchModule.default || algoliasearchModule;
          const recommend = recommendModule.default || recommendModule;
    
          const client = algoliasearch(algoliaId, algoliaSearchKey);
          const recommendClientInstance = recommend(algoliaId, algoliaSearchKey);
    
          setAlgoliaClient(client);
          setRecommendClient(recommendClientInstance);
        } catch (error) {
          console.error("Error loading Algolia or Recommend modules: ", error);
        }
      }
    }, [algoliaId, algoliaSearchKey, algoliaClient]);

    const index = useMemo(() => (algoliaClient ? algoliaClient.initIndex(`Article_${env}`) : null), [algoliaClient]);

    // Handle clicks outside the dropdown
    const handleClickOutside = useCallback((event) => {
      if (
        suggestionsRef.current &&
        !suggestionsRef.current.contains(event.target) &&
        !ref.current.contains(event.target)
      ) {
        setShowSuggestions(false);
      }
    }, [ref]);

    useEffect(() => {
      document.addEventListener('mousedown', handleClickOutside);
      return () => {
        document.removeEventListener('mousedown', handleClickOutside);
      };
    }, [handleClickOutside]);

    // Fetch initial recommendations
    const fetchRecommendations = useCallback(() => {
      if (recommendClient && articleContainer?.dataset?.articleId) {
        recommendClient.getRelatedProducts([
          {
            indexName: `Article_${env}`,
            objectID: articleContainer?.dataset?.articleId,
            maxRecommendations: 5,
            threshold: 10,
          },
        ]).then(({ results }) => {
          setSuggestions(results[0].hits);
        });
      }
    }, [recommendClient]);

    // Debounced search function
    const debouncedSearch = useCallback(debounceAction((value) => {
      if (value && index) {
        index.search(value, { hitsPerPage: 5 }).then(({ hits }) => {
          setSuggestions(hits); // Assuming 'title' is the field to display
        });
      } else if (!articleContainer?.dataset?.articleId) {
        setSuggestions([]);
      }
    }, 200), [index]);

    useEffect(() => {
      debouncedSearch(inputValue);
    }, [inputValue, debouncedSearch]);

    // Handle input changes
    const handleInputChange = (e) => {
      setInputValue(e.target.value);
      setShowSuggestions(true);
      setActiveSuggestionIndex(-1);
      if (e.target.value.length === 0 && articleContainer) {
        fetchRecommendations();
      }
    };

    // Load Algolia clients on focus
    const handleFocus = () => {
      loadAlgoliaClients();
      const typeahead = document.getElementById('search-typeahead');
      if (typeahead) {
        typeahead.classList.remove('hidden');
      }
      setShowSuggestions(true);
      if (articleContainer) {
        fetchRecommendations();
      }
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
              placeholder={articleContainer?.dataset?.articleId ? 'Find related posts...' : `${locale('core.search')}...`}
              autoComplete="off"
              aria-label="Search term"
              value={inputValue}
              onChange={handleInputChange}
              onFocus={handleFocus}
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
                      { inputValue.length > 0 ? 'Submit search for advanced filtering.' : 'Displaying Algolia Recommendations — Start typing to search' }
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
