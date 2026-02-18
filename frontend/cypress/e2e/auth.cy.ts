// describe('Authentication Flow', () => {
//   const testUser = {
//     firstName: 'Test',
//     lastName: 'User',
//     username: `testuser_${Date.now()}`,
//     email: `testuser_${Date.now()}@example.com`,
//     password: 'TestPassword1!',
//     location: 'Seattle, WA, USA'
//   };

//   beforeEach(() => {
//     // Clear cookies and local storage between tests
//     cy.clearCookies();
//     cy.clearLocalStorage();
//     cy.window().then((win) => {
//       win.sessionStorage.clear();
//     });
//   });

//   it('should load the homepage', () => {
//     cy.visit('/');
//     cy.get('body').should('be.visible');
//     cy.title().should('include', 'Seattle');
//   });

//   it('should navigate to the login page', () => {
//     cy.visit('/auth/login');
//     cy.url().should('include', '/auth/login');
//     cy.contains('Login - Welcome Back!').should('be.visible');
    
//     // Verify form elements exist
//     cy.get('input[name="email"]').should('be.visible');
//     cy.get('input[name="password"]').should('be.visible');
//     cy.contains('button', 'Login').should('be.visible');
    
//     // Verify social login buttons
//     cy.contains('button', 'Login with Google').should('be.visible');
//     cy.contains('button', 'Login with Facebook').should('be.visible');
//     cy.contains('button', 'Login with Apple').should('be.visible');
//   });

//   it('should navigate to the signup page', () => {
//     cy.visit('/auth/signup');
//     cy.url().should('include', '/auth/signup');
//     cy.contains('Sign Up').should('be.visible');
    
//     // Verify form elements exist
//     cy.get('input[name="firstName"]').should('be.visible');
//     cy.get('input[name="lastName"]').should('be.visible');
//     cy.get('input[name="username"]').should('be.visible');
//     cy.get('input[name="email"]').should('be.visible');
//     cy.get('input[name="password"]').should('be.visible');
//     cy.get('input[name="confirmPassword"]').should('be.visible');
//   });

//   it('should navigate to the forgot password page', () => {
//     cy.visit('/auth/forgot-password');
//     cy.url().should('include', '/auth/forgot-password');
//     cy.get('body').contains('Recover Password').should('be.visible');
    
//     // Verify form elements exist
//     cy.get('input[name="email"]').should('be.visible');
//     cy.contains('button', 'Send reset link').should('be.visible');
//   });

//   it('should handle login form validation', () => {
//     cy.visit('/auth/login');
    
//     // Submit empty form
//     cy.contains('button', 'Login').click();
    
//     // Check for validation errors
//     cy.contains('Invalid email address').should('be.visible');
//     cy.contains('Password is required').should('be.visible');
    
//     // Enter invalid email
//     cy.get('input[name="email"]').type('notanemail');
//     cy.contains('button', 'Login').click();
    
//     // Check for validation errors
//     cy.contains('Invalid email address').should('be.visible');
//   });

//   it('should handle signup form validation', () => {
//     cy.visit('/auth/signup');
    
//     // Submit empty form
//     cy.contains('button', 'Create Account').click();
    
//     // Check for validation errors
//     cy.contains('First name is required').should('be.visible');
//     cy.contains('Last name is required').should('be.visible');
//     cy.contains('Username is required').should('be.visible');
//     cy.contains('Invalid email').should('be.visible');
//     cy.contains('Password must be').should('be.visible');
//   });

//   it('should test password visibility toggle on login page', () => {
//     cy.visit('/auth/login');
    
//     // Type password
//     cy.get('input[name="password"]').type('testpassword');
    
//     // Password should be hidden initially
//     cy.get('input[name="password"]').should('have.attr', 'type', 'password');
    
//     // Click the eye icon
//     cy.get('button').find('[class*="eye"]').first().click();
    
//     // Now password should be visible
//     cy.get('input[name="password"]').should('have.attr', 'type', 'text');
//   });

//   it('should navigate from login to signup page', () => {
//     cy.visit('/auth/login');
    
//     // Click the Sign up link
//     cy.contains('a', 'Sign up').click();
    
//     // Verify we're on signup page
//     cy.url().should('include', '/auth/signup');
//     cy.contains('Sign Up').should('be.visible');
//   });

//   it('should navigate from signup to login page', () => {
//     cy.visit('/auth/signup');
    
//     // Click the Login link
//     cy.contains('a', 'Login').click();
    
//     // Verify we're on login page
//     cy.url().should('include', '/auth/login');
//     cy.contains('Login - Welcome Back!').should('be.visible');
//   });
// }); 