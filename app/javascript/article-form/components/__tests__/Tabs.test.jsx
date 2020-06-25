import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Tabs } from '../Tabs';

describe('<Tabs />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Tabs onPreview={null} previewShowing={false} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders two buttons', () => {
    const { getByText } = render(
      <Tabs onPreview={null} previewShowing={false} />,
    );
    getByText(/preview/i, { selector: 'button' });
    getByText(/edit/i, { selector: 'button' });
  });

  describe('highlights the current tab', () => {
    it('when preview is selected', () => {
      const { getByText } = render(
        <Tabs onPreview={null} previewShowing={true} />,
      );

      expect(
        getByText(/preview/i, { selector: 'button' }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toBe(true);
      expect(
        getByText(/edit/i, { selector: 'button' }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toBe(false);
    });

    it('when edit is selected', () => {
      const { getByText } = render(
        <Tabs onPreview={null} previewShowing={false} />,
      );

      expect(
        getByText(/edit/i, { selector: 'button' }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toBe(true);
      expect(
        getByText(/preview/i, { selector: 'button' }).classList.contains(
          `crayons-tabs__item--current`,
        ),
      ).toBe(false);
    });
  });
});
