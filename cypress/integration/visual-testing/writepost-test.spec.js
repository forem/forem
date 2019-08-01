import { baseURL, eyesOpen } from '../../utils';
describe('Visual  Regression Tests', () => {
  beforeEach(() => {
    cy.visit(baseURL + '/new');
    eyesOpen('Post Page');
  });
  afterEach(() => {
    cy.eyesClose();
  });

  it('should open the write post page', () => {
    cy.eyesCheckWindow('Post Page');
  });
});
