import 'preact/devtools';
import { h, Component, Fragment } from 'preact';
import PropTypes from 'prop-types';
import {
  getInitialSearchTerm,
  hasInstantClick,
  preloadSearchResults,
  displaySearchResults,
} from '../utilities/search';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { SearchForm } from './SearchForm';

const GLOBAL_MINIMIZE_KEY = 'Digit0';
const GLOBAL_SEARCH_KEY = 'Slash';
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
    InstantClick.off('change', this.enableSearchPageListener);
  }

  minimizeHeader = (event) => {
    event.preventDefault();
    document.body.classList.toggle('zen-mode');
  };

  focusOnSearchBox = (event) => {
    event.preventDefault();
    document.body.classList.remove('zen-mode');

    const { searchBoxId } = this.props;
    const searchBox = document.getElementById(searchBoxId);
    searchBox.focus();
    searchBox.select();
  };

  render({ searchBoxId }, { searchTerm = '' }) {
    return (
      <Fragment>
        <KeyboardShortcuts
          shortcuts={{
            [GLOBAL_SEARCH_KEY]: this.focusOnSearchBox,
            [GLOBAL_MINIMIZE_KEY]: this.minimizeHeader,
          }}
        />
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
      </Fragment>
    );
  }
}

Search.propTypes = {
  searchBoxId: PropTypes.string,
};
