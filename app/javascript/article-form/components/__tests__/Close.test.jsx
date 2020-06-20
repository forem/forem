import { h } from 'preact';
import { render } from '@testing-library/preact';
import { Close } from '../Close';

describe('<Close />', () => {
  it('shows the close button', () => {
    const { getByTitle } = render(<Close />);
    getByTitle(/Close the editor/i, { selector: 'button' });
  });
});
