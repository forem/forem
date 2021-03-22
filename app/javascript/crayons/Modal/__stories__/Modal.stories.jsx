import { h } from 'preact';
import { useState } from 'preact/hooks';
import { withKnobs, text, boolean, select } from '@storybook/addon-knobs';
import notes from './modals.md';
import { Modal, Button } from '@crayons';
import '../../storybook-utilities/designSystem.scss';

export default {
  title: 'Components/Modals',
  decorator: [withKnobs],
  parameters: { notes },
};

export const Default = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsModalOpen(true)}>Open modal</Button>
      {isModalOpen && (
        <Modal
          onClose={() => setIsModalOpen(false)}
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
        >
          <p>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse
            odio est, ultricies vel euismod ut, fringilla quis tellus. Sed at
            dui mi. Fusce cursus nibh lectus, vitae lobortis orci volutpat quis.{' '}
          </p>
        </Modal>
      )}
    </div>
  );
};

Default.story = {
  name: 'Modals',
};
