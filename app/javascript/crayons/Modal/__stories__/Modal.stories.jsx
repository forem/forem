import { h } from 'preact';
import { withKnobs, text, boolean, select } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import notes from './modals.md';
import { Modal, Button } from '@crayons';
import '../../storybook-utilities/designSystem.scss';

export default {
  title: 'Components/Modals',
  decorator: [withKnobs],
  parameters: { notes },
};

const commonProps = {
  onClose: action('close fired'),
};

export const Default = () => (
  <div>
    {/* TODO: add a trigger that will change component state... */}
    <Button>Open modal</Button>
    <Modal
      size={select(
        'size',
        {
          Small: 's',
          Medium: 'm',
          Default: 'default',
        },
        'default',
      )}
      className={text('className')}
      title={text('title', 'This is my Modal title')}
      overlay={boolean('overlay', true)}
      {...commonProps}
    >
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse
        odio est, ultricies vel euismod ut, fringilla quis tellus. Sed at dui
        mi. Fusce cursus nibh lectus, vitae lobortis orci volutpat quis.{' '}
      </p>
    </Modal>
  </div>
);

Default.story = {
  name: 'Modals',
};
