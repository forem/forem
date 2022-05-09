import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Tabs } from '../Tabs';
import '@testing-library/jest-dom';

describe('<Tabs />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Tabs onPreview={null} previewShowing={false} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders two buttons', () => {
    const { getByRole } = render(
      <Tabs onPreview={null} previewShowing={false} />,
    );

    expect(getByRole('button', { name: /preview/i })).toBeInTheDocument();
    expect(getByRole('button', { name: /edit/i })).toBeInTheDocument();
  });

  describe('highlights the current tab', () => {
    it('when preview is selected', () => {
      const { getByRole } = render(
        <Tabs onPreview={null} previewShowing={true} />,
      );

      expect(
        getByRole('button', { name: /preview/i }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toEqual(true);
      expect(
        getByRole('button', { name: /edit/i }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toEqual(false);
    });

    it('should make the edit button the current button when not in preview mode', () => {
      const { getByRole } = render(
        <Tabs onPreview={null} previewShowing={false} />,
      );

      expect(
        getByRole('button', { name: /edit/i }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toEqual(true);
      expect(
        getByRole('button', { name: /preview/i }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toEqual(false);
    });

    it('should make the preview button the current button when in preview mode', () => {
      const { getByRole } = render(
        <Tabs onPreview={null} previewShowing={true} />,
      );

      expect(
        getByRole('button', { name: /edit/i }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toEqual(false);
      expect(
        getByRole('button', { name: /preview/i }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toEqual(true);
    });
  });
});
