import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { SaveButton } from '../SaveButton';

it('should not show bookmark button when saveable is false', () => {
  const article = { class_name: 'Article', id: 1 };
  const { queryByRole } = render(
    <SaveButton article={article} saveable={false} />,
  );
  const saveButton = queryByRole('button', { name: 'Save to reading list' });

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
  const { queryByRole } = render(<SaveButton article={article} isBookmarked />);
  const saveButton = queryByRole('button', {
    name: 'Save to reading list',
    pressed: true,
  });

  expect(saveButton).not.toBeNull();
});

it('should button as not being bookmarked', () => {
  const article = { class_name: 'Article', id: 1 };
  const { queryByRole } = render(
    <SaveButton article={article} isBookmarked={false} />,
  );
  const saveButton = queryByRole('button', {
    name: 'Save to reading list',
    pressed: false,
  });

  expect(saveButton).not.toBeNull();
});

it('should bookmark when it previously was not', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { getByRole, findByRole } = render(
    <SaveButton onClick={jest.fn()} article={article} isBookmarked={false} />,
  );
  const saveButton = getByRole('button', { name: 'Save to reading list' });
  saveButton.click();

  const savedButton = await findByRole('button', {
    name: 'Save to reading list',
    pressed: true,
  });

  expect(savedButton).not.toBeNull();
});

it('should unbookmark when it previously was bookmarked', async () => {
  const article = { class_name: 'Article', id: 1 };
  const { getByRole, findByRole } = render(
    <SaveButton onClick={jest.fn()} article={article} isBookmarked />,
  );

  const savedButton = getByRole('button', {
    name: 'Save to reading list',
    pressed: true,
  });
  savedButton.click();

  const saveButton = await findByRole('button', {
    name: 'Save to reading list',
    pressed: false,
  });

  expect(saveButton).not.toBeNull();
});
