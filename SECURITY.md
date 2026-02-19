# Security Policy

## Never Commit Secrets
- Never commit API keys, access tokens, passwords, private keys, OAuth client secrets, DSNs, or live database URLs.
- Keep all secrets in local `.env` files (ignored by git) or a managed secret store in deployment.
- Commit only placeholder templates such as `.env.example`.

## Environment Configuration
- Copy templates and fill values locally:
  - `cp .env.example .env`
  - `cp backend/.env.example backend/.env`
  - `cp frontend/.env.example frontend/.env.local`
- Use placeholder values for local development unless a real third-party integration is required.
- For deployment, inject secrets via your platform secret manager (for this repo: ECS task `secrets.valueFrom`).

## If a Secret Is Leaked
- Treat leaked secrets as compromised immediately.
- Rotate at minimum:
  - Database credentials (for example Neon `DATABASE_URL` credentials)
  - Cloud credentials (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`)
  - OAuth credentials (`GOOGLE_CLIENT_SECRET`, `GOOGLE_CLIENT_SECRET_JSON`)
  - Communication providers (`TWILIO_AUTH_TOKEN`)
  - Monitoring/analytics tokens (`SENTRY_DSN`, `MIXPANEL_TOKEN_*`)
  - Mail/service credentials (`MAIL_PASSWORD` and similar)
- Update all environments to the new values and invalidate old credentials.
- Review git history and open PRs for additional exposure.
