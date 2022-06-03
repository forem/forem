import { h } from 'preact';
import { render, screen, waitFor } from '@testing-library/preact';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';
import { FlagUserModal } from '../packs/flagUserModal';
import { request } from '../utilities/http';
import { showSnackbarItem } from './utils';

jest.mock('../utilities/http', () => ({ request: jest.fn() }));
jest.mock('./utils', () => ({
  changeFlagUserButtonLabel: jest.fn(),
  toggleFlagUserModal: jest.fn(),
  showSnackbarItem: jest.fn(),
}));

const requestMock = (outcomeResult = null) => {
  request.mockImplementation(() => {
    return {
      json: () => Promise.resolve({ result: outcomeResult }),
    };
  });
};

const setup = ({ modCenterArticleUrl, authorId, flaggedUser }) => {
  return render(
    <FlagUserModal
      modCenterArticleUrl={modCenterArticleUrl}
      authorId={authorId}
      flaggedUser={flaggedUser}
    />,
  );
};

describe('<FlagUserModal />', () => {
  beforeEach(jest.clearAllMocks);

  describe('When article author is unflagged', () => {
    it('should render Flag User modal title', async () => {
      setup({ modCenterArticleUrl: '/', authorId: 12, flaggedUser: false });

      expect(screen.getByText('Flag User')).toBeInTheDocument();
    });

    it('should render Report other inappropriate conduct link', async () => {
      setup({ modCenterArticleUrl: '/', authorId: 12, flaggedUser: false });

      const link = screen.getByText('Report other inappropriate conduct');

      expect(link).toBeInTheDocument();
    });

    describe('When Make all posts by this author less visible radio button is clicked', () => {
      it('should render Confirm button not disabled', async () => {
        setup({ modCenterArticleUrl: '/', authorId: 12, flaggedUser: false });

        const radioButton = screen.getByLabelText(
          'Make all posts by this author less visible',
        );
        const confirmActionButton = screen.getByText('Confirm action');

        expect(confirmActionButton).toBeDisabled();

        userEvent.click(radioButton);

        await waitFor(() => {
          expect(confirmActionButton).toBeEnabled();
        });
      });
    });
  });

  describe('When article author is flagged', () => {
    it('should render Unflag User modal title', async () => {
      setup({ modCenterArticleUrl: '/', authorId: 12, flaggedUser: true });

      expect(screen.getByText('Unflag User')).toBeInTheDocument();
    });

    it('should render Confirm button not disabled', async () => {
      setup({ modCenterArticleUrl: '/', authorId: 12, flaggedUser: true });

      const confirmActionButton = screen.getByText('Confirm action');

      expect(confirmActionButton).toBeEnabled();
    });
  });

  describe('When Confirm action button is clicked', () => {
    describe('When user is flagged', () => {
      it("calls showSnackbarItem with message 'This article author was unflagged.'", async () => {
        requestMock('destroy');

        setup({
          modCenterArticleUrl: '/',
          authorId: 12,
          flaggedUser: true,
        });

        const confirmActionButton = screen.getByText('Confirm action');

        userEvent.click(confirmActionButton);

        await waitFor(() => {
          expect(showSnackbarItem).toBeCalledWith(
            'This article author was unflagged.',
          );
        });
      });
    });

    describe('When user is unflagged', () => {
      it("calls showSnackbarItem with message 'All posts by this author will be less visible.'", async () => {
        requestMock('create');

        setup({
          modCenterArticleUrl: '/',
          authorId: 12,
          flaggedUser: false,
        });

        const radioButton = screen.getByRole('radio');
        const confirmActionButton = screen.getByText('Confirm action');

        userEvent.click(radioButton);

        await waitFor(() => {
          userEvent.click(confirmActionButton);

          expect(showSnackbarItem).toBeCalledWith(
            'All posts by this author will be less visible.',
          );
        });
      });
    });
  });
});
