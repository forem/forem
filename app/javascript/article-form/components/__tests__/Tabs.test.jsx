import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Tabs } from '../Tabs';
import { locale } from '../../../utilities/locale';

describe('<Tabs />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Tabs onPreview={null} previewShowing={false} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders two buttons', () => {
    const { queryByText } = render(
      <Tabs onPreview={null} previewShowing={false} />,
    );

    expect(
      queryByText(locale('views.editor.preview'), { selector: 'button' }),
    ).toBeDefined();
    expect(
      queryByText(locale('views.editor.edit'), { selector: 'button' }),
    ).toBeDefined();
  });

  describe('highlights the current tab', () => {
    it('when preview is selected', () => {
      const { getByText } = render(
        <Tabs onPreview={null} previewShowing={true} />,
      );

      expect(
        getByText(locale('views.editor.preview'), {
          selector: 'button',
        }).classList.contains(`crayons-tabs__item--current`),
      ).toEqual(true);
      expect(
        getByText(locale('views.editor.edit'), {
          selector: 'button',
        }).classList.contains(`crayons-tabs__item--current`),
      ).toEqual(false);
    });

    it('should make the edit button the current button when not in preview mode', () => {
      const { getByText } = render(
        <Tabs onPreview={null} previewShowing={false} />,
      );

      expect(
        getByText(locale('views.editor.edit'), {
          selector: 'button',
        }).classList.contains(`crayons-tabs__item--current`),
      ).toEqual(true);
      expect(
        getByText(locale('views.editor.preview'), {
          selector: 'button',
        }).classList.contains(`crayons-tabs__item--current`),
      ).toEqual(false);
    });

    it('should make the preview button the current button when in preview mode', () => {
      const { getByText } = render(
        <Tabs onPreview={null} previewShowing={true} />,
      );

      expect(
        getByText(locale('views.editor.edit'), {
          selector: 'button',
        }).classList.contains(`crayons-tabs__item--current`),
      ).toEqual(false);
      expect(
        getByText(locale('views.editor.preview'), {
          selector: 'button',
        }).classList.contains(`crayons-tabs__item--current`),
      ).toEqual(true);
    });
  });
});
