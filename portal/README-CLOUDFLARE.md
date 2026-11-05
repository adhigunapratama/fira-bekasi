# FRIDA internal download portal

Landing page for FRIDA, deployed separately from the Android web app by using the `portal/` directory as the Cloudflare Pages build output.

## Cloudflare Pages configuration

Connect this GitHub repository to Cloudflare Pages and configure:

- Production branch: `feature/frida-download-portal`
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

The portal serves `/download/apk` through an authenticated Pages Function. The function reads `frida-latest.apk` from a Workers KV namespace bound to the Pages project as `FRIDA_APK_KV`. The Android workflow uploads each successful APK to this KV key when the three Cloudflare GitHub Actions secrets are configured.

Create a Workers KV namespace and bind it to the Pages project as `FRIDA_APK_KV`. Add GitHub Actions repository secrets `CF_ACCOUNT_ID`, `CF_KV_NAMESPACE_ID`, and `CF_API_TOKEN`. The API token needs Workers KV Storage Edit permission for the account. Individual KV values have a 25 MiB limit, so publishing is skipped if the APK exceeds that size. Never expose the API token in source code or chat. Until the binding, secrets, and a successful new Android build are configured, the direct-download endpoint will report that the APK is not yet available.

## Notes

The existing root `index.html`, `www/`, Capacitor app files, and Android build workflow are intentionally left untouched. The portal uses the existing logo at `assets/frida-logo.png`.
