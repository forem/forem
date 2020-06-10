import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import SelectedTags from '../components/SelectedTags';

const tags = ['clojure', 'java', 'dotnet'];
const getProps = () => ({
  tags,
  onClick: () => {
    return 'onClick';
  },
  onKeyPress: () => {
    return 'onKeyPress';
  },
});

describe('<SelectedTags />', () => {
  const renderSelectedTags = () => render(<SelectedTags {...getProps()} />);

  it('should have no a11y violations', async () => {
    const { container } = renderSelectedTags();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render all the selected tags', () => {
    const { getByText } = renderSelectedTags();
    tags.forEach(tag => {
      getByText(tag);
    });
  });

  it('should show the relevant links for each tag', () => {
    const { getByText } = renderSelectedTags();
    tags.forEach(tag => {
      expect(getByText(tag).closest('a').href).toContain(`/listings?t=${tag}`);
    });
  });
  });
});
