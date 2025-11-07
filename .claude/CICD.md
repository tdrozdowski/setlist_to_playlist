# CI/CD Guide

This document describes the CI/CD pipeline, GitHub Actions workflows, and release process for the Setlist Playlist Builder project.

## Overview

**CRITICAL**: All CI/CD runs via GitHub Actions. PRs must pass all checks before merging.

## Workflow Summary

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Pull Request CI** | Every PR creation/update | Build, test, lint, coverage (80% min) |
| **Release Build** | Merge to main/master | Build release binary, create GitHub release |
| **Dependency Check** | Weekly (Sunday) | Check for outdated dependencies |

## Pull Request CI Workflow

**File**: `.github/workflows/pr.yml`

**Runs on**: Every PR creation and update to main/master

**Purpose**: Enforce code quality and test coverage

### Checks Performed

✅ Code formatting (`cargo fmt --check`)
✅ Linting with clippy (`-D warnings`)
✅ Build succeeds
✅ All tests pass
✅ **80% minimum coverage** (enforced by `cargo tarpaulin --fail-under 80`)
✅ Coverage report uploaded to Codecov (required)
✅ Codecov status check on PR (pass/fail based on coverage)

### Workflow File

```yaml
name: Pull Request CI

on:
  pull_request:
    branches: [main, master]

jobs:
  check:
    name: Check, Build, Test, Coverage
    runs-on: macos-latest  # Required for Swift/macOS builds

    steps:
      - uses: actions/checkout@v4

      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable

      - name: Install Swift (verify)
        run: swift --version

      - name: Cache cargo registry
        uses: actions/cache@v4
        with:
          path: ~/.cargo/registry
          key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}

      - name: Cache cargo index
        uses: actions/cache@v4
        with:
          path: ~/.cargo/git
          key: ${{ runner.os }}-cargo-index-${{ hashFiles('**/Cargo.lock') }}

      - name: Cache target directory
        uses: actions/cache@v4
        with:
          path: target
          key: ${{ runner.os }}-target-${{ hashFiles('**/Cargo.lock') }}

      - name: Check formatting
        run: cargo fmt --all -- --check

      - name: Clippy (lint)
        run: cargo clippy --all-targets --all-features -- -D warnings

      - name: Build
        run: cargo build --verbose

      - name: Run tests
        run: cargo test --verbose

      - name: Install tarpaulin
        run: cargo install cargo-tarpaulin

      - name: Run coverage (80% minimum required)
        run: cargo tarpaulin --fail-under 80 --out Xml --output-dir ./coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/cobertura.xml
          fail_ci_if_error: true
          token: ${{ secrets.CODECOV_TOKEN }}  # Optional: only needed if upload fails
          flags: unittests                     # Optional: flag for this upload
          name: codecov-umbrella               # Optional: custom name

      - name: Upload coverage report (artifact)
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
```

### Running Locally

**Run all CI checks locally before pushing**:

```bash
cargo fmt --all -- --check && \
cargo clippy --all-targets --all-features -- -D warnings && \
cargo test && \
cargo tarpaulin --fail-under 80
```

## Release Build Workflow

**File**: `.github/workflows/release.yml`

**Runs on**: Every merge to main/master

**Purpose**: Build release binary and create GitHub release

### Release Process

1. **Extract version** from `Cargo.toml`
2. **Build release binary** (`cargo build --release`)
3. **Run tests** in release mode
4. **Create tarball** of binary
5. **Create GitHub release** with version tag
6. **Upload binary** as release asset

### Workflow File

```yaml
name: Release Build

on:
  push:
    branches: [main, master]

jobs:
  build-and-release:
    name: Build and Release Binary
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable

      - name: Install Swift (verify)
        run: swift --version

      - name: Build release binary
        run: cargo build --release --verbose

      - name: Run tests
        run: cargo test --release --verbose

      - name: Get version from Cargo.toml
        id: version
        run: |
          VERSION=$(grep -m1 '^version' Cargo.toml | cut -d'"' -f2)
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Create tarball
        run: |
          cd target/release
          tar -czf setlist-playlist-builder-${{ steps.version.outputs.version }}-macos-arm64.tar.gz setlist_to_playlist

      - name: Generate changelog
        id: changelog
        run: |
          COMMIT_MSG=$(git log -1 --pretty=format:"%s")
          echo "message=$COMMIT_MSG" >> $GITHUB_OUTPUT

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${{ steps.version.outputs.version }}
          name: Release v${{ steps.version.outputs.version }}
          body: |
            ## Changes
            ${{ steps.changelog.message }}

            ## Installation

            Download the binary for your platform and extract:

            ```bash
            tar -xzf setlist-playlist-builder-${{ steps.version.outputs.version }}-macos-arm64.tar.gz
            chmod +x setlist_to_playlist
            mv setlist_to_playlist /usr/local/bin/
            ```

            ## Requirements
            - macOS 12.0+ (Monterey or later)
            - Apple Music subscription
            - Setlist.fm API key
          files: |
            target/release/setlist-playlist-builder-${{ steps.version.outputs.version }}-macos-arm64.tar.gz
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Versioning Strategy

**Semantic Versioning** (major.minor.patch):

1. Update version in `Cargo.toml` before merging to main
2. CI automatically creates release with that version
3. Tag format: `v0.1.0`, `v0.2.0`, `v1.0.0`, etc.

**Example Workflow**:
```bash
# 1. Create feature branch
git checkout -b feature/add-fuzzy-matching

