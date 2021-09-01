import { h, Fragment } from 'preact';
import { memo } from 'preact/compat';

/**
 * Component which renders the user metadata detail in a profile preview card.
 *
 * @param {object} props
 * @param {string} props.email The user's email (if set to be publicly displayed)
 * @param {string} props.location The user's location
 * @param {string} props.created_at The user's join date string
 * @param {string} props.education The user's education detail
 * @param {string} props.work The user's work details
 */
export const UserMetadata = memo(
  ({ email, location, summary, created_at, education, work }) => {
    const joinedOnDate = new Date(created_at);
    const joinedOnDateString = new Intl.DateTimeFormat(
      navigator.language || 'default',
      {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
      },
    ).format(joinedOnDate);

    return (
      <Fragment>
        {summary && <div className="color-base-70">{summary}</div>}
        <div className="user-metadata-details">
          <ul class="user-metadata-details-inner">
            {email && (
              <li>
                <div class="key">Email</div>
                <div class="value">
                  <a href={`mailto:${email}`}>{email}</a>
                </div>
              </li>
            )}
            {work && (
              <li>
                <div className="key">Work</div>
                <div className="value">{work}</div>
              </li>
            )}
            {location && (
              <li>
                <div class="key">Location</div>
                <div class="value">{location}</div>
              </li>
            )}
            {education && (
              <li>
                <div class="key">Education</div>
                <div class="value">{education}</div>
              </li>
            )}
            <li>
              <div class="key">Joined</div>
              <div class="value">
                <time datetime={created_at} class="date">
                  {joinedOnDateString}
                </time>
              </div>
            </li>
          </ul>
        </div>
      </Fragment>
    );
  },
);
