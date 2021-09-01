import { h } from 'preact';
import { useState } from 'preact/hooks';
import notes from './drawers.md';
import { MobileDrawer, Button } from '@crayons';

export default {
  title: 'Components/MobileDrawer',
  parameters: { notes },
};

export const Default = () => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsDrawerOpen(true)}>Open drawer</Button>
      {isDrawerOpen && (
        <MobileDrawer
          title="Example MobileDrawer"
          onClose={() => setIsDrawerOpen(false)}
        >
          <h2 className="mb-4">Lorem ipsum</h2>
          <Button onClick={() => setIsDrawerOpen(false)}>OK</Button>
        </MobileDrawer>
      )}
    </div>
  );
};

Default.story = {
  name: 'MobileDrawer',
};
