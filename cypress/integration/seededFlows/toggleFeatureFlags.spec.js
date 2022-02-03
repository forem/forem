describe('Toggling feature flags', () => {
  it('toggles and verifies feature flags', () => {
    const flag = 'test_feature_flag';
    cy.checkFeatureFlag(flag, false);
    cy.enableFeatureFlag(flag);
    cy.checkFeatureFlag(flag, true);
    cy.disableFeatureFlag(flag);
    cy.checkFeatureFlag(flag, false);
  });
});
