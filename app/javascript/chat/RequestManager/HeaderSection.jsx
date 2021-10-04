import { h } from 'preact';
import { Trans } from 'react-i18next';

export const HeaderSection = ({}) => (
  <div className="request_manager_header crayons-card mb-6 grid grid-flow-row gap-6 p-6">
    <h1>
      <Trans i18nKey="chat.join.heading"
        // eslint-disable-next-line react/jsx-key
        components={[<span role="img" aria-label="handshake" />]} />
    </h1>
  </div>
);
