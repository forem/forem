import 'preact/devtools';
import { Component, h } from 'preact';
import PropTypes from 'prop-types';
import {
  getInitialSearchTerm,
  hasInstantClick,
  preloadSearchResults,
  displaySearchResults,
} from '../../utils/search';
import { SearchForm } from './SearchForm';

const GLOBAL_SEARCH_KEY_CODE = 191;
const ENTER_KEY_CODE = 13;

export class Search extends Component {
  static defaultProps = {
    searchBoxId: 'nav-search',
  };

  componentWillMount() {
    this.setState(
      { searchTerm: getInitialSearchTerm(window.location.search) },
      () => preloadSearchResults({ searchTerm: this.state.searchTerm }),
    );
    const searchPageChecker = () => {
      if (
        this.enableSearchPageChecker &&
        this.state.searchTerm !== '' &&
        /^http(s)?:\/\/[^/]+\/search/.exec(window.location.href) === null
      ) {
        this.setState({ searchTerm: '' });
      }

      setTimeout(searchPageChecker, 500);
    };

    searchPageChecker();
  }

  componentDidMount() {
    this.registerGlobalSearchKeyListener();
    InstantClick.on('change', this.enableSearchPageListener);
  }

  componentDidUnmount() {
    document.removeEventListener('keydown', this.globalSearchKeyListener);
    InstantClick.off('change', this.enableSearchPageListener);
  }

  enableSearchPageChecker = true;
  globalSearchKeyListener;
  enableSearchPageListener = () => {
    this.enableSearchPageChecker = true;
  };

  registerGlobalSearchKeyListener() {
    const searchBox = document.getElementById(this.props.searchBoxId);

    this.globalSearchKeyListener = event => {
      const { tagName, classList } = document.activeElement;
      if (
        event.which !== GLOBAL_SEARCH_KEY_CODE ||
        tagName === 'INPUT' ||
        tagName === 'TEXTAREA' ||
        classList.contains('input')
      ) {
        return;
      }

      event.preventDefault();
      searchBox.focus();
      searchBox.select();
    };

    document.addEventListener('keydown', this.globalSearchKeyListener);
  }

  search = event => {
    const { keyCode, target: { value } } = event;

    this.enableSearchPageChecker = false;

    if (hasInstantClick() && keyCode === ENTER_KEY_CODE) {
      this.setState({ searchTerm: value }, () => {
        preloadSearchResults({ searchTerm: this.state.searchTerm });
      });
    }
  };

  submit = event => {
    if (hasInstantClick) {
      const { searchTerm } = this.state;

      event.preventDefault();
      displaySearchResults({ searchTerm });
    }
  };

  render({ searchBoxId }, { searchTerm = '' }) {
    return (
      <SearchForm
        searchTerm={searchTerm}
        onSearch={this.search}
        onSubmitSearch={this.submit}
        searchBoxId={searchBoxId}
      />
    );
  }
}

Search.propTypes = {
  searchBoxId: PropTypes.string,
};
