import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import BodyMarkdown from '../components/BodyMarkdown';

describe('<BodyMarkdown />', () => {
  const getProps = () => ({
    onChange: () => {
      return 'onChange';
    },
    default: 'defaultValue',
  });
  it('should have no a11y violations', async () => {
    const { container } = render(<BodyMarkdown {...getProps()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const defaultValue = 'some default value';
    const props = {
      onChange: jest.fn(),
      defaultValue,
    };

    const { getByLabelText } = render(<BodyMarkdown {...props} />);

    const textArea = getByLabelText('Body Markdown');

    expect(textArea.getAttribute('placeholder')).toEqual(
      '400 characters max, 12 line break max, no images allowed, *markdown is encouraged*',
    );
    expect(textArea.getAttribute('maxLength')).toEqual('400');
    expect(textArea.value).toEqual(defaultValue);
  });

  it('should call change handler', () => {
    const defaultValue = 'some default value';
    const onChange = jest.fn();
    const props = {
      onChange,
      defaultValue,
    };
    const { getByLabelText } = render(<BodyMarkdown {...props} />);
    const textArea = getByLabelText('Body Markdown');

    fireEvent.input(textArea, { target: { value: 'changing the value' } });

    expect(onChange).toHaveBeenCalledTimes(1);
  });
});
