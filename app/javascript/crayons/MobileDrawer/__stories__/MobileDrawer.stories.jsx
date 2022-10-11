import { h } from 'preact';
import { useState } from 'preact/hooks';
import Notes from './drawers.mdx';
import { MobileDrawer, ButtonNew as Button } from '@crayons';

export default {
  title: 'BETA/MobileDrawer',
  parameters: {
    docs: {
      page: Notes,
    },
  },
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

Default.storyName = 'MobileDrawer';
