import { h } from 'preact';
import { deep } from 'preact-render-spy';
import Description from '../description';

describe('<Description />', () => {
  const defaultProps = {
    onChange: () => {
      return 'onChange';
    },
    defaultValue: 'Some description',
  };

  const renderDescription = (props = defaultProps) =>
    deep(<Description {...props} />);

  const context = renderDescription();
  const descriptionField = context.find('#article-form-description');

  it('Should have "description" as placeholder', () => {
    expect(descriptionField.attr('placeholder')).toBe('description');
  });

  it(`Should have "${defaultProps.defaultValue}" as value`, () => {
    expect(descriptionField.attr('value')).toBe(defaultProps.defaultValue);
  });
});
