describe('Seattle Pulse App', () => {
  it('loads the homepage', () => {
    cy.visit('/');
    cy.title().should('include', 'Seattle');
    cy.get('body').should('be.visible');
  });
});