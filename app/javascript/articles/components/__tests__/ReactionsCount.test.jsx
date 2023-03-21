import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { ReactionsCount } from '..';
import {
  articleWithReactions,
  articleWithoutReactions,
  articleWithOneReaction,
} from '../../__tests__/utilities/articleUtilities.js';

describe('<ReactionsCount /> component', () => {
  it('should not display reactions data when there are no reactions', async () => {
    const { queryByText } = render(
      <ReactionsCount article={articleWithoutReactions} />,
    );

    expect(queryByText('0 reactions')).toBeNull();
  });

  it('should display reaction count when there are exactly one reaction', async () => {
    const { queryByText } = render(
      <ReactionsCount article={articleWithOneReaction} />,
    );

    expect(queryByText('1 reaction')).toBeNull();
  });

  it('should display reactions data when there are reactions', async () => {
    const { findByText } = render(
      <ReactionsCount article={articleWithReactions} />,
    );

    expect(findByText('232 reactions')).toBeDefined();
  });

  it('should display multiple reactions when there are reactions', async () => {
    const { findByText } = render(
      <ReactionsCount article={articleWithReactions} />,
    );

    expect(
      findByText(
        '<span class="multiple_reactions_icons_container" dir="rtl"><span class="crayons_icon_container"><img src="/assets/like.svg" alt="Like" width="18" height="18"></span>',
      ),
    ).toBeDefined();
  });
});
