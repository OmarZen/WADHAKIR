# Contributing to Wadhakir 🤝

Thank you for helping improve Wadhakir. This guide explains the rules we follow so contributions stay easy to review and safe to merge.

## Before you start

1. Fork the repository.
2. Clone your fork locally.
3. Install dependencies:

```bash
flutter pub get
bash android/fix_deps_proguard.sh
```

   **Re-run `android/fix_deps_proguard.sh` after every `flutter pub get`.** It
   patches `quran_library` in the pub cache for AGP 9.x, and `pub get` restores
   the pristine copy each time — so the patch has to be re-applied after any
   command that resolves dependencies. Without it the Android build fails
   during Gradle configuration with no indication that a patch is missing.

4. *(Optional)* Install the local git hooks, which run format, analyze and
   tests before each commit and lint the commit message:

```bash
npm install
```

   The hooks live in `.husky/`. They are a convenience, not the gate — CI runs
   the same checks on every pull request.

5. Read the README and the workflow guide so you understand the current app structure.

## Branching rules

We follow a Git Flow style process:

- `main` is for stable releases only.
- `develop` is the default integration branch.
- `feature/*` is for new work.
- `fix/*` is for bug fixes.
- `release/*` is for release preparation.

### Branch naming examples

```bash
feature/prayer-reminder-ui
feature/quran-bookmarking
fix/qibla-compass-calibration
fix/overlay-visibility
release/v3.0.1
```

## Contribution rules

- Keep changes focused on one goal.
- Use respectful, constructive language in issues and pull requests.
- Do not commit secrets, local config files, or generated build artifacts.
- Add or update tests when behavior changes.
- Update documentation when the user-facing behavior changes.
- Include screenshots or a short recording for UI updates.

## Development checklist

Before opening a pull request, run:

```bash
dart format .
flutter analyze
flutter test
```

If you changed platform-specific files, test on the relevant device or emulator as well.

## Commit message convention

Use Conventional Commits:

```bash
feat(quran): add bookmark screen
fix(prayer-times): correct timezone handling
docs(readme): improve setup instructions
chore(deps): update packages
```

Recommended types:

- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `refactor` — code restructuring without behavior changes
- `test` — tests added or updated
- `chore` — maintenance or tooling
- `perf` — performance improvement
- `revert` — revert a previous change

## Pull request rules

- Open PRs against `develop` unless the change is a critical production fix.
- Use the PR template in `.github/PULL_REQUEST_TEMPLATE.md`.
- Include a clear summary, test steps, and any relevant screenshots.
- Make sure CI passes before requesting review.
- Respond to review feedback promptly and keep discussions constructive.

## Release flow

1. Create a `release/*` branch from `develop`.
2. Update the version in `pubspec.yaml`.
3. Update `CHANGELOG.md` if the release includes user-visible changes.
4. Run the full checks again.
5. Open a PR to `main`.
6. After merge, tag the release and merge `main` back into `develop`.

## Reporting bugs and requesting features

- Use the issue templates in `.github/ISSUE_TEMPLATE/`.
- Describe the problem or request clearly.
- Add steps to reproduce whenever possible.
- Include screenshots, videos, or device details if they help explain the issue.

## Need help?

- Use GitHub Issues for bugs.
- Use GitHub Discussions for questions and ideas.

Thank you for contributing to Wadhakir and helping keep it welcoming for the community.
