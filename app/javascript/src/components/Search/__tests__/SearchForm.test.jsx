import { h } from 'preact';
import render from 'preact-render-to-json';
import { SearchForm } from '../SearchForm';

describe('<SearchForm />', () => {
  it('renders properly when given search functions and a search term', () => {
    const onSubmitSearch = jest.fn();
    const onSearch = jest.fn();
    const searchTerm = 'hello';
    const tree = render(
      <SearchForm
        onSubmitSearch={onSubmitSearch}
        onSearch={onSearch}
        searchTerm={searchTerm}
        searchBoxId="nav-search"
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
