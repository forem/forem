import { h, Fragment } from 'preact';
import { memo } from 'preact/compat';

/**
 * Component which renders the user metadata detail in a profile preview card.
 *
 * @param {string} email The user's email (if set to be publicly displayed)
 * @param {string} location The user's location
 * @param {string} created_at The user's join date string
 * @param {string} education The user's education detail
 * @param {string} employment_title The user's employment title, if provided
 * @param {string} employer_name The user's employer, if provided
 * @param {string} employer_url The user's employer URL, if provided
 */
const UserMetadata = ({
  email,
  location,
  summary,
  created_at,
  education,
  employment_title,
  employer_name,
  employer_url,
}) => {
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
          {employment_title && (
            <li>
              <div className="key">Work</div>
              <div className="value">
                {employment_title}
                {employer_name && <span class="opacity-50"> at </span>}
                {employer_name && employer_url && (
                  <a
                    href={employer_url}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {employer_name}
                  </a>
                )}
                {!employer_url && employer_name}
              </div>
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
};

export const MemoizedUserMetadata = memo(UserMetadata);
