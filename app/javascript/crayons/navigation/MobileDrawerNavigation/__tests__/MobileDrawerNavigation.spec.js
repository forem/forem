import { h } from 'preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { render, waitFor } from '@testing-library/preact';
import { MobileDrawerNavigation } from '../MobileDrawerNavigation';

describe('<MobileDrawerNavigation />', () => {
  const testLinks = [
    { url: '/#1', displayName: 'Link 1', isCurrentPage: true },
    { url: '/#2', displayName: 'Link 2', isCurrentPage: false },
    { url: '/#3', displayName: 'Link 3', isCurrentPage: false },
  ];

  it('should have no a11y violations when closed', async () => {
    const { container } = render(
      <MobileDrawerNavigation
        navigationTitle="Test navigation"
        headingLevel={1}
        navigationLinks={testLinks}
      />,
    );

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when open', async () => {
    const { container, getByRole } = render(
      <MobileDrawerNavigation
        navigationTitle="Test navigation"
        headingLevel={1}
        navigationLinks={testLinks}
      />,
    );

    getByRole('button', { name: 'Test navigation' }).click();
    await waitFor(() => getByRole('navigation', { name: 'Test navigation' }));

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render a heading with a button when closed', () => {
    const { container } = render(
      <MobileDrawerNavigation
        navigationTitle="Test navigation"
        headingLevel={1}
        navigationLinks={testLinks}
      />,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a navigation with a checkmark for current page when open', async () => {
    const { container, getByRole } = render(
      <MobileDrawerNavigation
        navigationTitle="Test navigation"
        headingLevel={1}
        navigationLinks={testLinks}
      />,
    );

    getByRole('button', { name: 'Test navigation' }).click();
    await waitFor(() => getByRole('navigation', { name: 'Test navigation' }));
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render all links', async () => {
    const { getByRole } = render(
      <MobileDrawerNavigation
        navigationTitle="Test navigation"
        headingLevel={1}
        navigationLinks={testLinks}
      />,
    );

    getByRole('button', { name: 'Test navigation' }).click();
    await waitFor(() => getByRole('navigation', { name: 'Test navigation' }));

    expect(getByRole('link', { name: 'Link 1' })).toBeInTheDocument();
    expect(getByRole('link', { name: 'Link 2' })).toBeInTheDocument();
    expect(getByRole('link', { name: 'Link 3' })).toBeInTheDocument();
  });
});
