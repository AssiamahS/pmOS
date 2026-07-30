# NOTES

- 2026-07-30: ASC public API cannot CREATE app records (POST /v1/apps → 403 "does
  not allow CREATE"; only GET/UPDATE). New apps need the 1-minute web step in
  App Store Connect. Bundle IDs CAN be registered via API with KB93R49B9J.
- 2026-07-30: cloud signing mints a throwaway "Created via API" DEVELOPMENT cert
  every CI run; the account cap fills up and archive dies with "Choose a
  certificate to revoke". Fix: DELETE /v1/certificates/<id> for stale ones
  (204 empty body — don't json-parse it). Keep the fitx p12 cert (exp 2027-07-16).
- SwiftUI: `cond ? .secondary : .white` inside foregroundStyle won't unify
  (HierarchicalShapeStyle vs Color) — write `Color.secondary : Color.white`.
- No Xcode on this Mac (CLT only): compile verification happens in the CI
  sim-build job, nowhere else.
