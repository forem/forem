import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ItemListTags } from '../ItemListTags';

describe('<ItemListTags />', () => {
  it('should have no a11y violations with two different sets of tags', async () => {
    const { container } = render(
      <ItemListTags
        availableTags={['discuss']}
        selectedTags={['javascript']}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations with two some shared tags', async () => {
    const { container } = render(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders properly with two different sets of tags', () => {
    const { getByText, queryByText } = render(
      <ItemListTags
        availableTags={['discuss']}
        selectedTags={['javascript']}
      />,
    );

    getByText('#discuss');
    expect(queryByText('#javascript')).toBeNull();
  });

  it('renders properly with some shared tags', () => {
    const { queryByText } = render(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
      />,
    );

    expect(queryByText('#discuss')).toBeDefined();
    expect(queryByText('#javascript')).toBeDefined();
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
