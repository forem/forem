import { h } from 'preact';
import render from 'preact-render-to-json';
import { FormField, RadioButton } from '@crayons';

describe('<FormField /> component', () => {
  it('should render', () => {
    const tree = render(<FormField />);
    expect(tree).toMatchSnapshot();
  });

  it('should render with contents', () => {
    const tree = render(
      <FormField>
        <RadioButton id="some-id" value="some-value" name="some-name" />
        <label htmlFor="some-id">Some Label</label>
      </FormField>,
    );
    expect(tree).toMatchSnapshot();
  });
});
