import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { FormField, RadioButton } from '@crayons';

describe('<FormField /> component', () => {
  it('should have no a11y violations when rendered', async () => {
    const { container } = render(<FormField />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when rendered with content', async () => {
    const { container } = render(
      <FormField>
        {' '}
        <RadioButton id="some-id" value="some-value" name="some-name" />
        <label htmlFor="some-id">Some Label</label>
      </FormField>,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { container } = render(<FormField />);
    expect(container).toMatchSnapshot();
  });

  it('should render with content', () => {
    const { container } = render(
      <FormField>
        <RadioButton id="some-id" value="some-value" name="some-name" />
        <label htmlFor="some-id">Some Label</label>
      </FormField>,
    );
    expect(container).toMatchSnapshot();
  });
});
