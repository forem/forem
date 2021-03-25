import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';

import { NextPageButton } from '../components/NextPageButton';

describe('<NextPageButton />', () => {
  const defaultProps = {
    onClick: () => {
      return 'onClick';
    },
  };

  it('should have no a11y violations', async () => {
    const { container } = render(<NextPageButton {...defaultProps} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should show a button', () => {
    const { queryByText } = render(<NextPageButton {...defaultProps} />);

    expect(queryByText(/load more/i)).toBeDefined();
  });

  it('should call the onclick handler', () => {
    const onClick = jest.fn();
    const { getByText } = render(<NextPageButton onClick={onClick} />);
    const button = getByText(/load more/i);

    button.click();
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
