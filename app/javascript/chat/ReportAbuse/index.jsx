import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import { reportAbuse, blockUser } from '../actions/requestActions';
import { addSnackbarItem } from '../../Snackbar';
import { Button, FormField, RadioButton } from '@crayons';

/**
 * This component render the report abuse
 *
 * @param {object} props
 * @param {object} props.data
 * @param {object} props.closeReportAbuseForm
 *
 * @component
 *
 * @example
 *
 * <ReportAbuse
 *  data={data}
 *  closeReportAbuseForm={closeReportAbuseForm}
 * />
 *
 */
function ReportAbuse({ data, closeReportAbuseForm }) {
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
        const response = await blockUser(data.user_id);
        if (response.result === 'blocked') {
          addSnackbarItem({
            message: 'Your report has been submitted and User has been blocker',
          });
        }
      } else {
        addSnackbarItem({ message: 'Your report has been submitted.' });
      }
      closeReportAbuseForm();
    } else {
      addSnackbarItem({ message });
    }
  };

  return (
    <div>
      <section className="p-4 grid gap-2 crayons-card mb-4">
        <h1 className="lh-tight mb-4 mt-0">Report Abuse</h1>
        <p>
          Thank you for reporting any abuse that violates our{' '}
          <a href="/code-of-conduct">code of conduct</a> or
          <a href="/terms">terms and conditions</a>. We continue to try to make
          environment a great one for everybody.
        </p>
      </section>
      <section className="crayons-card crayons-card--secondary p-4 justify-between">
        <FormField variant="radio">
          <RadioButton
            id="rude_or_vulgar"
            name="rude_or_vulgar"
            value="rude or vulgar"
            checked={category === 'rude or vulgar'}
            onClick={handleChange}
            data-testid="rude_or_vulgar"
          />
          <label
            htmlFor="rude_or_vulgar"
            className="crayons-field__label mb-4"
            aria-label="rude of vulgar"
          >
            Rude or vulgar
          </label>
        </FormField>

        <FormField variant="radio">
          <RadioButton
            id="harassment"
            name="harassment"
            value="harassment"
            checked={category === 'harassment'}
            onClick={handleChange}
            data-testid="harassment"
          />
          <label
            htmlFor="harassment"
            className="crayons-field__label mb-4"
            aria-label="Harassment or hate speech"
          >
            Harassment or hate speech
          </label>
        </FormField>

        <FormField variant="radio">
          <RadioButton
            id="spam"
            name="spam"
            value="spam"
            checked={category === 'spam'}
            onClick={handleChange}
            data-testid="spam"
          />
          <label
            htmlFor="spam"
            className="crayons-field__label mb-4"
            aria-label="Spam or copyright issue"
          >
            Spam or copyright issue
          </label>
        </FormField>

        <FormField variant="radio">
          <RadioButton
            id="listings"
            name="listings"
            value="listings"
            checked={category === 'listings'}
            onClick={handleChange}
            data-testid="listings"
          />
          <label
            htmlFor="listings"
            className="crayons-field__label mb-4"
            aria-label="Inappropriate listings message/category"
          >
            Inappropriate listings message/category
          </label>
        </FormField>
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
      </section>
    </div>
  );
}

ReportAbuse.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.shape({
      user_id: PropTypes.number.isRequired,
      message: PropTypes.element.isRequired,
    }),
  }).isRequired,
};

export default ReportAbuse;
