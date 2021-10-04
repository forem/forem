import { h } from 'preact';
import { i18next } from '../../i18n/l10n';

export const HeaderSection = ({}) => (
  <div className="request_manager_header crayons-card mb-6 grid grid-flow-row gap-6 p-6">
    <h1
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: i18next.t('chat.join.heading') }}
    />
  </div>
);
