import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { CommentsList } from '../CommentsList';
import { singleComment, threeCommentList } from './utilities/commentUtilities';

// Show buttons

// When 1 top comment and 1 total comment: hide button

// When 2 top comments and 2 total comments: hide button

// When more than 3 total comments: show button

describe('<CommentsList />', () => {
  it('should have no a11y violations', async () => {
    global.timeAgo = jest.fn(() => '4 days ago');

    const { container } = render(
      <CommentsList
        comments={threeCommentList}
        articlePath=""
        totalCount={3}
      />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should not render without comments', () => {
    const { container } = render(<CommentsList />);

    expect(container.innerHTML).toEqual('');
  });

  it('should not render with empty comments array', () => {
    const { container } = render(
      <CommentsList comments={[]} articlePath="" totalCount={0} />,
    );

    expect(container.innerHTML).toEqual('');
  });

  it('should not render "See all comments" button when there is a single comment and it is the top comment', () => {
    const { queryByTestId } = render(
      <CommentsList comments={[singleComment]} articlePath="" totalCount={1} />,
    );

    const showMoreCommentsButton = queryByTestId('see-all-comments');

    expect(showMoreCommentsButton).toBeNull();
  });

  it('should not render "See all comments" button when there are two comments and are both top comments', () => {
    const { queryByTestId } = render(
      <CommentsList
        comments={[singleComment, singleComment]}
        articlePath=""
        totalCount={2}
      />,
    );

    const showMoreCommentsButton = queryByTestId('see-all-comments');

    expect(showMoreCommentsButton).toBeNull();
  });

  it('should render "See all comments" button when there are two top comments and more than two total', () => {
    const { queryByTestId } = render(
      <CommentsList
        comments={[singleComment, singleComment]}
        articlePath=""
        totalCount={3}
      />,
    );

    expect(queryByTestId('see-all-comments')).toExist();
  });
});
