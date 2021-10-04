import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import { Trans } from 'react-i18next';
import { reportAbuse, blockUser } from '../actions/requestActions';
import { addSnackbarItem } from '../../Snackbar';
import { i18next } from '@utilities/locale';
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
export function ReportAbuse({ data, closeReportAbuseForm }) {
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
      const confirmBlock = window.confirm(i18next.t('feedback.block'));

      if (confirmBlock) {
        const response = await blockUser(data.user_id);
        if (response.result === 'blocked') {
          addSnackbarItem({ message: i18next.t('feedback.blocked') });
        }
      } else {
        addSnackbarItem({ message: i18next.t('feedback.submitted') });
      }
      closeReportAbuseForm();
    } else {
      addSnackbarItem({ message });
    }
  };

  return (
    <Fragment>
      <section className="mt-7 p-4 grid gap-2 crayons-card mb-4">
        <h1 className="lh-tight mb-4 mt-0">{i18next.t('feedback.heading')}</h1>
        <p>
          <Trans i18nKey="feedback.desc"
            // eslint-disable-next-line react/jsx-key, jsx-a11y/anchor-has-content
            components={[<a href="/code-of-conduct" />, <a href="/terms" />]} />
        </p>
        <fieldset className="report__abuse-options p-4 justify-between">
          <legend>{i18next.t('feedback.why')}</legend>
          <FormField variant="radio">
            <RadioButton
              id="rude_or_vulgar"
              name="rude_or_vulgar"
              value="rude or vulgar"
              checked={category === 'rude or vulgar'}
              onClick={handleChange}
            />
            <label htmlFor="rude_or_vulgar" className="crayons-field__label">
              {i18next.t('feedback.rude_or_vulgar')}
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
              {i18next.t('feedback.harassment')}
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
              {i18next.t('feedback.spam')}
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
              {i18next.t('feedback.listings')}
            </label>
          </FormField>
          <h2>{i18next.t('feedback.message')}</h2>
          <div
            className="reported__message p-2 mt-2 mb-3"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: data.message }}
          />
          <Button disabled={category === null} size="s" onClick={handleSubmit}>
            {i18next.t('feedback.report_message')}
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
