import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { CTA } from '@crayons';

describe('<CTA />', () => {
  it('has no accessibility errors in default style', async () => {
    const { container } = render(<CTA>Hello world!</CTA>);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has no accessibility errors in branded style', async () => {
    const { container } = render(<CTA style="branded">Hello world!</CTA>);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders default CTA', () => {
    const { container } = render(<CTA>Hello world!</CTA>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders branded CTA', () => {
    const { container } = render(<CTA style="branded">Hello world!</CTA>);
    expect(container.innerHTML).toMatchSnapshot();
  });
});
