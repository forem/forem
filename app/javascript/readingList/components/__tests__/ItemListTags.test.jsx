import { h } from 'preact';
import { render } from '@testing-library/preact';
import { ItemListTags } from '../ItemListTags';

describe('<ItemListTags />', () => {
  it('renders properly with two different sets of tags', () => {
      const { getByText, queryByText } = render(
      <ItemListTags
        availableTags={['discuss']}
        selectedTags={['javascript']}
      />,
    );

    expect(getByText('#discuss')).toBeTruthy();
    expect(queryByText('#javascript')).toBeNull();
  });

  it('renders properly with some shared tags', () => {
    const { getByText } = render(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
      />,
    );

    expect(getByText('#discuss')).toBeTruthy();
    expect(getByText('#javascript')).toBeTruthy();
  });

  it('triggers the onClick', () => {
    const onClick = jest.fn();
    const { getByText } = render(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
        onClick={onClick}
      />,
    );

    let tag = getByText('#discuss', { selector: 'a' });
    tag.click();

    expect(onClick).toHaveBeenCalled();
  });
});
