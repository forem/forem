import { h } from 'preact';

const SnackBar = ({ archiving, isStatusViewValid }) => {
  if (archiving) {
    return (
      <div className="snackbar">
        {isStatusViewValid() ? 'Archiving...' : 'Unarchiving...'}
      </div>
    );
  }
};

export default SnackBar;
