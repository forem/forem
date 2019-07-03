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

const GLOBAL_MINIMIZE_KEY = '0';
const GLOBAL_SEARCH_KEY = '/';
const ENTER_KEY = 'Enter';

export class Search extends Component {
  static defaultProps = {
    searchBoxId: 'nav-search',
  };

  constructor(props) {
    super(props);
    this.enableSearchPageChecker = true;
  }

  componentWillMount() {
    let searchTerm;

    ({ searchTerm } = this.state);
    this.setState(
      { searchTerm: getInitialSearchTerm(window.location.search) },
      () => preloadSearchResults({ searchTerm }),
    );

    ({ searchTerm } = this.state);
    const searchPageChecker = () => {
      if (
        this.enableSearchPageChecker &&
        searchTerm !== '' &&
        /^http(s)?:\/\/[^/]+\/search/.exec(window.location.href) === null
      ) {
        this.setState({ searchTerm: '' });
      }

      setTimeout(searchPageChecker, 500);
    };

    searchPageChecker();
  }

  componentDidMount() {
    this.registerGlobalKeysListener();
    InstantClick.on('change', this.enableSearchPageListener);
  }

  enableSearchPageListener = () => {
    this.enableSearchPageChecker = true;
  };

  hasKeyModifiers = event => {
    return event.altKey || event.ctrlKey || event.metaKey || event.shiftKey;
  };

  search = event => {
    const {
      key,
      target: { value },
    } = event;

    this.enableSearchPageChecker = false;

    if (hasInstantClick() && key === ENTER_KEY) {
      this.setState({ searchTerm: value }, () => {
        const { searchTerm } = this.state;
        preloadSearchResults({ searchTerm });
      });
    }
  };

  submit = event => {
    if (hasInstantClick) {
      event.preventDefault();

      const { searchTerm } = this.state;
      displaySearchResults({ searchTerm });
    }
  };

  componentDidUnmount() {
    document.removeEventListener('keydown', this.globalKeysListener);
    InstantClick.off('change', this.enableSearchPageListener);
  }

  registerGlobalKeysListener() {
    const { searchBoxId } = this.props;
    const searchBox = document.getElementById(searchBoxId);

    this.globalKeysListener = event => {
      const { tagName, classList } = document.activeElement;

      if (
        (event.key !== GLOBAL_SEARCH_KEY &&
          event.key !== GLOBAL_MINIMIZE_KEY) ||
        tagName === 'INPUT' ||
        tagName === 'TEXTAREA' ||
        classList.contains('input')
      ) {
        return;
      }

      if (event.key === GLOBAL_SEARCH_KEY) {
        event.preventDefault();
        document.getElementsByTagName('body')[0].classList.remove('zen-mode');
        searchBox.focus();
        searchBox.select();
      } else if (
        event.key === GLOBAL_MINIMIZE_KEY &&
        !this.hasKeyModifiers(event)
      ) {
        event.preventDefault();
        document.getElementsByTagName('body')[0].classList.toggle('zen-mode');
      }
    };

    document.addEventListener('keydown', this.globalKeysListener);
  }

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
