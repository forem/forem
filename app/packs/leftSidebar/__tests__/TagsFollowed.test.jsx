import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { TagsFollowed } from '..';

const getTags = () => [
  {
    id: 6,
    name: 'javascript',
    bg_color_hex: '#F7DF1E',
    text_color_hex: '#000000',
    hotness_score: 5012724,
    points: 5.0,
  },
  {
    id: 8,
    name: 'webdev',
    bg_color_hex: '#562765',
    text_color_hex: '#ffffff',
    hotness_score: 2390660,
    points: 1.0,
  },
  {
    id: 125,
    name: 'react',
    bg_color_hex: '#222222',
    text_color_hex: '#61DAF6',
    hotness_score: 565245,
    points: 5.0,
  },
];

describe('<TagsFollowed />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<TagsFollowed tags={getTags()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the empty view when no tags are passed in', () => {
    const { container } = render(<TagsFollowed tags={[]} />);

    expect(container).toBeEmptyDOMElement();
  });

  it('should render the tags followed when tags are passed in', () => {
    const { queryByTitle } = render(<TagsFollowed tags={getTags()} />);

    expect(queryByTitle('javascript tag')).toBeDefined();
    expect(queryByTitle('webdev tag')).toBeDefined();
    expect(queryByTitle('react tag')).toBeDefined();
  });
});
