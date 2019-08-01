import { baseURL, eyesOpen } from '../../utils';
describe('Visual  Regression Tests', () => {
  beforeEach(() => {
    cy.visit(baseURL + '/mingschiller');
    eyesOpen('Feed Page');
  });
  afterEach(() => {
    cy.eyesClose();
  });

  it('should open a feed', () => {
    cy.eyesCheckWindow('Open Feed');
  });
});
