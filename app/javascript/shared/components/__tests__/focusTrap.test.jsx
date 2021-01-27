import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';

import FocusTrap from '../focusTrap';

describe('<FocusTrap />', () => {
  it('should trap focus within crayon-modals', async () => {
    const { getByTestId } = render(
      <div>
        <input type="text " />
        <FocusTrap>
          <div class="crayons-modal">
            <input type="text" data-testid="firstInput" />
            <input type="text" />
          </div>
        </FocusTrap>
      </div>,
    );

    const firstInput = getByTestId('firstInput');
    firstInput.focus();
    userEvent.tab();
    userEvent.tab();

    expect(firstInput).toHaveFocus();
  });
});
