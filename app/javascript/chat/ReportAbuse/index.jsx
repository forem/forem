import { h } from 'preact';
import PropTypes from 'prop-types';

function ReportAbuse({ resource: data }) {
  return (
    <div className="p4">
      <div className="p-4 grid gap-2 crayons-card mb-4">
        <h1 className="lh-tight mb-4 mt-0">Report Abuse</h1>
        <p>
          Thank you for reporting any abuse that violates our{' '}
          <a href="/code-of-conduct">code of conduct</a> or
          <a href="/terms">terms and conditions</a>. We continue to try to make
          this environment a great one for everybody.
        </p>
      </div>
      <div className="crayons-card crayons-card--secondary p-4 ">
        <div className="crayons-fields">
          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="rude or vulgar"
              id=""
              className="crayons-radio"
            />
            <label htmlFor="rude or vulgar" className="crayons-field__label">
              Rude or vulgar
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="harassment"
              id=""
              className="crayons-radio"
            />
            <label htmlFor="harassment" className="crayons-field__label">
              Harassment or hate speech
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input type="radio" name="spam" id="" className="crayons-radio" />
            <label htmlFor="spam" className="crayons-field__label">
              Spam or copyright issue
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input
              type="radio"
              name="listings"
              id=""
              className="crayons-radio"
            />
            <label htmlFor="listings" className="crayons-field__label">
              Inappropriate listings message/category
            </label>
          </div>

          <div className="crayons-field crayons-field--radio">
            <input type="radio" name="other" id="" className="crayons-radio" />
            <label htmlFor="other" className="crayons-field__label">
              other
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
          <button type="submit" name="commit" className="crayons-btn">
            Report Message
          </button>
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
