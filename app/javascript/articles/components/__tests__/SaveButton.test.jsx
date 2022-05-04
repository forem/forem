import { h } from 'preact';
import { fireEvent, render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { SaveButton } from '../SaveButton';

it('should not show bookmark button when saveable is false', () => {
  const article = { class_name: 'Article', id: 1 };
  const { queryByText } = render(
    <SaveButton article={article} saveable={false} />,
  );
  const saveButton = queryByText('Saved');

  expect(saveButton).toBeNull();
});

it('should have no a11y violations', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { container } = render(<SaveButton article={article} />);
  const results = await axe(container);

  expect(results).toHaveNoViolations();
});

it('should render button as bookmarked', () => {
  const article = { class_name: 'Article', id: 1 };
  const { queryByText } = render(<SaveButton article={article} isBookmarked />);
  const saveButton = queryByText('Saved');

  expect(saveButton).not.toBeNull();
});

it('should button as not being bookmarked', () => {
  const article = { class_name: 'Article', id: 1 };
  const { queryByText } = render(
    <SaveButton article={article} isBookmarked={false} />,
  );
  const saveButton = queryByText('Save');

  expect(saveButton).not.toBeNull();
});

it('should bookmark when it previously was not', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { getByText, findByText } = render(
    <SaveButton onClick={jest.fn()} article={article} isBookmarked={false} />,
  );
  const saveButton = getByText('Save');
  saveButton.click();

  const savedButton = await findByText('Saved');

  expect(savedButton).not.toBeNull();
});

it('should unbookmark when it previously was bookmarked', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { getByText, findByText } = render(
    <SaveButton onClick={jest.fn()} article={article} isBookmarked />,
  );

  const savedButton = getByText('Saved');
  savedButton.click();

  const saveButton = await findByText('Save');

  expect(saveButton).not.toBeNull();
});

it('should change text to unbookmark when hovering over button and it is bookmarked', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { getByText, findByText } = render(
    <SaveButton onClick={jest.fn()} article={article} isBookmarked />,
  );

  const savedButton = getByText('Saved');
  fireEvent.mouseMove(savedButton);

  const saveButton = await findByText('Unsave');

  expect(saveButton).not.toBeNull();
});

it('should not change button text when hovering over button and it is not bookmarked', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { getByText, findByText } = render(
    <SaveButton onClick={jest.fn()} article={article} isBookmarked={false} />,
  );

  const savedButton = getByText('Save');
  fireEvent.mouseMove(savedButton);

  // We're checking for the same button text again because we need to find the element again
  // again after the mouse has moved over the button.
  const saveButton = await findByText('Save');

  expect(saveButton).not.toBeNull();
});
