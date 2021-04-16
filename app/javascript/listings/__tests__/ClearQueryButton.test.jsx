import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ClearQueryButton } from '../components/ClearQueryButton';

describe('<ClearQueryButton />', () => {
  it('has no a11y violations', async () => {
    const { container } = render(<ClearQueryButton onClick={jest.fn()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should fire a click event when pressed', () => {
    const onClickHandler = jest.fn();
    const { getByText } = render(<ClearQueryButton onClick={onClickHandler} />);
    const button = getByText('×');

    button.click();

    expect(onClickHandler).toHaveBeenCalledTimes(1);
  });
});
