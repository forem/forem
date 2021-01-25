import { h, Fragment } from 'preact';
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
 * @param {function} props.closeReportAbuseForm
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
        `The message will be reported.\n\nWould you like to block this person as well?\n\nThis will:
      - prevent them from commenting on your posts
      - block all notifications from them
      - prevent them from messaging you via chat`,
      );

      if (confirmBlock) {
        const response = await blockUser(data.user_id);
        if (response.result === 'blocked') {
          addSnackbarItem({
            message:
              'Your report has been submitted and the user has been blocked',
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
    <Fragment>
      <section className="mt-7 p-4 grid gap-2 crayons-card mb-4">
        <h1 className="lh-tight mb-4 mt-0">Report Abuse</h1>
        <p>
          Thank you for reporting any abuse that violates our{' '}
          <a href="/code-of-conduct">code of conduct</a> or{' '}
          <a href="/terms">terms and conditions</a>. We continue to try to make
          this environment a great one for everybody.
        </p>
        <fieldset className="report__abuse-options p-4 justify-between">
          <legend>Why is this content inappropriate?</legend>
          <FormField variant="radio">
            <RadioButton
              id="rude_or_vulgar"
              name="rude_or_vulgar"
              value="rude or vulgar"
              checked={category === 'rude or vulgar'}
              onClick={handleChange}
            />
            <label htmlFor="rude_or_vulgar" className="crayons-field__label">
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
            />
            <label htmlFor="harassment" className="crayons-field__label">
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
            />
            <label htmlFor="spam" className="crayons-field__label">
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
            />
            <label htmlFor="listings" className="crayons-field__label">
              Inappropriate listings message/category
            </label>
          </FormField>
          <h2>Message to Report</h2>
          <div
            className="reported__message p-2 mt-2 mb-3"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: data.message }}
          />
          <Button disabled={category === null} size="s" onClick={handleSubmit}>
            Report Message
          </Button>
        </fieldset>
      </section>
    </Fragment>
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
