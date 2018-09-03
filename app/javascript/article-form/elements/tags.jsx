import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class Tags extends Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedIndex: -1,
      searchResults: [],
    };

    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
      .content;
    const algoliaKey = document.querySelector("meta[name='algolia-public-key']")
      .content;
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey);
    this.index = client.initIndex(`Tag_${env}`);
  }

  get selected() {
    return this.props.defaultValue
      .split(',')
      .map(item => item != undefined && item.trim())
      .filter(item => item.length > 0);
  }

  render() {
    let searchResultsHTML = '';
    const searchResultsRows = this.state.searchResults.map((tag, index) => (
      <div
        tabIndex="-1"
        className={`articleform__tagoptionrow articleform__tagoptionrow--${
          this.state.selectedIndex === index ? 'active' : 'inactive'
        }`}
        onClick={this.handleTagClick}
        data-content={tag.name}
      >
        {tag.name}
      </div>
    ));
    if (
      this.state.searchResults.length > 0 &&
      document.activeElement.id === 'tag-input'
    ) {
      searchResultsHTML = (
        <div className="articleform__tagsoptions">{searchResultsRows}</div>
      );
    }

    return (
      <div className="articleform__tagswrapper">
        <textarea
          id="tag-input"
          type="text"
          className="articleform__tags"
          placeholder="tags"
          value={this.props.defaultValue}
          onInput={this.handleInput}
          onKeyDown={this.handleKeyDown}
          onBlur={this.handleFocusChange}
          onFocus={this.handleFocusChange}
        />
        {searchResultsHTML}
      </div>
    );
  }

  handleTagClick = e => {
    const input = document.getElementById('tag-input');
    input.focus();

    console.log('CLICK');
    this.insertTag(e.target.dataset.content);
  };

  handleInput = e => {
    const component = this;

    let value = e.target.value;
    if (e.inputType === 'insertText') {
      if (e.target.value[e.target.selectionStart - 2] === ',') {
        value = `${value.slice(0, e.target.selectionStart - 1)} ${value.slice(
          e.target.selectionStart - 1,
          value.length,
        )}`;
      }
    }

    if (e.data === ',') {
      value += ' ';
    }

    this.props.onInput(value);

    const query = this.getCurrentTagAtSelectionIndex(
      e.target.value,
      e.target.selectionStart - 1,
    );
    if (query === '' && e.target.value != '') {
      component.setState({
        searchResults: [],
      });
      return;
    } else if (query === '' || e.target.value === '') {
      component.setState({
        searchResults: [],
        selected: [],
      });
      return;
    }
    return this.search(query);
  };

  getCurrentTagAtSelectionIndex(value, index) {
    let tagIndex = 0;
    const tagByCharacterIndex = {};

    value.split('').map((letter, index) => {
      if (letter === ',') {
        tagIndex++;
      } else {
        tagByCharacterIndex[index] = tagIndex;
      }
    });

    const tag = value.split(',')[tagByCharacterIndex[index]];

    if (tag === undefined) {
      return '';
    }
    return tag.trim();
  }

  search(query) {
    return this.index
      .search(query, {
        hitsPerPage: 10,
        filters: 'supported:true',
      })
      .then(content => {
        this.setState({
          searchResults: content.hits.filter(
            hit => !this.props.defaultValue.split(',').includes(hit.name),
          ),
        });
      });
  }

  handleKeyDown = e => {
    const component = this;
    const keyCode = e.keyCode;
    if (component.selected.length === MAX_TAGS && e.keyCode === KEYS.COMMA) {
      e.preventDefault();
      return;
    }
    if (
      (e.keyCode === KEYS.DOWN || e.keyCode === KEYS.TAB) &&
      component.state.selectedIndex <
        component.state.searchResults.length - 1 &&
      component.props.defaultValue != ''
    ) {
      // down key or tab key
      e.preventDefault();
      this.setState({
        selectedIndex: component.state.selectedIndex + 1,
      });
    } else if (e.keyCode === KEYS.UP && component.state.selectedIndex > -1) {
      // up key
      e.preventDefault();
      this.setState({
        selectedIndex: component.state.selectedIndex - 1,
      });
    } else if (
      e.keyCode === KEYS.RETURN &&
      component.state.selectedIndex > -1
    ) {
      // return key
      e.preventDefault();
      this.insertTag(
        component.state.searchResults[component.state.selectedIndex].name,
      );

      setTimeout(() => {
        document.getElementById('tag-input').focus();
      }, 10);
    } else if (
      e.keyCode === KEYS.COMMA &&
      component.state.selectedIndex === -1
    ) {
      // comma key
      component.setState({
        searchResults: [],
        selectedIndex: -1,
      });
    } else if (e.keyCode === KEYS.DELETE) {
      // Delete key
      if (
        component.props.defaultValue[
          component.props.defaultValue.length - 1
        ] === ','
      ) {
        const selectedTags = component.selected;
        component.setState({
          selectedIndex: -1,
          selected: selectedTags.slice(0, selectedTags.length - 2),
        });
      }
    } else if (
      (e.keyCode < 65 || e.keyCode > 90) &&
      e.keyCode != KEYS.COMMA &&
      e.keyCode != KEYS.DELETE &&
      e.keyCode != KEYS.LEFT &&
      e.keyCode != KEYS.RIGHT &&
      e.keyCode != KEYS.TAB
    ) {
      // not letter or comma or delete
      e.preventDefault();
    }
  };

  insertTag(tag) {
    const input = document.getElementById('tag-input');

    const range = this.getRangeBetweenCommas(input.value, input.selectionStart);
    const insertingAtEnd = range[1] === input.value.length;
    const maxTagsWillBeReached = this.selected.length === MAX_TAGS;
    if (insertingAtEnd && !maxTagsWillBeReached) {
      tag += ', ';
    }

    // Insert new tag between commas if there are any.
    const newInput =
      input.value.slice(0, range[0]) +
      tag +
      input.value.slice(range[1], input.value.length);

    this.props.onInput(newInput);

    this.setState({
      searchResults: [],
      selectedIndex: -1,
    });
  }

  // Given an index of the String value, finds the range between commas.
  // This is useful when we want to insert a new tag anywhere in the
  // comma separated list of tags.
  getRangeBetweenCommas(value, index) {
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
  }

  handleFocusChange = e => {
    const component = this;
    setTimeout(() => {
      if (document.activeElement.id === 'tag-input') {
        return;
      }
      component.forceUpdate();
    }, 100);
  };
}

Tags.propTypes = {
  defaultValue: PropTypes.string.isRequired,
};

const KEYS = {
  UP: 38,
  DOWN: 40,
  LEFT: 37,
  RIGHT: 39,
  TAB: 9,
  RETURN: 13,
  COMMA: 188,
  DELETE: 8,
};

const MAX_TAGS = 4;

export default Tags;
