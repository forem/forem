import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { fetchSearch } from '../../utilities/search';

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

const LETTERS_NUMBERS = /[a-z0-9]/i;

/* TODO: Remove all instances of this.props.listing
   and refactor this component to be more generic */

class Tags extends Component {
  constructor(props) {
    super(props);
    const { listing } = props;

    const listingState = listing
      ? {
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
        }
      : null;

    this.state = {
      selectedIndex: -1,
      searchResults: [],
      additionalTags: [],
      cursorIdx: 0,
      prevLen: 0,
      showingRulesForTag: null,
      ...listingState,
    };
  }

  componentDidUpdate() {
    // stop cursor jumping if the user goes back to edit previous tags
    const { cursorIdx, prevLen } = this.state;
    if (
      cursorIdx < this.textArea.value.length &&
      this.textArea.value.length < prevLen + 1
    ) {
      this.textArea.selectionEnd = cursorIdx;
      this.textArea.selectionStart = this.textArea.selectionEnd;
    }
  }

  get selected() {
    const { defaultValue } = this.props;
    return defaultValue
      .split(',')
      .map((item) => item !== undefined && item.trim())
      .filter((item) => item.length > 0);
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

  getCurrentTagAtSelectionIndex = (value, index) => {
    let tagIndex = 0;
    const tagByCharacterIndex = {};

    value.split('').forEach((letter, letterIndex) => {
      if (letter === ',') {
        tagIndex += 1;
      } else {
        tagByCharacterIndex[letterIndex] = tagIndex;
      }
    });

    const tag = value.split(',')[tagByCharacterIndex[index]];

    if (tag === undefined) {
      return '';
    }
    return tag.trim();
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

  handleKeyDown = (e) => {
    const component = this;
    const { maxTags } = this.props;
    if (component.selected.length === maxTags && e.key === KEYS.COMMA) {
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
      !LETTERS_NUMBERS.test(e.key) &&
      !NAVIGATION_KEYS.includes(e.key)
    ) {
      e.preventDefault();
    }
  };

  handleRulesClick = (e) => {
    e.preventDefault();
    const { showingRulesForTag } = this.state;
    if (showingRulesForTag === e.target.dataset.content) {
      this.setState({ showingRulesForTag: null });
    } else {
      this.setState({ showingRulesForTag: e.target.dataset.content });
    }
  };

  handleTagClick = (e) => {
    if (e.target.className === 'articleform__tagsoptionrulesbutton') {
      return;
    }

    const input = document.getElementById('tag-input');
    input.focus();

    // the rules container (__tagoptionrow) is the real target of the event,
    // by using currentTarget we let the event propagation work
    // from the inner rules box as well (__tagrules)
    this.insertTag(e.currentTarget.dataset.content);
  };

  handleInput = (e) => {
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

    /* eslint-disable-next-line react/destructuring-assignment */
    this.props.onInput(value);

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

  handleFocusChange = () => {
    const component = this;
    setTimeout(() => {
      if (document.activeElement.id === 'tag-input') {
        return;
      }
      component.forceUpdate();
    }, 250);
  };

  insertSpace = (value, position) => {
    return `${value.slice(0, position)} ${value.slice(position, value.length)}`;
  };

  handleTagEnter = (e) => {
    if (e.key === KEYS.RETURN) {
      this.handleTagClick();
    }
  };

  insertTag(tag) {
    const input = document.getElementById('tag-input');
    const { maxTags } = this.props;
    const range = this.getRangeBetweenCommas(input.value, input.selectionStart);
    const insertingAtEnd = range[1] === input.value.length;
    const maxTagsWillBeReached = this.selected.length === maxTags;
    let tagValue = tag;
    if (insertingAtEnd && !maxTagsWillBeReached) {
      tagValue = `${tagValue}, `;
    }

    // Insert new tag between commas if there are any.
    const newInput =
      input.value.slice(0, range[0]) +
      tagValue +
      input.value.slice(range[1], input.value.length);
    /* eslint-disable-next-line react/destructuring-assignment */
    this.props.onInput(newInput);
    this.resetSearchResults();
    this.clearSelectedSearchResult();
  }

  search(query) {
    if (query === '') {
      return new Promise((resolve) => {
        setTimeout(() => {
          this.resetSearchResults();
          resolve();
        }, 5);
      });
    }
    const { listing } = this.props;

    const dataHash = { name: query };
    const responsePromise = fetchSearch('tags', dataHash);

    return responsePromise.then((response) => {
      if (listing === true) {
        const { additionalTags } = this.state;
        const { category } = this.props;
        const additionalItems = (additionalTags[category] || []).filter((t) =>
          t.includes(query),
        );
        const resultsArray = response.result;
        additionalItems.forEach((t) => {
          if (!resultsArray.includes(t)) {
            resultsArray.push({ name: t });
          }
        });
      }
      // updates searchResults array according to what is being typed by user
      // allows user to choose a tag when they've typed the partial or whole word
      this.setState({
        searchResults: response.result.filter((t) => !this.selected.includes(t.name)),
      });
    });
  }

  resetSearchResults() {
    this.setState({
      searchResults: [],
    });
  }

  moveUpInSearchResults() {
    this.setState((prevState) => ({
      selectedIndex: prevState.selectedIndex - 1,
    }));
  }

  moveDownInSearchResults() {
    this.setState((prevState) => ({
      selectedIndex: prevState.selectedIndex + 1,
    }));
  }

  clearSelectedSearchResult() {
    this.setState({
      selectedIndex: -1,
    });
  }

  render() {
    let searchResultsHTML = '';
    const { searchResults, selectedIndex, showingRulesForTag } = this.state;
    const {
      classPrefix,
      defaultValue,
      maxTags,
      listing,
      fieldClassName,
      onFocus,
      pattern,
    } = this.props;
    const { activeElement } = document;
    const searchResultsRows = searchResults.map((tag, index) => (
      <div
        tabIndex="-1"
        role="button"
        className={`${classPrefix}__tagoptionrow ${classPrefix}__tagoptionrow--${
          selectedIndex === index ? 'active' : 'inactive'
        }`}
        onClick={this.handleTagClick}
        onKeyDown={this.handleTagEnter}
        data-content={tag.name}
      >
        <span className={`${classPrefix}__tagname`}>{tag.name}</span>
        {tag.rules_html && tag.rules_html.length > 0 ? (
          <button
            type="button"
            className={`${classPrefix}__tagsoptionrulesbutton`}
            onClick={this.handleRulesClick}
            data-content={tag.name}
          >
            {showingRulesForTag === tag.name ? 'Hide Rules' : 'View Rules'}
          </button>
        ) : (
          ''
        )}
        <div
          className={`${classPrefix}__tagrules--${
            showingRulesForTag === tag.name ? 'active' : 'inactive'
          }`}
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{ __html: tag.rules_html }}
        />
      </div>
    ));
    if (
      searchResults.length > 0 &&
      (activeElement.id === 'tag-input' ||
        activeElement.classList.contains(
          'articleform__tagsoptionrulesbutton',
        ) ||
        activeElement.classList.contains('articleform__tagoptionrow'))
    ) {
      searchResultsHTML = (
        <div className={`${classPrefix}__tagsoptions`}>
          {searchResultsRows}
          <div className={`${classPrefix}__tagsoptionsbottomrow`}>
            Some tags have rules and guidelines determined by community
            moderators
          </div>
        </div>
      );
    }

    return (
      <div className={`${classPrefix}__tagswrapper crayons-field`}>
        {listing && (
          <label htmlFor="Tags" class="crayons-field__label">
            Tags
          </label>
        )}
        <input
          data-testid="tag-input"
          aria-label="Post Tags"
          id="tag-input"
          type="text"
          ref={(t) => {
            this.textArea = t;
            return this.textArea;
          }}
          className={`${`${fieldClassName} ${classPrefix}`}__tags`}
          name="listing[tag_list]"
          placeholder={`Add up to ${maxTags} tags...`}
          autoComplete="off"
          value={defaultValue}
          onInput={this.handleInput}
          onKeyDown={this.handleKeyDown}
          onBlur={this.handleFocusChange}
          onFocus={onFocus}
          pattern={pattern}
        />
        {searchResultsHTML}
      </div>
    );
  }
}

Tags.propTypes = {
  defaultValue: PropTypes.string.isRequired,
  onInput: PropTypes.func.isRequired,
  maxTags: PropTypes.number.isRequired,
  classPrefix: PropTypes.string.isRequired,
  fieldClassName: PropTypes.string.isRequired,
  listing: PropTypes.string.isRequired,
  category: PropTypes.string.isRequired,
  onFocus: PropTypes.func.isRequired,
  pattern: PropTypes.string.isRequired,
};

export default Tags;
