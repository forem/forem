import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import CogIcon from '@images/cog.svg';
import { Link } from '@crayons';

describe('<Link />', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(<Link>Hello world!</Link>);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders default link', () => {
    const { container } = render(<Link href="/url">Hello world!</Link>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders branded link', () => {
    const { container } = render(
      <Link variant="branded" href="/url">
        Hello world!
      </Link>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders block link', () => {
    const { container } = render(
      <Link block href="/url">
        Hello world!
      </Link>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders rounded link', () => {
    const { container } = render(
      <Link rounded href="/url">
        Hello world!
      </Link>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a link with icon alone', () => {
    const { container } = render(<Link icon={CogIcon} href="/url" />);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with icon and text', () => {
    const { container } = render(
      <Link icon={CogIcon} href="/url">
        Hello world!
      </Link>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with additional classnames', () => {
    const { container } = render(
      <Link className="one two three" href="/url">
        Hello world!
      </Link>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });
});
