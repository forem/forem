import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ModalBackground } from '../components/ModalBackground';

describe('<ModalBackground />', () => {
  const defaultProps = {
    onClick: () => {
      return 'onClick';
    },
  };

  it('should have no a11y violations', async () => {
    const { container } = render(<ModalBackground {...defaultProps} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByTestId } = render(<ModalBackground {...defaultProps} />);

    expect(queryByTestId('listings-modal-background')).toBeDefined();
  });

  it('should call the onClick handler', () => {
    const onClick = jest.fn();
    const { getByTestId } = render(
      <ModalBackground {...defaultProps} onClick={onClick} />,
    );

    const modalBackground = getByTestId('listings-modal-background');
    modalBackground.click();

    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
