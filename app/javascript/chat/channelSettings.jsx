import { h } from 'preact';
import PropTypes from 'prop-types';

const ChannelSetting = ({ resource: data }) => {
  return (
    <div className="activechatchannel__activeArticle">
      <div className="p-4">
        <div className="p-4 grid gap-2 crayons-card mb-4 channel_details">
          <h1 class="mb-1">Sarthak-test</h1>
          <p>
            Lorem ipsum dolor sit amet consectetur, adipisicing elit. Et natus
            error illum nesciunt recusandae autem odio expedita impedit atque.
            Voluptatibus.
          </p>
          <p class="fw-bold">You are a channel mod</p>
        </div>
        <div className="p-4 grid gap-2 crayons-card mb-4">
          <h3 class="mb-2">Members</h3>
        </div>
      </div>
    </div>
  );
};

ChannelSetting.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
};
export default ChannelSetting;
