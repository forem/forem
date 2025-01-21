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

    // Dynamically load Algolia and recommend, return them so we can use them immediately.
    const loadAlgoliaClients = useCallback(async () => {
      // In case ID/Key are missing, bail out
      if (!algoliaId || !algoliaSearchKey) {
        return { client: null, recommendClientInstance: null };
      }

      try {
        // If we already have both clients in state, just return them
        if (algoliaClient && recommendClient) {
          return { client: algoliaClient, recommendClientInstance: recommendClient };
        }

        // Otherwise, dynamically import
        const [algoliasearchModule, recommendModule] = await Promise.all([
          import('algoliasearch/lite'),
          import('@algolia/recommend'),
        ]);

        const algoliasearch = algoliasearchModule.default || algoliasearchModule;
        const recommend = recommendModule.default || recommendModule;

        const client = algoliasearch(algoliaId, algoliaSearchKey);
        const recommendClientInstance = recommend(algoliaId, algoliaSearchKey);

        // Update state, but also return so we can use them right away
        setAlgoliaClient(client);
        setRecommendClient(recommendClientInstance);
        return { client, recommendClientInstance };
      } catch (error) {
        console.error('Error loading Algolia or Recommend modules: ', error);
        return { client: null, recommendClientInstance: null };
      }
    }, [algoliaId, algoliaSearchKey, algoliaClient, recommendClient]);

    // Memoize the index using algoliaClient from state
    const index = useMemo(() => {
      return algoliaClient ? algoliaClient.initIndex(`Article_${env}`) : null;
    }, [algoliaClient]);

    // Debounced search function
    const debouncedSearch = useCallback(debounceAction((value) => {
      if (value && index) {
        index.search(value, { hitsPerPage: 5, clickAnalytics: true }).then(({ hits, queryID }) => {
          setSuggestions(hits.map((hit) => ({ ...hit, queryID }))); // Attach queryID to each hit
        });
      } else if (!articleContainer?.dataset?.articleId) {
        setSuggestions([]);
      }
    }, 200), [index]);

    useEffect(() => {
      debouncedSearch(inputValue);
    }, [inputValue, debouncedSearch]);

    // Grab recommended products from the local reference, so we don't rely on the updated state
    const fetchRecommendations = useCallback((recommendClientInstance) => {
      if (!recommendClientInstance) return;
      const articleId = articleContainer?.dataset?.articleId;
      if (articleId) {
        recommendClientInstance
          .getRelatedProducts([
            {
              indexName: `Article_${env}`,
              objectID: articleId,
              maxRecommendations: 5,
              threshold: 10,
            },
          ])
          .then(({ results }) => {
            setSuggestions(results[0].hits);
          })
          .catch((err) => console.error(err));
      }
    }, [articleContainer]);

    // On focus, we ensure clients are loaded, then fetch recommendations using local references
    const handleFocus = useCallback(async () => {
      const { client, recommendClientInstance } = await loadAlgoliaClients();

      // Show the dropdown
      const typeahead = document.getElementById('search-typeahead');
      if (typeahead) {
        typeahead.classList.remove('hidden');
      }
      setShowSuggestions(true);

      // If no input value and there's an article ID, fetch recommendations
      if (inputValue.length === 0 && articleContainer) {
        fetchRecommendations(recommendClientInstance);
      }
    }, [articleContainer, inputValue, loadAlgoliaClients, fetchRecommendations]);

    // Handle input changes
    const handleInputChange = useCallback(
      (e) => {
        setInputValue(e.target.value);
        setShowSuggestions(true);
        setActiveSuggestionIndex(-1);

        // If user clears input, show recommendations if possible
        if (e.target.value.length === 0 && articleContainer) {
          // We might not have loaded clients yet, so load them
          loadAlgoliaClients().then(({ recommendClientInstance }) => {
            if (recommendClientInstance) {
              fetchRecommendations(recommendClientInstance);
            }
          });
        }
      },
      [articleContainer, fetchRecommendations, loadAlgoliaClients],
    );

    // Handle keyboard navigation and selection
    const handleKeyDown = (e) => {
      if (activeSuggestionIndex !== -1) {
        // Preload link on arrow movement for instant nav
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
        // “Select” that suggestion
        setInputValue(suggestions[activeSuggestionIndex].title);
        setShowSuggestions(false);
        setActiveSuggestionIndex(-1);
        InstantClick.display(suggestions[activeSuggestionIndex].path);
      }
    };

    const sendInsightEvent = async (eventType, eventName, objectID, indexName, queryID) => {
      try {
        const response = await fetch('/insights', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          },
          body: JSON.stringify({
            insight: {
              event_type: eventType,
              event_name: eventName,
              object_id: objectID,
              index_name: indexName,
              query_id: queryID,
            },
          }),
        });
    
        if (!response.ok) {
          console.error('Failed to track insight:', await response.json());
        }
      } catch (error) {
        console.error('Error sending tracking event:', error);
      }
    };

    // Close the dropdown if user clicks outside
    const handleClickOutside = useCallback(
      (event) => {
        if (
          suggestionsRef.current &&
          !suggestionsRef.current.contains(event.target) &&
          !ref.current.contains(event.target)
        ) {
          setShowSuggestions(false);
        }
      },
      [ref],
    );

    useEffect(() => {
      document.addEventListener('mousedown', handleClickOutside);
      return () => {
        document.removeEventListener('mousedown', handleClickOutside);
      };
    }, [handleClickOutside]);

    // On submit, run onSubmitSearch, then hide suggestions
    const handleSubmit = useCallback(
      (e) => {
        // e.preventDefault();
        onSubmitSearch(inputValue);
        setShowSuggestions(false);
      },
      [onSubmitSearch, inputValue],
    );

    return (
      <form
        action="/search"
        acceptCharset="UTF-8"
        method="get"
        onSubmit={handleSubmit}
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
              placeholder={
                articleContainer?.dataset?.articleId
                  ? 'Find related posts...'
                  : `${locale('core.search')}...`
              }
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
                  {suggestions.map((suggestion, idx) => (
                    <li
                      key={idx}
                      className={
                        idx === activeSuggestionIndex
                          ? 'crayons-header--search-typeahead-item-selected'
                          : ''
                      }
                    >
                      <a
                        href={suggestion.path}
                        onClick={(e) => {
                          // Send tracking event before navigating
                          e.preventDefault();
                          sendInsightEvent(
                            'click', // eventType
                            'Result Clicked', // eventName
                            suggestion.objectID, // objectID
                            `Article_${env}`, // indexName
                            suggestion.queryID // queryID from Algolia response
                          ).finally(() => {
                            // Navigate after tracking is sent
                            window.location.href = suggestion.path;
                          });
                        }}
                      >
                        <div className="crayons-header--search-typeahead-item-preheader">
                          @{suggestion.user.username}
                        </div>
                        <strong>{suggestion.title}</strong>
                        <div className="crayons-header--search-typeahead-item-subheader">
                          {suggestion.readable_publish_date}
                        </div>
                      </a>
                    </li>
                  ))}
                  <div className="crayons-header--search-typeahead-footer">
                    <span>
                      {inputValue.length > 0
                        ? 'Submit search for advanced filtering.'
                        : 'Displaying Algolia Recommendations — Start typing to search'}
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
  branding: PropTypes.string,
  algoliaId: PropTypes.string,
  algoliaSearchKey: PropTypes.string,
};
