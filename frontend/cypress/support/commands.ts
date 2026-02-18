/// <reference types="cypress" />

declare global {
  namespace Cypress {
    interface Chainable {
      login(user: { email: string; password: string }): Chainable<void>;
      signup(user: {
        firstName: string;
        lastName: string;
        username: string;
        email: string;
        password: string;
        location: string;
      }): Chainable<void>;
      logout(): Chainable<void>;
    }
  }
}

// cypress/support/commands.ts
Cypress.Commands.add('login', ({ email, password }) => {
  // 1) Visit the login page
  cy.visit('/auth/login');

  // 2) Fill in and submit
  cy.get('input[name="email"]', { timeout: 10000 }).should('be.visible').type(email);
  cy.get('input[name="password"]').type(password);
  cy.contains('button', 'Login').click();

  // 3) Wait for redirect to home page (root route)
  cy.url({ timeout: 10000 }).should('eq', Cypress.config().baseUrl + '/');
});

// Signup command - simplified, doesn't wait for email verification
Cypress.Commands.add('signup', (user) => {
  cy.visit('/auth/signup');

  cy.get('input[name="firstName"]', { timeout: 10000 }).should('be.visible').type(user.firstName);
  cy.get('input[name="lastName"]').type(user.lastName);
  cy.get('input[name="username"]').type(user.username);
  // Signup form uses emailOrPhoneNumber, not email
  cy.get('input[name="emailOrPhoneNumber"]').type(user.email);
  cy.get('input[name="password"]').type(user.password);
  cy.get('input[name="confirmPassword"]').type(user.password);

  // ✅ Interact with AsyncSelect
  cy.get('.select__control').click().type('Seattle');

  // Wait for and select an option
  cy.get('.select__menu').should('be.visible');
  cy.get('.select__option').first().click();

  // Agree to terms
  cy.get('input[name="terms"]').check({ force: true });

  // Submit the form
  cy.contains('button', 'Create Account').click();
  
  // Just verify form was submitted - don't wait for email verification redirect
  // since that requires actual email sending
});

// Logout command
Cypress.Commands.add('logout', () => {
  // This is a placeholder - adjust based on your app's logout functionality
  cy.get('header').find('button[aria-label="User menu"]').click();
  cy.contains('Logout').click();
});

export {}; 