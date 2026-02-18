# Cypress End-to-End Testing for Seattle Pulse

This document explains the Cypress end-to-end test setup for the Seattle Pulse application.

## Overview

The test suite covers authentication flows including:
- User signup process
- Login flow
- Forgot password flow
- Email verification
- Form validations
- Auth popup behavior

## Setup and Configuration

The tests are configured in `cypress.config.ts` with the following features:
- Base URL set to http://localhost:3000
- Enhanced retry mechanisms for test stability
- Cross-browser testing support
- Extended timeouts for more reliable tests

## Running Tests

### Opening Cypress UI

```bash
# Open with default browser
npm run cypress:open

# Open with Firefox
npm run cypress:open:firefox

# Open with Electron
npm run cypress:open:electron
```

### Running Headless Tests

```bash
# Run with default browser
npm run cypress:run

# Run with Firefox
npm run cypress:run:firefox

# Run with Electron
npm run cypress:run:electron
```

### Running with Development Server

```bash
# Start dev server and run tests
npm run test:e2e

# Start dev server and run tests with Firefox
npm run test:e2e:firefox

# Start dev server and run tests with Electron
npm run test:e2e:electron
```

## Test Structure

The tests are organized into the following files:

- `cypress/e2e/spec.cy.ts`: Basic application loading test
- `cypress/e2e/auth.cy.ts`: Tests for authentication page navigation and form validation
- `cypress/e2e/auth-flows.cy.ts`: Tests for complete authentication flows using custom commands
- `cypress/e2e/auth-popup.cy.ts`: Tests for the authentication popup component

## Custom Commands

The tests use custom commands defined in `cypress/support/commands.ts`:

- `cy.login(user)`: Performs login with provided credentials
- `cy.signup(user)`: Completes signup form with provided user data
- `cy.logout()`: Performs logout action

## Troubleshooting

### Chrome Connection Issues

If you experience issues with Chrome, try using Firefox or Electron instead:

```bash
npm run cypress:open:firefox
```

or

```bash
npm run cypress:open:electron
```

### Test Failures

If tests fail due to not finding elements:

1. Check that selectors match your current application structure
2. Inspect the failure screenshots in the `cypress/screenshots` directory
3. Consider using more resilient selection strategies (like data-test attributes)

### Slow Test Execution

If tests run slowly:

1. Run in headless mode: `npm run cypress:run`
2. Disable video recording in cypress.config.ts
3. Run specific tests instead of the entire suite: `npx cypress run --spec "cypress/e2e/auth.cy.ts"`

## Best Practices

1. Use data-test attributes for test elements to make them resilient to UI changes
2. Keep tests independent of each other
3. Avoid writing tests that depend on the state from previous tests
4. Use environment variables for sensitive data
5. Keep tests focused on critical user flows 