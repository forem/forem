import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { AiDisclosureModal } from '../AiDisclosureModal';
import '@testing-library/jest-dom';

describe('<AiDisclosureModal />', () => {
  const baseProps = {
    isOpen: true,
    onClose: jest.fn(),
    onChange: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('lets the author dismiss it when disclosure is not required', () => {
    const { getByText } = render(<AiDisclosureModal {...baseProps} />);

    expect(getByText('Done')).not.toBeDisabled();
  });

  it('blocks Done until an answer is given when required', () => {
    const { getByText } = render(<AiDisclosureModal {...baseProps} required />);

    expect(getByText('Done')).toBeDisabled();
    expect(
      getByText(/Choose how AI was used before publishing/),
    ).toBeInTheDocument();
  });

  it('unblocks Done once a level is selected', () => {
    const { getByText, getByLabelText } = render(
      <AiDisclosureModal {...baseProps} required />,
    );

    fireEvent.click(getByLabelText('Some AI (AI-assisted)'));

    expect(getByText('Done')).not.toBeDisabled();
    expect(baseProps.onChange).toHaveBeenCalledWith(
      expect.objectContaining({
        target: { name: 'aiDisclosureLevel', value: 'some_ai' },
      }),
    );
  });

  it('accepts an explicit Not Disclosed as a valid answer', () => {
    const { getByText, getByLabelText } = render(
      <AiDisclosureModal {...baseProps} required />,
    );

    fireEvent.click(getByLabelText('Not Disclosed'));

    expect(getByText('Done')).not.toBeDisabled();
  });
});
