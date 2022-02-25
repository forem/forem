describe('Toggling feature flags', () => {
  function checkFeatureFlag(flag, expected) {
    return cy
      .request('GET', `/api/feature_flags?flag=${flag}`)
      .should((response) => {
        expect(response.body).to.deep.equal({ [flag]: expected });
      });
  }

  it('toggles and verifies feature flags', () => {
    const flag = 'test_feature_flag';
    checkFeatureFlag(flag, false);
    cy.enableFeatureFlag(flag);
    checkFeatureFlag(flag, true);
    cy.disableFeatureFlag(flag);
    checkFeatureFlag(flag, false);
  });
});
