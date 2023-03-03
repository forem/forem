import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { ReactionsCount } from '..';
import {
  articleWithReactions,
  articleWithoutReactions,
} from '../../__tests__/utilities/articleUtilities.js';

describe('<ReactionsCount /> component', () => {
  it('should not display reactions data when there are no reactions', async () => {
    const { queryByText } = render(
      <ReactionsCount article={articleWithoutReactions} />,
    );

    expect(queryByText('0 reactions')).toBeNull();
  });

  it('should display reactions data when there are reactions', async () => {
    const { findByText } = render(
      <ReactionsCount article={articleWithReactions} />,
    );

    expect(findByText('232 reactions')).toBeDefined();
  });
});