# 2. Implement feature with tests (ensure 80%+ coverage)
# ... make changes ...

# 3. Update version in Cargo.toml
# version = "0.2.0"  # Bump version

# 4. Create PR
git push origin feature/add-fuzzy-matching
# CI runs all checks

# 5. Review and merge
# Release workflow creates GitHub release automatically

# 6. Binary available at GitHub releases
# https://github.com/user/repo/releases/tag/v0.2.0
```

## Dependency Check Workflow

**File**: `.github/workflows/dependencies.yml`

**Runs on**: Weekly schedule (Sunday 00:00 UTC)

**Purpose**: Check for outdated dependencies and create issues

### Workflow File

```yaml
name: Dependency Check

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:  # Allow manual trigger

jobs:
  check-deps:
    name: Check for Outdated Dependencies
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable

      - name: Install cargo-outdated
        run: cargo install cargo-outdated

      - name: Check for outdated dependencies
        run: cargo outdated --exit-code 1
        continue-on-error: true

      - name: Create issue if outdated
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Outdated Dependencies Detected',
              body: 'The weekly dependency check found outdated dependencies. Run `cargo outdated` locally and update with `cargo upgrade`.',
              labels: ['dependencies', 'maintenance']
            })
```

### Manual Trigger

You can manually trigger the dependency check:

```bash
# Via GitHub UI: Actions → Dependency Check → Run workflow

# Or via GitHub CLI
gh workflow run dependencies.yml
```

## Branch Protection Rules

**Configure on GitHub**: `Settings > Branches > Branch protection rules`

### For `main` or `master` Branch

✅ **Require pull request reviews before merging**
✅ **Require status checks to pass before merging**:
  - `Check, Build, Test, Coverage` (GitHub Actions job)
  - `codecov/project` (Codecov project coverage)
  - `codecov/patch` (Codecov patch coverage)
✅ **Require branches to be up to date before merging**
✅ **Do not allow bypassing the above settings**
❌ **Do not allow force pushes**
❌ **Do not allow deletions**

**Note**: Codecov status checks will appear after the first PR with coverage is uploaded.

### Configuration Steps

1. Go to repository `Settings`
2. Click `Branches` in left sidebar
3. Click `Add rule` under "Branch protection rules"
4. Enter branch name pattern: `main` (or `master`)
5. Check the boxes listed above
6. Click `Create` or `Save changes`

## Codecov Integration

**REQUIRED**: Codecov is integrated into the CI pipeline for coverage visualization and enforcement.

### Setup

1. **Sign up for Codecov**:
   - Go to https://codecov.io
   - Sign in with GitHub
   - Authorize Codecov to access your repositories

2. **Enable repository**:
   - Codecov automatically detects new repositories
   - No additional configuration needed (uses GITHUB_TOKEN)
   - Coverage uploads happen automatically on each PR

3. **Get Codecov token** (optional, only if upload fails):
   - Go to repository settings on Codecov
   - Copy the upload token
   - Add as GitHub secret: `Settings > Secrets > CODECOV_TOKEN`

### Configuration File

**File**: `.codecov.yml` (required)

Create this file in the repository root:

```yaml
# .codecov.yml - Codecov configuration

# Coverage requirements
coverage:
  status:
    project:
      default:
        target: 80%          # Minimum 80% coverage required
        threshold: 1%        # Allow max 1% drop from previous commit
        if_ci_failed: error  # Fail if CI failed
    patch:
      default:
        target: 80%          # New code must also have 80%+ coverage
        if_ci_failed: error

# PR comment configuration
comment:
  layout: "reach,diff,flags,files,footer"
  behavior: default
  require_changes: false     # Comment even if coverage unchanged
  require_base: false        # Comment even for first PR
  require_head: true         # Only comment if head report exists

