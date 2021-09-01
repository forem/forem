import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { SelectedTags } from '../components/SelectedTags';

const tags = ['clojure', 'java', 'dotnet'];
const getProps = () => ({
  tags,
  onRemoveTag: jest.fn(),
  onKeyPress: jest.fn(),
});

describe('<SelectedTags />', () => {
  const renderSelectedTags = () => render(<SelectedTags {...getProps()} />);

  it('should have no a11y violations', async () => {
    const { container } = renderSelectedTags();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render all the selected tags', () => {
    const { queryByText } = renderSelectedTags();

    tags.forEach((tag) => {
      expect(queryByText(tag)).toBeDefined();
    });
  });

  it('should show the relevant links for each tag', () => {
    const { getByText } = renderSelectedTags();
    tags.forEach((tag) => {
      expect(getByText(tag).closest('a').href).toContain(`/listings?t=${tag}`);
    });
  });

  it('should remove a tag', async () => {
    const onRemoveTag = jest.fn();
    const onKeyPress = jest.fn();
    const { getAllByText } = render(
      <SelectedTags
        tags={tags}
        onKeyPress={onKeyPress}
        onRemoveTag={onRemoveTag}
      />,
    );

    const firstTagX = getAllByText('×')[0];
    firstTagX.click();

    expect(onRemoveTag).toHaveBeenCalledTimes(1);
  });
});
