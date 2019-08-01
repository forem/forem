export const baseURL = 'http://localhost:3000/';

export function eyesOpen(testName) {
  cy.eyesOpen({
    appName: 'Dev.To',
    testName: testName,
    browser: { width: 800, height: 600, name: 'chrome' },
  });
}
