const loadActionsPanel = async () => {
  const { initializeActionsPanel } = await import(
    '../actionsPanel/actionsPanel'
  );

  initializeActionsPanel();
};

loadActionsPanel();
