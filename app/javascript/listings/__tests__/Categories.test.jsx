import { h } from 'preact';
import { render, screen } from '@testing-library/preact';
import { Categories } from '../components/Categories';
import '@testing-library/jest-dom';

const defaultProps = {
  categoriesForSelect: [['Conference CFP (1 Credit)', 'cfp', '1']],
  categoriesForDetails: [
    {
      name: 'Conference CFP',
      rules: 'categories_rule',
    },
  ],
  categoryId: 0,
  onChange: jest.fn(),
};

const setup = (props = defaultProps) => {
  return render(<Categories {...props} />);
};

describe('<Categories />', () => {
  describe('With selected option', () => {
    beforeEach(() => {
      setup({
        ...defaultProps,
        categoryId: '1',
      });
    });
    it('should render selected option', () => {
      const optionName = defaultProps.categoriesForSelect[0][0];
      const option = screen.getByRole('option', { name: optionName });
      expect(option.selected).toStrictEqual(true);
    });
  });
  describe('Without selected option', () => {
    beforeEach(setup);

    it('should render select input', () => {
      const selectInput = screen.getByRole('combobox', { name: /category/i });
      const optionName = defaultProps.categoriesForSelect[0][0];
      const option = screen.getByRole('option', { name: optionName });

      expect(selectInput).toBeInTheDocument();
      expect(option).toBeInTheDocument();
    });

    it('should render category details', () => {
      expect(screen.getByText('Conference CFP:')).toBeInTheDocument();
      expect(screen.getByText('Category details/rules')).toBeInTheDocument();
    });
  });
});
