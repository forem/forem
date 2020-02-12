import { h } from 'preact';
import render from 'preact-render-to-json';
import { TagsFollowed } from '..';

describe('<TagsFollowed />', () => {
  it('should render the empty view when no tags are passed in', () => {
    const tree = render(<TagsFollowed tags={[]} />);
    expect(tree).toMatchSnapshot();
  });

  it('should render the tags followed when tags are passed in', () => {
    const tags = [
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
      {
        id: 715,
        name: 'discuss',
        bg_color_hex: '#000000',
        text_color_hex: '#FFFFFF',
        hotness_score: 495293,
        points: 1.0,
      },
      {
        id: 112,
        name: 'productivity',
        bg_color_hex: '#2A0798',
        text_color_hex: '#C8F7C5',
        hotness_score: 296498,
        points: 1.0,
      },
      {
        id: 630,
        name: 'career',
        bg_color_hex: '#2A2566',
        text_color_hex: '#FFFFFF',
        hotness_score: 269614,
        points: 1.0,
      },
      {
        id: 15,
        name: 'node',
        bg_color_hex: '#3d8836',
        text_color_hex: '#ffffff',
        hotness_score: 197945,
        points: 5.0,
      },
      {
        id: 23,
        name: 'css',
        bg_color_hex: '#004f86',
        text_color_hex: '#ffffff',
        hotness_score: 180553,
        points: 5.0,
      },
      {
        id: 57,
        name: 'html',
        bg_color_hex: '#F53900',
        text_color_hex: '#FFFFFF',
        hotness_score: 73916,
        points: 1.0,
      },
      {
        id: 169,
        name: 'typescript',
        bg_color_hex: '#234A84',
        text_color_hex: '#FFFFFF',
        hotness_score: 67712,
        points: 5.0,
      },
      {
        id: 228,
        name: 'opensource',
        bg_color_hex: '#26BE00',
        text_color_hex: '#FFFFFF',
        hotness_score: 67153,
        points: 1.0,
      },
    ];

    const tree = render(<TagsFollowed tags={tags} />);
    expect(tree).toMatchSnapshot();
  });
});
