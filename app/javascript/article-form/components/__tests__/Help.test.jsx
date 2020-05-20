import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { Help } from '../Help';

describe('<Help />', () => {
  it('renders properly', () => {
    const tree = render(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('does not render help if we are in preview mode', () => {
    const container = shallow(
      <Help
        previewShowing
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );
    expect(
      container.find('.crayons-article-form__main__aside').text().length,
    ).toEqual(0);
  });

  it('shows some help in edit mode', () => {
    const container = shallow(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );
    expect(
      container.find('.crayons-article-form__main__aside').text().length,
    ).toBeGreaterThan(0);
  });

  it('shows some help in edit mode', () => {
    const container = shallow(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );
    expect(
      container.find('.crayons-article-form__main__aside').text().length,
    ).toBeGreaterThan(0);
  });

  it('shows the correct help for v1', () => {
    const container = shallow(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );
    expect(
      container.find('.crayons-article-form__main__aside').text().length,
    ).toBeGreaterThan(0);
    expect(container.find('.spec__basic-editor-help').exists()).toEqual(true);
    expect(container.find('.spec__format-help').exists()).toEqual(true);
    expect(container.find('.spec__title-help').exists()).toEqual(false);
    expect(container.find('.spec__basic-tag-input-help').exists()).toEqual(
      false,
    );
  });

  it('shows the correct help section based on helpFor for v2', () => {
    const container = shallow(
      <Help
        previewShowing={false}
        helpFor="article-form-title"
        helpPosition={null}
        version="v2"
      />,
    );
    expect(
      container.find('.crayons-article-form__main__aside').text().length,
    ).toBeGreaterThan(0);
    expect(container.find('.spec__title-help').exists()).toEqual(true);
    expect(container.find('.spec__format-help').exists()).toEqual(false);
    expect(container.find('.spec__basic-editor-help').exists()).toEqual(false);
    expect(container.find('.spec__basic-tag-input-help').exists()).toEqual(
      false,
    );

    const container2 = shallow(
      <Help
        previewShowing={false}
        helpFor="article_body_markdown"
        helpPosition={null}
        version="v2"
      />,
    );
    expect(
      container2.find('.crayons-article-form__main__aside').text().length,
    ).toBeGreaterThan(0);
    expect(container2.find('.spec__format-help').exists()).toEqual(true);
    expect(container2.find('.spec__basic-editor-help').exists()).toEqual(false);
    expect(container2.find('.spec__title-help').exists()).toEqual(false);
    expect(container2.find('.spec__basic-tag-input-help').exists()).toEqual(
      false,
    );

    const container3 = shallow(
      <Help
        previewShowing={false}
        helpFor="tag-input"
        helpPosition={null}
        version="v2"
      />,
    );
    expect(
      container3.find('.crayons-article-form__main__aside').text().length,
    ).toBeGreaterThan(0);
    expect(container3.find('.spec__basic-tag-input-help').exists()).toEqual(
      true,
    );
    expect(container3.find('.spec__format-help').exists()).toEqual(false);
    expect(container3.find('.spec__basic-editor-help').exists()).toEqual(false);
    expect(container3.find('.spec__title-help').exists()).toEqual(false);
  });

  // TODO: test the modals
});
