import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { FavoritedMarker } from '..';

describe('<FavoritedMarker /> component', () => {
  beforeEach(() => {
    document.body.dataset.globalFeatureFlagsEnabled = 'community_favorites';
  });

  afterEach(() => {
    delete document.body.dataset.globalFeatureFlagsEnabled;
  });

  it('renders nothing when the feature flag is off', () => {
    document.body.dataset.globalFeatureFlagsEnabled = 'some_other_flag';

    const { container } = render(
      <FavoritedMarker favoritedByUserId={99} currentUserId={11} />,
    );

    expect(container).toBeEmptyDOMElement();
  });

  it('renders nothing when nobody has favorited the article', () => {
    const { container } = render(
      <FavoritedMarker favoritedByUserId={null} currentUserId={11} />,
    );

    expect(container).toBeEmptyDOMElement();
  });

  it('renders the marker when someone else favorited the article', () => {
    const { getByLabelText } = render(
      <FavoritedMarker favoritedByUserId={99} currentUserId={11} />,
    );

    expect(getByLabelText('Favorited')).toBeInTheDocument();
  });

  it('names the viewer when they are the one who favorited it', () => {
    const { getByLabelText } = render(
      <FavoritedMarker favoritedByUserId={11} currentUserId={11} />,
    );

    expect(getByLabelText('Favorited by you')).toBeInTheDocument();
  });

  it('recognises the viewer when their id arrives as a string', () => {
    const { getByLabelText } = render(
      <FavoritedMarker favoritedByUserId={11} currentUserId="11" />,
    );

    expect(getByLabelText('Favorited by you')).toBeInTheDocument();
  });

  it('does not claim a signed-out visitor favorited it', () => {
    const { container } = render(
      <FavoritedMarker favoritedByUserId={null} currentUserId={null} />,
    );

    expect(container).toBeEmptyDOMElement();
  });

  it('does not claim the viewer favorited it when they are signed out', () => {
    const { getByLabelText } = render(
      <FavoritedMarker favoritedByUserId={99} currentUserId={undefined} />,
    );

    expect(getByLabelText('Favorited')).toBeInTheDocument();
  });
});
