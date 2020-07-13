import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import Tags from '../tags';

describe('<Tags />', () => {
  beforeAll(() => {
    const environment = document.createElement('meta');
    environment.setAttribute('name', 'environment');
    document.body.appendChild(environment);
  });

  it('should have no a11y violations', async () => {
    const { container } = render(<Tags defaultValue="defaultValue" listing />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('handleKeyDown', () => {
    it('calls preventDefault on unused keyCode', () => {
      const { getByTestId } = render(
        <Tags defaultValue="defaultValue" listing />,
      );

      Event.prototype.preventDefault = jest.fn();

      fireEvent.keyDown(getByTestId('tag-input'), {
        key: '§',
        code: '192',
      });

      expect(Event.prototype.preventDefault).toHaveBeenCalledTimes(1);
    });

    it('does not call preventDefault on used keyCode', () => {
      const { getByTestId } = render(
        <Tags defaultValue="defaultValue" listing />,
      );

      Event.prototype.preventDefault = jest.fn();

      const tests = [
        { key: 'a', code: '65' },
        { key: '1', code: '49' },
        { key: ',', code: '188' },
        { key: 'Enter', code: '13' },
      ];

      tests.forEach((eventPayload) => {
        fireEvent.keyDown(getByTestId('tag-input'), eventPayload);
      });

      expect(Event.prototype.preventDefault).not.toHaveBeenCalled();
    });
  });
});
