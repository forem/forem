import { h, Component } from 'preact';
import PropTypes from 'prop-types';

const KEYS = {
  UP: 'ArrowUp',
  DOWN: 'ArrowDown',
  LEFT: 'ArrowLeft',
  RIGHT: 'ArrowRight',
  TAB: 'Tab',
  RETURN: 'Enter',
  COMMA: ',',
  DELETE: 'Backspace',
};

const NAVIGATION_KEYS = [
  KEYS.COMMA,
  KEYS.DELETE,
  KEYS.LEFT,
  KEYS.RIGHT,
  KEYS.TAB,
];

const LETTERS = /[a-z]/i;

/* TODO: Remove all instances of this.props.listing
   and refactor this component to be more generic */

class Tags extends Component {
  static propTypes = {
    defaultValue: PropTypes.string.isRequired,
    onInput: PropTypes.func.isRequired,
    maxTags: PropTypes.number.isRequired,
    classPrefix: PropTypes.string.isRequired,
    listing: PropTypes.bool,
    category: PropTypes.string,
    autoComplete: PropTypes.string,
  };

  static defaultProps = {
    listing: false,
    category: '',
    autoComplete: 'on',
  };

  constructor(props) {
    super(props);

    this.state = {
      selectedIndex: -1,
      searchResults: [],
      additionalTags: [],
      cursorIdx: 0,
      prevLen: 0,
      showingRulesForTag: null,
    };

    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
      .content;
    const algoliaKey = document.querySelector("meta[name='algolia-public-key']")
      .content;
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey);
    this.index = client.initIndex(`Tag_${env}`);
  }

  componentDidMount() {
    const { listing } = this.props;
    if (listing === true) {
      this.setState({
        additionalTags: {
          jobs: [
            'remote',
            'remoteoptional',
            'lgbtbenefits',
            'greencard',
            'senior',
            'junior',
            'intermediate',
            '401k',
            'fulltime',
            'contract',
            'temp',
          ],
          forhire: [
            'remote',
            'remoteoptional',
            'lgbtbenefits',
            'greencard',
            'senior',
            'junior',
            'intermediate',
            '401k',
            'fulltime',
            'contract',
            'temp',
          ],
          forsale: ['laptop', 'desktopcomputer', 'new', 'used'],
          events: ['conference', 'meetup'],
          collabs: ['paid', 'temp'],
        },
      });
    }
  }

  componentDidUpdate() {
    const { cursorIdx, prevLen } = this.state;
    const { value } = this.textArea;
    // stop cursor jumping if the user goes back to edit previous tags
    if (cursorIdx < value.length && value.length < prevLen + 1) {
      this.textArea.selectionStart = cursorIdx;
      this.textArea.selectionEnd = cursorIdx;
    }
  }

  getCurrentTagAtSelectionIndex = (value, index) => {
    let tagIndex = 0;
    const tagByCharacterIndex = {};

    value.split('').map((letter, valueIndex) => {
      if (letter === ',') {
        tagIndex += 1;
      } else {
        tagByCharacterIndex[valueIndex] = tagIndex;
      }
    });

    const tag = value.split(',')[tagByCharacterIndex[index]];

    if (tag === undefined) {
      return '';
    }
    return tag.trim();
  };

  get selected() {
    const { defaultValue } = this.props;
    return defaultValue
      .split(',')
      .map(item => item !== undefined && item.trim())
      .filter(item => item.length > 0);
  }

  get isTopOfSearchResults() {
    const { selectedIndex } = this.state;
    return selectedIndex <= 0;
  }

  get isBottomOfSearchResults() {
    const { selectedIndex, searchResults } = this.state;
    return selectedIndex >= searchResults.length - 1;
  }

  get isSearchResultSelected() {
    const { selectedIndex } = this.state;
    return selectedIndex > -1;
  }

  handleRulesClick = e => {
    e.preventDefault();
    if (this.state.showingRulesForTag === e.target.dataset.content) {
      this.setState({showingRulesForTag: null});
    } else {
      this.setState({showingRulesForTag: e.target.dataset.content});
    }
  }

  handleTagClick = e => {
    if (e.target.className === 'articleform__tagsoptionrulesbutton') {
      return;
    }
    const input = document.getElementById('tag-input');
    input.focus();
    this.insertTag(e.target.dataset.content);
  };

  handleInput = e => {
    let { value } = e.target;
    // If we start typing immediately after a comma, add a space
    // before what we typed.
    // e.g. If value = "javascript," and we type a "p",
    // the result should be "javascript, p".
    if (e.inputType === 'insertText') {
      const isTypingAfterComma =
        e.target.value[e.target.selectionStart - 2] === ',';
      if (isTypingAfterComma) {
        value = this.insertSpace(value, e.target.selectionStart - 1);
      }
    }

    if (e.data === ',') {
      value += ' ';
    }

    const { onInput } = this.props;
    onInput(value);

    const query = this.getCurrentTagAtSelectionIndex(
      e.target.value,
      e.target.selectionStart - 1,
    );

    this.setState({
      selectedIndex: 0,
      cursorIdx: e.target.selectionStart,
      prevLen: this.textArea.value.length,
    });
    return this.search(query);
  };

  handleKeyDown = e => {
    const component = this;
    const { maxTags } = this.props;
    if (component.selected.length === maxTags && e.keyCode === KEYS.COMMA) {
      e.preventDefault();
      return;
    }

    if (
      (e.key === KEYS.DOWN || e.key === KEYS.TAB) &&
      !this.isBottomOfSearchResults &&
      component.props.defaultValue !== ''
    ) {
      e.preventDefault();
      this.moveDownInSearchResults();
    } else if (e.key === KEYS.UP && !this.isTopOfSearchResults) {
      e.preventDefault();
      this.moveUpInSearchResults();
    } else if (e.key === KEYS.RETURN && this.isSearchResultSelected) {
      e.preventDefault();
      this.insertTag(
        component.state.searchResults[component.state.selectedIndex].name,
      );

      setTimeout(() => {
        document.getElementById('tag-input').focus();
      }, 10);
    } else if (e.key === KEYS.COMMA && !this.isSearchResultSelected) {
      this.resetSearchResults();
      this.clearSelectedSearchResult();
    } else if (e.key === KEYS.DELETE) {
      if (
        component.props.defaultValue[
          component.props.defaultValue.length - 1
        ] === ','
      ) {
        this.clearSelectedSearchResult();
      }
    } else if (
      (e.keyCode < 65 || e.keyCode > 90) &&
      e.keyCode !== KEYS.COMMA &&
      e.keyCode !== KEYS.DELETE &&
      e.keyCode !== KEYS.LEFT &&
      e.keyCode !== KEYS.RIGHT &&
      e.keyCode !== KEYS.TAB
    ) {
      e.preventDefault();
    }
  };

  // Given an index of the String value, finds the range between commas.
  // This is useful when we want to insert a new tag anywhere in the
  // comma separated list of tags.
  getRangeBetweenCommas = (value, index) => {
    let start = 0;
    let end = value.length;

    const toPreviousComma = value
      .slice(0, index)
      .split('')
      .reverse()
      .indexOf(',');
    const toNextComma = value.slice(index).indexOf(',');

    if (toPreviousComma !== -1) {
      start = index - toPreviousComma + 1;
    }

    if (toNextComma !== -1) {
      end = index + toNextComma;
    }

    return [start, end];
  };

  handleFocusChange = () => {
    const component = this;
    setTimeout(() => {
      if (document.activeElement.id === 'tag-input') {
        return;
      }
      component.forceUpdate();
    }, 100);
  };

  insertSpace = (value, position) => {
    return `${value.slice(0, position)} ${value.slice(position, value.length)}`;
  };

  clearSelectedSearchResult() {
    this.setState({
      selectedIndex: -1,
    });
  }

  insertTag(tag) {
    const { maxTags, onInput } = this.props;
    const input = document.getElementById('tag-input');

    const range = this.getRangeBetweenCommas(input.value, input.selectionStart);
    const insertingAtEnd = range[1] === input.value.length;
    const maxTagsWillBeReached = this.selected.length === maxTags;
    let tagValue = '';
    if (insertingAtEnd && !maxTagsWillBeReached) {
      tagValue = `${tag}, `;
    }

    // Insert new tag between commas if there are any.
    const newInput =
      input.value.slice(0, range[0]) +
      tagValue +
      input.value.slice(range[1], input.value.length);

    onInput(newInput);
    this.resetSearchResults();
    this.clearSelectedSearchResult();
  }

  moveDownInSearchResults() {
    const { selectedIndex } = this.state;
    this.setState({
      selectedIndex: selectedIndex + 1,
    });
  }

  moveUpInSearchResults() {
    const { selectedIndex } = this.state;
    this.setState({
      selectedIndex: selectedIndex - 1,
    });
  }

  resetSearchResults() {
    this.setState({
      searchResults: [],
    });
  }

  search(query) {
    const { listing = false } = this.props;

    if (query === '') {
      return new Promise(resolve => {
        setTimeout(() => {
          this.resetSearchResults();
          resolve();
        }, 5);
      });
    }

    return this.index
      .search(query, {
        hitsPerPage: 10,
        attributesToHighlight: [],
        filters: 'supported:true',
      })
      .then(content => {
        if (listing === true) {
          const { additionalTags } = this.state;
          const { category } = this.props;
          const additionalItems = (additionalTags[category] || []).filter(
            t => t.indexOf(query) > -1,
          );
          const resultsArray = content.hits;
          additionalItems.forEach(t => {
            if (resultsArray.indexOf(t) === -1) {
              resultsArray.push({ name: t });
            }
          });
        }
        this.setState({
          searchResults: content.hits.filter(
            hit => !this.selected.includes(hit.name),
          ),
        });
      });
  }

  render() {
    const { searchResults, selectedIndex } = this.state;
    const {
      classPrefix,
      listing,
      maxTags,
      autoComplete,
      defaultValue,
    } = this.props;
    let searchResultsHTML = '';
    const searchResultsRows = searchResults.map((tag, index) => (
      <div
        tabIndex="-1"
        className={`${classPrefix}__tagoptionrow ${classPrefix}__tagoptionrow--${
          selectedIndex === index ? 'active' : 'inactive'
        }`}
        onClick={this.handleTagClick}
        data-content={tag.name}
        role="button"
      >
        {tag.name}
      </div>
    ));
    if (searchResults.length > 0 && document.activeElement.id === 'tag-input') {
      searchResultsHTML = (
        <div className={`${classPrefix}__tagsoptions`}>{searchResultsRows}</div>
      );
    }

    return (
      <div className={`${classPrefix}__tagswrapper`}>
        {listing && <label htmlFor="Tags">Tags</label>}
        <input
          id="tag-input"
          type="text"
          ref={t => (this.textArea = t)}
          className={`${classPrefix}__tags`}
          placeholder={`${maxTags} tags max, comma separated, no spaces or special characters`}
          autoComplete={autoComplete || 'on'}
          value={defaultValue}
          onInput={this.handleInput}
          onKeyDown={this.handleKeyDown}
          onBlur={this.handleFocusChange}
          onFocus={this.handleFocusChange}
        />
        {searchResultsHTML}
      </div>
    );
  }
}

export default Tags;
