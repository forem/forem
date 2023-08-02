import { h } from 'preact';
import { render, within } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { i18nSupport } from '../../../__support__/i18n';
import { reactionImagesSupport } from '../../../__support__/reaction_images';
import { ReactionsCount } from '..';
import {
  articleWithReactions,
  articleWithoutReactions,
  articleWithOneReaction,
} from '../../__tests__/utilities/articleUtilities.js';

describe('<ReactionsCount /> component', () => {
  beforeAll(() => {
    i18nSupport();
    reactionImagesSupport();
  });

  it('should not display reactions data when there are no reactions', async () => {
    const { queryByText } = render(
      <ReactionsCount article={articleWithoutReactions} />,
    );

    expect(queryByText(/0 reactions/i)).not.toExist();
  });

  it('should display reaction count when there are exactly one reaction', async () => {
    const { queryByText } = render(
      <ReactionsCount article={articleWithOneReaction} />,
    );

    expect(queryByText(/1 reaction/i)).toExist();
  });

  it('should display reactions data when there are reactions', async () => {
    const { queryByText } = render(
      <ReactionsCount article={articleWithReactions} />,
    );

    expect(queryByText(/232 reactions/i)).toExist();
  });

  it('should display multiple reactions when there are reactions', async () => {
    const { getByTestId } = render(
      <ReactionsCount article={articleWithReactions} />,
    );

    const container = getByTestId('multiple-reactions-icons-container');
    const { queryByAltText } = within(container);

    // `articleWithReactions` has all reactions except exploding head
    // also, we are not using `toHaveAttribute` directly because Jest inserts a
    // base URL and we are only interested in the path
    expect(queryByAltText('Like').getAttribute('src')).toContain(
      '/assets/sparkle-heart.svg',
    );
    expect(queryByAltText('Unicorn').getAttribute('src')).toContain(
      '/assets/multi-unicorn.svg',
    );
    expect(queryByAltText('Fire').getAttribute('src')).toContain(
      '/assets/fire.svg',
    );
    expect(queryByAltText('Raised Hands').getAttribute('src')).toContain(
      '/assets/raised-hands.svg',
    );
    expect(queryByAltText('Exploding Head')).not.toExist();
  });
});
