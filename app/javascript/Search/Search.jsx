import 'preact/devtools';
import { Component, h } from 'preact';
import PropTypes from 'prop-types';
import {
  getInitialSearchTerm,
  hasInstantClick,
  preloadSearchResults,
  displaySearchResults,
} from '../utilities/search';
import { registerGlobalKeyEventListener } from '../utilities/hooks/useGlobalKeyEventListener';
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
    const { searchBoxId } = this.props;
    const searchBox = document.getElementById(searchBoxId);

    this.globalKeyEventListener = registerGlobalKeyEventListener(
      [GLOBAL_SEARCH_KEY, GLOBAL_MINIMIZE_KEY],
      (event) => {
        if (event.key === GLOBAL_SEARCH_KEY) {
          event.preventDefault();
          document.body.classList.remove('zen-mode');
          searchBox.focus();
          searchBox.select();
        } else if (
          event.key === GLOBAL_MINIMIZE_KEY &&
          !this.hasKeyModifiers(event)
        ) {
          event.preventDefault();
          document.body.classList.toggle('zen-mode');
        }
      },
    );

    InstantClick.on('change', this.enableSearchPageListener);
  }

  enableSearchPageListener = () => {
    this.enableSearchPageChecker = true;
  };

  hasKeyModifiers = (event) => {
    return event.altKey || event.ctrlKey || event.metaKey || event.shiftKey;
  };

  submit = (event) => {
    if (hasInstantClick) {
      event.preventDefault();

      const { searchTerm } = this.state;
      displaySearchResults({ searchTerm });
    }
  };

  search(key, value) {
    this.enableSearchPageChecker = false;

    if (hasInstantClick() && key === ENTER_KEY) {
      this.setState({ searchTerm: value }, () => {
        const { searchTerm } = this.state;
        preloadSearchResults({ searchTerm });
      });
    }
  }

  componentDidUnmount() {
    document.removeEventListener('keydown', this.globalKeyEventListener);
    InstantClick.off('change', this.enableSearchPageListener);
  }

  render({ searchBoxId }, { searchTerm = '' }) {
    return (
      <SearchForm
        searchTerm={searchTerm}
        onSearch={(event) => {
          const {
            key,
            target: { value },
          } = event;
          this.search(key, value);
        }}
        onSubmitSearch={this.submit}
        searchBoxId={searchBoxId}
      />
    );
  }
}

Search.propTypes = {
  searchBoxId: PropTypes.string,
};