# Ignore these files from coverage
ignore:
  - "src/main.rs"           # Binary entry point
  - "src/bridge.rs"         # Generated FFI code
  - "**/*_test.rs"          # Test files
  - "tests/**"              # Test directories

# Flags for different parts of codebase (optional)
flags:
  services:
    paths:
      - src/services/
    target: 90%              # Services need 90%+ coverage

  controllers:
    paths:
      - src/controllers/
    target: 85%              # Controllers need 85%+ coverage

  adapters:
    paths:
      - src/adapters/
    target: 85%              # Adapters need 85%+ coverage
```

### Codecov Badge

Add to README.md (after repository is set up):

```markdown
# Setlist Playlist Builder

[![CI](https://github.com/username/repo/workflows/Pull%20Request%20CI/badge.svg)](https://github.com/username/repo/actions)
[![codecov](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)

Your project description here...
```

### How It Works

1. **PR created** → GitHub Actions runs tests with coverage
2. **Coverage generated** → `cargo tarpaulin` creates XML report
3. **Upload to Codecov** → `codecov-action@v4` uploads report
4. **Codecov analyzes** → Compares with base branch
5. **PR comment** → Codecov bot comments with coverage diff
6. **Status check** → Pass/fail based on coverage thresholds

### Codecov PR Comments

Codecov will automatically comment on PRs with:

```
## [Codecov](https://codecov.io/gh/user/repo/pull/123) Report
> :exclamation: 80.45% (+0.52%) compared to main

| Coverage Diff | main | PR |
|---------------|------|-----|
| Coverage      | 79.93% | 80.45% |
| Files         | 25 | 26 |
| Lines         | 1234 | 1289 |

[Coverage by file](https://codecov.io/gh/user/repo/pull/123)
```

### Codecov Dashboard

View coverage trends at: `https://codecov.io/gh/username/repo`

**Dashboard features**:
- **Coverage trend** over time (line graph)
- **File browser** with coverage per file
- **Compare branches** to see coverage differences
- **Commit list** with coverage for each commit
- **Pull request list** with coverage impact
- **Sunburst chart** visual coverage breakdown

### Codecov Settings

Configure in Codecov UI (`Settings` tab):

**Status Checks**:
- ✅ Enable status checks on PRs
- ✅ Fail PR if coverage decreases
- ✅ Only report coverage changes in PR diff

**Notifications**:
- ✅ Email on coverage changes
- ✅ Slack notifications (optional)

**Badge Settings**:
- Choose badge style (shields.io, flat, flat-square)
- Select branch (main/master)

### Troubleshooting Codecov

**Upload fails in CI**:
```yaml
# Add verbose flag to upload step
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: ./coverage/cobertura.xml
    fail_ci_if_error: true
    verbose: true  # Add this for debugging
```

**Coverage not showing**:
1. Check XML file is generated: `ls -la coverage/`
2. Verify file format: `head coverage/cobertura.xml`
3. Check Codecov logs in GitHub Actions output
4. Ensure repository is enabled on Codecov

**Status check not appearing**:
1. Go to Codecov settings
2. Enable "Status Checks" in configuration
3. Wait for next PR/commit

**Inaccurate coverage**:
1. Ensure `.codecov.yml` `ignore` section is correct
2. Check file paths match actual project structure
3. Verify `tarpaulin` excludes correct files

### Local Codecov Testing

Test Codecov configuration locally:

```bash
# Install Codecov CLI
brew install codecov/codecov/codecov  # macOS
# or
curl -Os https://uploader.codecov.io/latest/linux/codecov
chmod +x codecov

# Validate configuration
codecov --help

# Dry-run upload (doesn't actually upload)
codecov --dry-run -f coverage/cobertura.xml
```

## Local Pre-Commit Hook

**Optional**: Mirror CI checks locally before commit.

**File**: `.git/hooks/pre-commit`

```bash
#!/bin/bash
set -e

echo "Running pre-commit checks..."

echo "1. Checking formatting..."
cargo fmt --all -- --check

echo "2. Running clippy..."
cargo clippy --all-targets --all-features -- -D warnings

echo "3. Running tests..."
cargo test

echo "✅ All pre-commit checks passed!"
```

**Install**:
```bash
chmod +x .git/hooks/pre-commit
```

**Bypass** (not recommended):
```bash
git commit --no-verify
```

## CI/CD Best Practices

### 1. Never Bypass CI Checks
❌ **Never merge PRs without passing CI**
✅ All code must pass: format, clippy, tests, coverage

### 2. Fix Failing Tests Immediately
❌ Don't merge with failing tests
❌ Don't disable tests to make CI pass
✅ Fix the root cause of test failures

### 3. Maintain 80%+ Coverage
❌ Don't merge if coverage drops below 80%
✅ Add tests before merging features
✅ Focus on high-value tests (services, algorithms)

### 4. Keep Dependencies Updated
✅ Review weekly dependency check issues
✅ Run `cargo update` regularly
✅ Test after updating dependencies

### 5. Test Locally First
✅ Run all CI checks locally before pushing:
```bash
cargo fmt --all -- --check && \
cargo clippy --all-targets --all-features -- -D warnings && \
cargo test && \
cargo tarpaulin --fail-under 80
```

### 6. Use Meaningful Commit Messages
✅ Commit messages appear in release notes
✅ Use conventional commits format (optional):
  - `feat: Add fuzzy matching algorithm`
  - `fix: Correct confidence threshold calculation`
  - `docs: Update architecture documentation`
  - `test: Add integration tests for playlist controller`

## Troubleshooting

### Build Fails on CI But Passes Locally

**Possible causes**:
- Swift version difference between local and CI
- Rust version difference (CI uses stable)
- Dependency version mismatch (Cargo.lock not committed)
- Environment-specific code

**Solutions**:
1. Check Swift version: `swift --version` (should be 5.x+)
2. Check Rust version: `rustc --version` (CI uses stable)
3. Ensure `Cargo.lock` is committed
4. Run `cargo clean && cargo build` locally
5. Check CI logs for specific error messages

### Coverage Below 80%

**Solution**:
1. Run locally: `cargo tarpaulin --out Html --output-dir coverage`
2. Open `coverage/index.html` in browser
3. Identify uncovered lines (shown in red)
4. Add tests for uncovered code paths
5. Focus on services, algorithms, domain logic
6. Skip trivial code (getters, simple From impls)
7. Re-run: `cargo tarpaulin --fail-under 80`

### Release Fails

**Possible causes**:
- Version in `Cargo.toml` already exists as a tag
- GITHUB_TOKEN lacks permissions
- Binary doesn't build in release mode

**Solutions**:
1. Check existing tags: `git tag -l`
2. Bump version in `Cargo.toml` if tag exists
3. Verify binary builds: `cargo build --release`
4. Check GitHub Actions permissions in repo settings

### Clippy Fails with Warnings

**Solution**:
```bash
# See all clippy warnings locally
cargo clippy --all-targets --all-features

# Fix automatically (some warnings)
cargo clippy --fix --all-targets --all-features

# CI uses -D warnings (treat warnings as errors)
cargo clippy --all-targets --all-features -- -D warnings
```

### Formatting Check Fails

**Solution**:
```bash
# Format code locally
cargo fmt --all

# Check formatting (what CI runs)
cargo fmt --all -- --check
```

### Dependency Check Creates Too Many Issues

**Solution**:
- Adjust cron schedule in `dependencies.yml`
- Only update dependencies when necessary
- Close duplicate issues
- Run `cargo upgrade` locally and create single PR

## GitHub Actions Debugging

### View Logs

1. Go to repository on GitHub
2. Click `Actions` tab
3. Click on workflow run
4. Click on job name
5. Expand steps to see detailed logs

### Re-Run Failed Jobs

1. Go to failed workflow run
2. Click `Re-run jobs` button
3. Select `Re-run failed jobs` or `Re-run all jobs`

### Secrets Management

CI workflows can use GitHub secrets for sensitive data:

1. Go to `Settings > Secrets and variables > Actions`
2. Click `New repository secret`
3. Add secret name and value
4. Reference in workflow: `${{ secrets.SECRET_NAME }}`

**Note**: Current workflows don't require additional secrets (use built-in `GITHUB_TOKEN`).

## Monitoring

### GitHub Actions Dashboard

View CI/CD status:
- Repository homepage shows status badge
- Actions tab shows all workflow runs
- Can filter by workflow, branch, status

### Codecov Dashboard

View coverage trends:
- https://codecov.io/gh/username/repo
- Coverage graph over time
- File-level coverage breakdown
- PR coverage diffs

## Future Enhancements

Potential CI/CD improvements:

1. **Multi-platform builds**: Add Linux, Windows support
2. **Performance benchmarks**: Track performance regressions
3. **Security scanning**: Add `cargo audit` to PR checks
4. **Automated dependency updates**: Use Dependabot or Renovate
5. **Staging releases**: Pre-release tags for testing
6. **Docker images**: Build and publish Docker images
7. **Homebrew formula**: Automated tap updates on release
