import { h } from 'preact';
import render from 'preact-render-to-json';
import { CommentsList } from '../CommentsList';
import { singleComment, threeCommentList } from './utilities/commentUtilities';
// import '../../../../assets/javascripts/utilities/timeAgo';

// Show buttons

// When 1 top comment and 1 total comment: hide button

// When 2 top comments and 2 total comments: hide button

// When more than 3 total comments: show button

describe('<CommentsList />', () => {
  it('should not render without comments', () => {
    const tree = render(<CommentsList />);

    expect(tree).toMatchSnapshot();
  });

  it('should not render with empty comments array', () => {
    const tree = render(
      <CommentsList comments={[]} articlePath="" totalCount={0} />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should render comments', () => {
    global.timeAgo = jest.fn(() => '4 days ago');
    const tree = render(
      <CommentsList
        comments={threeCommentList}
        articlePath=""
        totalCount={3}
      />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should not render "See all comments" button when there is a single comment and it is the top comment', () => {
    const tree = render(
      <CommentsList comments={[singleComment]} articlePath="" totalCount={1} />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should not render "See all comments" button when there are two comments and are both top comments', () => {
    const tree = render(
      <CommentsList
        comments={[singleComment, singleComment]}
        articlePath=""
        totalCount={2}
      />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should render "See all comments" button when there are two top comments and more than two total', () => {
    const tree = render(
      <CommentsList
        comments={[singleComment, singleComment]}
        articlePath=""
        totalCount={3}
      />,
    );

    expect(tree).toMatchSnapshot();
  });
});
