import { h, Component, toChildArray } from 'preact';

import { action } from '@storybook/addon-actions';
import { SearchForm } from '..';

const commonProps = {
  onSearch: action('on preloading search'),
  onSubmitSearch: (e) => {
    e.preventDefault();
    action('on submit')(e);
  },
};

class FocusedForm extends Component {
  componentDidMount() {
    document.getElementById('nav-search').focus();
  }

  render() {
    // Disabling prop types checks here because this is simply a wrapper
    // class for a Storybook story.
    // eslint-disable-next-line react/destructuring-assignment, react/prop-types
    return toChildArray(this.props.children)[0];
  }
}

export default {
  component: SearchForm,
  title: '4_App Components/Search/Search Form',
};

export const NoSearchTerm = () => <SearchForm {...commonProps} searchTerm="" />;

NoSearchTerm.story = {
  name: 'no search term',
};

export const WithSearchTerm = () => (
  <SearchForm {...commonProps} searchTerm="Hello" />
);

WithSearchTerm.story = {
  name: 'with search term',
};

export const WithFocus = () => (
  <FocusedForm>
    <SearchForm {...commonProps} searchTerm="Hello" />
  </FocusedForm>
);

WithFocus.story = {
  name: 'with focus',
};
