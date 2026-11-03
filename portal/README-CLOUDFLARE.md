# FRIDA internal download portal

Landing page for FRIDA, deployed separately from the Android web app by using the `portal/` directory as the Cloudflare Pages build output.

## Cloudflare Pages configuration

Connect this GitHub repository to Cloudflare Pages and configure:

- Production branch: `main`
- Framework preset: `None`
- Build command: leave empty
- Build output directory: `portal`
- Root directory: `/` (repository root)
- Functions directory: `functions` (at repository root; Pages detects this automatically)

The Android app build workflow in `.github/workflows/android.yml` is not changed.

## Required Pages secrets

In **Workers & Pages > your Pages project > Settings > Variables and Secrets**, add these as encrypted secrets for Production (and Preview if preview deployments should be protected):

- `FRIDA_PASSWORD`: a strong, unique team password. Do not commit it to Git.
- `SESSION_SECRET`: a separate random secret of at least 32 characters, used to sign 8-hour session cookies.

Do not paste either value into source files or chat. After adding secrets, redeploy the Pages project.

## Authentication behavior

- All portal paths are protected by `functions/_middleware.js`.
- Password is checked server-side using a constant-time comparison.
- Successful login sets an HttpOnly, Secure, SameSite=Lax cookie.
- Session expires after 8 hours.
- Logout clears the session cookie.
- Login and portal responses are marked no-store.

For production, enable Cloudflare rate limiting/WAF protection on `/__auth/login` to slow repeated password guesses. A shared password is convenient but is not individual identity or audit logging.

## APK download

The current button opens the repository's GitHub Actions Android workflow. Select the latest successful run and download artifact `FRIDA-v1.4-debug-APK`. GitHub artifacts expire after the workflow's configured retention period (currently 14 days), and downloading may require GitHub sign-in.

For a smoother internal distribution flow, a later enhancement can copy successful APK builds into a private Cloudflare R2 bucket and serve them through an authenticated Pages Function. Do not publish the APK to a public GitHub Release if it must remain internal.

## Notes

The existing root `index.html`, `www/`, Capacitor app files, and Android build workflow are intentionally left untouched. The portal uses the existing logo at `assets/frida-logo.png`.
