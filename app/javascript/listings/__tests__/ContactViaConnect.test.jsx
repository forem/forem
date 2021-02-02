import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ContactViaConnect } from '../components/ContactViaConnect';

describe('<ContactViaConnect />', () => {
  it('should have no a11y violations', async () => {
    const onChange = jest.fn;
    const { container } = render(
      <ContactViaConnect onChange={onChange} checked />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render a checked check box opting in to open DMs', () => {
    const onChange = jest.fn();
    const { getByText } = render(
      <ContactViaConnect onChange={onChange} checked />,
    );

    expect(getByText('Allow Users to message me via Connect.')).toBeDefined();
  });

  it('should fire a change event when clicking the checkbox', () => {
    const onChange = jest.fn();
    const { getByText } = render(
      <ContactViaConnect onChange={onChange} checked />,
    );

    const checkbox = getByText('Allow Users to message me via Connect.');

    fireEvent.click(checkbox);

    expect(onChange).toHaveBeenCalledTimes(1);
  });
});
