import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import { reportAbuse } from '../actions/requestActions';
import { addSnackbarItem } from '../../Snackbar';
import { Button } from '@crayons';

function ReportAbuse({ resource: data }) {
  const [category, setCategory] = useState(null);

  const handleChange = (e) => {
    setCategory(e.target.value);
  };

  const handleSubmit = async () => {
    const response = await reportAbuse(
      data.message,
      'connect',
      category,
      data.user_id,
    );
    const { success, message } = response;
    if (success) {
      const confirmBlock = window.confirm(
        `Are you sure you want to block this person? This will:
      - prevent them from commenting on your posts
      - block all notifications from them
      - prevent them from messaging you via DEV Connect`,
      );
      if (confirmBlock) {
        fetch(`/user_blocks`, {
          method: 'POST',
          headers: {
            Accept: 'application/json',
            'X-CSRF-Token': window.csrfToken,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            user_block: {
              blocked_id: data.user_id,
            },
          }),
        }).then((response) => response.json());
      }
    } else {
      addSnackbarItem({ message });
    }
  };

  return (
    <div className="p4">
      <div className="p-4 grid gap-2 crayons-card mb-4">
        <h1 className="lh-tight mb-4 mt-0">Report Abuse</h1>
        <p>
          Thank you for reporting any abuse that violates our{' '}
          <a href="/code-of-conduct">code of conduct</a> or
          <a href="/terms">terms and conditions</a>. We continue to try to make
          environment a great one for everybody.
        </p>
      </div>
      <div className="crayons-card crayons-card--secondary p-4">
        <div className="crayons-fields">
          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="rude or vulgar"
              value="rude or vulgar"
              className="crayons-radio"
              checked={category === 'rude or vulgar'}
              onChange={handleChange}
              aria-label="rude or vulgar"
            />
            <label htmlFor="rude or vulgar" className="crayons-field__label">
              Rude or vulgar
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="harassment"
              value="harassment"
              className="crayons-radio"
              checked={category === 'harassment'}
              onChange={handleChange}
              aria-label="harassment"
            />
            <label htmlFor="harassment" className="crayons-field__label">
              Harassment or hate speech
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="spam"
              value="spam"
              className="crayons-radio"
              checked={category === 'spam'}
              onChange={handleChange}
              aria-label="spam"
            />
            <label htmlFor="spam" className="crayons-field__label">
              Spam or copyright issue
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="listings"
              value="listings"
              className="crayons-radio"
              checked={category === 'listings'}
              onChange={handleChange}
              aria-label="listings"
            />
            <label htmlFor="listings" className="crayons-field__label">
              Inappropriate listings message/category
            </label>
          </div>
        </div>
        <p className="reported__message__section"> Reported Message</p>
        <div className="reported__message">
          <span
            className="chatmessagebody__message"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: data.message }}
          />
        </div>
        <div>
          <Button className="m-2" size="s" onClick={handleSubmit}>
            Report Message
          </Button>
        </div>
      </div>
    </div>
  );
}

ReportAbuse.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
};

export default ReportAbuse;
