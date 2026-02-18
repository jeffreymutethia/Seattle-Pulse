describe('Feed Page Interactions', () => {
  beforeEach(() => {
    cy.clearCookies();
    cy.clearLocalStorage();
    cy.window().then(win => win.sessionStorage.clear());

    // use your custom login
    cy.login({
      email: 'user100@example.com',
      password: 'Strong1!',
    });
  });

  it('should navigate to the root route', () => {
    cy.url().should('eq', Cypress.config().baseUrl + '/');
  });
});
