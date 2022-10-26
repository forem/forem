import { h, Component, toChildArray } from 'preact';

import { action } from '@storybook/addon-actions';
import { SearchForm } from '..';

const commonProps = {
  onSubmitSearch: (e) => {
    e.preventDefault();
    action('on submit')(e);
  },
};

class FocusedForm extends Component {
  componentDidMount() {
    document.querySelector('.crayons-header--search-input').focus();
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
  title: 'App Components/Search',
};

export const NoSearchTerm = () => <SearchForm {...commonProps} searchTerm="" />;

NoSearchTerm.storyName = 'no search term';

export const WithSearchTerm = () => (
  <SearchForm {...commonProps} searchTerm="Hello" />
);

WithSearchTerm.storyName = 'with search term';

export const WithFocus = () => (
  <FocusedForm>
    <SearchForm {...commonProps} searchTerm="Hello" />
  </FocusedForm>
);

WithFocus.storyName = 'with focus';
