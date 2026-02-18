// ***********************************************************
// This file can be used to load additional commands to Cypress
// ***********************************************************

/// <reference types="cypress" />

// Import commands.js using ES2015 syntax
import './commands'

// Cypress global types
declare global {
  namespace Cypress {
    interface Chainable {
      // Add custom commands here if needed
    }
  }
} 