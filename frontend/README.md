# Seattle Pulse Frontend

A modern, **location-based social media** front-end built with **Next.js** to deliver high-performance, friendly experiences. This repository stands on its own, focusing exclusively on the **web client**—making it easy for new contributors to get started without extra baggage.

---

## Table of Contents

1. [Overview](#overview)  
2. [Features](#features)  
3. [Technology Stack](#technology-stack)  
4. [Getting Started](#getting-started)  
   - [Prerequisites](#prerequisites)  
   - [Installation](#installation)  
   - [Running the App](#running-the-app)  
5. [Environment Variables](#environment-variables)  
6. [Project Structure](#project-structure)  
7. [Contributing](#contributing)  
   - [Branching](#branching)  
   - [Commit Conventions](#commit-conventions)  
   - [Pull Requests](#pull-requests)  
8. [Testing](#testing)  
9. [Docker (Optional)](#docker-optional)  
10. [Additional Resources](#additional-resources)  
11. [License](#license)  

---

## Overview

**Seattle Pulse Frontend** is the user-facing component of a location-based social network. It allows users to:
- Explore local content in real time.
- Engage with community-driven feeds and events.
- Manage personal profiles, follow others, and share multimedia posts.

> **Note**: For backend functionality (API, database, etc.), refer to the [Seattle Pulse Backend](https://github.com/Seattle-Pulse/SEATTLE-PULSE-BACKEND).

---

## Features

- **Location-Aware Feeds**: Discover trending stories and posts in Seattle neighborhoods.  
- **Real-Time Engagement**: See up-to-date content thanks to Next.js dynamic features.  
- **User Profiles & Follows**: Manage your public profile, follow friends or influencers, and view curated feeds.  
- **Responsive Design**: Built with mobile-first principles, ensuring a fast experience across devices.

---

## Technology Stack

- **Framework**: [Next.js](https://nextjs.org/) (React-based, supports SSR & static generation)  
- **Language**: TypeScript (for type safety and maintainability)  
- **Styling**: CSS modules, Tailwind, or other CSS frameworks (depending on your preference)  
- **State Management**: React hooks, context APIs, or Redux (optional)  
- **HTTP Client**: `fetch` or Axios to interact with the Seattle Pulse API  
- **Version Control**: Git + GitHub  

---

## Getting Started

### Prerequisites

- **Node.js** (version 16 or higher recommended)  
- **npm** (or **yarn**, if you prefer)  
- **Git**  

> **Recommended**: Use [nvm](https://github.com/nvm-sh/nvm) to manage Node versions seamlessly.

### Installation

1. **Clone the Repo**  
   ```bash
   git clone https://github.com/Seattle-Pulse/SEATTLE-PULSE-FRONTEND.git
   cd SEATTLE-PULSE-FRONTEND
   ```

2. **Install Dependencies**  

    ```bash
    npm install
    ```

or

    ```bash
    yarn
    ```

### Running the App

1. **Development Server**  
   ```bash
   npm run dev
   ```
   This starts a local Next.js server at [http://localhost:3000](http://localhost:3000).

2. **Production Build**  
   ```bash
   npm run build
   npm run start
   ```
   Compiles the project for production, then launches on the default port `3000`.

---

## Environment Variables

To configure API endpoints or other secrets, create a file named `.env.local` (ignored by Git) in the project root. Example:

```dotenv
# Example: FRONTEND .env.local

# The base URL for Seattle Pulse API
NEXT_PUBLIC_API_URL=http://localhost:5001
```

- **NEXT_PUBLIC_API_URL**: The public-facing URL for your backend API.  
- Add or remove variables as needed for maps, analytics, etc.

> **Important**: Never commit secrets or private tokens to the repo. Use `.env.local` or a secure manager like Vault / AWS Secrets Manager in production.

---

## Project Structure

Simplified layout may look like this:

```ruby
SEATTLE-PULSE-FRONTEND/
├── app/
│   ├── page.tsx           # Home or main feed page
│   ├── profile/           # User profile routes
│   ├── auth/              # Auth-related pages (login, signup, reset)
│   ├── services/          # API calls or utility wrappers
│   ├── ...                # Other pages/routes
├── components/
│   ├── nav-bar.tsx
│   ├── sidebar.tsx
│   ├── ui/                # Reusable UI components (buttons, modals, etc.)
├── public/                # Static assets (images, icons, etc.)
├── styles/                # Global or shared styles (if not using Tailwind)
├── .gitignore
├── package.json
├── README.md
├── next.config.js
├── tsconfig.json
└── ...
```

- **app/**: Next.js routes + core logic.  
- **components/**: Reusable UI components (nav bars, modals).  
- **public/**: Images, icons, or other static files.

---

## Contributing

### Branching

- **main**: Always stable and deployable.  
- **feature/short-description**: For new features or enhancements.  
- **hotfix/short-description**: For urgent production fixes.

```bash
git checkout -b alias/my-awesome-feature
```

### Commit Conventions

Use meaningful commit messages:

```
[Feature] Implement story posting UI

- Added new form for story submissions
- Integrated with /api/content endpoint
```

### Pull Requests

1. **Push your branch**:
   ```bash
   git push origin alias/my-awesome-feature
   ```
2. **Open a PR** on GitHub against `main`.  
3. **Tag reviewers** and provide any context or screenshots.  
4. **Merge** once approved and checks pass.

---

## Testing

This project uses **Cypress** for end-to-end tests. Run all tests with:

```bash
npm run test
```

Feel free to add Jest or React Testing Library if you need unit tests.

> **Best Practice**: Keep test files alongside components (e.g., `my-component.test.tsx`).

---

## Docker (Optional)

If you prefer containerized development, here's a simple `Dockerfile` example:

```dockerfile
# Dockerfile

FROM node:18-alpine
WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
```

Build and run:

```bash
docker build -t seattle-pulse-frontend .
docker run -p 3000:3000 seattle-pulse-frontend
```

> **Note**: This is a **standalone** container for the frontend. For a full-stack local dev, see the backend’s docker-compose or an infra repo.

---

## Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)

---

## License

All rights reserved.  
This project is proprietary and confidential. Unauthorized copying of this project, via any medium, is strictly prohibited.
