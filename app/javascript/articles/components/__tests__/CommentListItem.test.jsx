import { h } from 'preact';
import { render } from '@testing-library/preact';
import { CommentListItem } from '../CommentListItem';
import { singleComment } from './utilities/commentUtilities';

describe('<CommentListItem />', () => {
  beforeEach(() => {
    global.timeAgo = jest.fn(() => '4 days ago');
  });

  it('interpolates the username into the avatar alt text', () => {
    const { getByAltText } = render(
      <CommentListItem comment={singleComment} />,
    );

    expect(getByAltText(`${singleComment.username} avatar`)).toBeTruthy();
  });
});
