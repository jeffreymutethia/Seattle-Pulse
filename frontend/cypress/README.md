# Cypress End-to-End Testing for Seattle Pulse

This directory contains the Cypress end-to-end tests for the Seattle Pulse frontend application.

## Authentication Testing

The current tests focus on the authentication flows:
- Signup process
- Login process
- Forgot password flow
- Email verification
- Form validations
- Auth popup behavior

## Running the Tests

### Open Cypress UI

To open the Cypress UI and run tests interactively:

```bash
npm run cypress:open
```

This will open the Cypress UI where you can select which tests to run.

### Run Headless Tests

To run all tests in headless mode:

```bash
npm run cypress:run
```

### Run with Development Server

To start the development server and run tests:

```bash
npm run test:e2e
```

This uses `start-server-and-test` to:
1. Start the Next.js development server
2. Wait for http://localhost:3000 to be available
3. Run Cypress tests
4. Shut down the server when tests complete

## Test Structure

- `auth.cy.ts`: Basic authentication tests
- `auth-flows.cy.ts`: Complete authentication flows with custom commands
- `spec.cy.ts`: Basic application loading test

## Custom Commands

Custom commands are defined in `cypress/support/commands.ts`:

- `cy.login(user)`: Performs a login with the provided credentials
- `cy.signup(user)`: Completes the signup form with the provided user data
- `cy.logout()`: Performs a logout action

## Notes for Developers

- The tests use randomly generated emails and usernames to avoid conflicts
- Some tests expect validation errors since we're working with test users
- Adjust selectors if the UI components change
- These tests are meant to verify UI flows, not actual authentication with the backend # Cypress Tests for Seattle Pulse Frontend

This directory contains end-to-end tests for the Seattle Pulse frontend application using Cypress.

## Setup

To run the tests, you need to:

1. Install the dependencies:
   ```bash
   npm install
   ```

2. Make sure your application is running locally on port 3000:
   ```bash
   npm run dev
   ```

## Running Tests

### Interactive Mode

To run tests in interactive mode with the Cypress Test Runner:

```bash
npm run cypress
```

### Headless Mode

To run tests in headless mode (CI/CD):

```bash
npm run cypress:headless
```

## Test Coverage

Currently, the following features are tested:

- **Waitlist Modal**
  - Submitting the waitlist form via sidebar button
  - Automatic display of waitlist modal after scrolling (for guest users)
  - Form validation and submission
  - Success state after submission

## Adding New Tests

To add new tests:

1. Create a new file in the `cypress/e2e` directory with the `.cy.ts` extension.
2. Follow the existing test patterns for consistency. If your test needs data, place it under `cypress/fixtures`.
3. Run your tests locally to verify they work:
   ```bash
   npx cypress open      # interactive mode
   npx cypress run       # headless mode
   ```
4. Commit the new spec and any fixtures after the tests pass.

For additional guidance, see the [Cypress documentation](https://docs.cypress.io/).
