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
      const { getAllByTestId } = render(
        <Tags defaultValue="defaultValue" listing />,
      );

      // https://stackoverflow.com/questions/60455119/react-jest-test-preventdefault-action
      const isPrevented = fireEvent.keyDown(getAllByTestId('tag-input')[0], {
        key: '§',
        code: '192',
      });
      expect(isPrevented).toEqual(false);
    });

    it('does not call preventDefault on used keyCode', () => {
      const { getAllByTestId } = render(
        <Tags defaultValue="defaultValue" listing />,
      );

      // https://stackoverflow.com/questions/60455119/react-jest-test-preventdefault-action
      const tests = [
        { key: 'a', code: '65' },
        { key: '1', code: '49' },
        { key: ',', code: '188' },
        { key: 'Enter', code: '13' },
      ];

      tests.forEach((obj) => {
        const isPrevented = fireEvent.keyDown(
          getAllByTestId('tag-input')[0],
          obj,
        );
        expect(isPrevented).toEqual(true);
      });
    });
  });
});
