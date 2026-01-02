# Release Process

This document describes the automated release process for vagrant-orbstack using RubyGems Trusted Publishing.

## Overview

Releases are **fully automated** using Release-Please and RubyGems Trusted Publishing. The process is triggered by conventional commits pushed to main, eliminating manual version bumping and changelog updates.

## Automated Release Process (Primary Method)

### How It Works

1. **Commit with conventional format** to main (via PR):
   ```
   feat: add synced folders support [SPI-1234]
   fix: resolve SSH timeout on machine start [SPI-1235]
   ```

2. **Release-Please analyzes commits**:
   - Runs automatically on every push to main
   - Determines version bump based on commit types:
     - `feat:` → minor bump (0.1.0 → 0.2.0)
     - `fix:` → patch bump (0.1.0 → 0.1.1)
     - `BREAKING CHANGE:` → major bump (0.x.0 → 1.0.0)
   - Categorizes changes for changelog

3. **Release PR automatically created/updated**:
   - Title: `chore: prepare 0.2.0 release`
   - Updates: `lib/vagrant-orbstack/version.rb` and `CHANGELOG.md`
   - Grouped by type: Added (feat), Fixed (fix), Changed (refactor), etc.
   - Linear issue references preserved

4. **Review and merge release PR**:
   - Review version bump (correct semver?)
   - Review changelog (accurate categorization?)
   - Merge when ready

5. **Automated publishing triggered**:
   - Merge creates git tag (e.g., v0.2.0)
   - Tag triggers `.github/workflows/release.yml`
   - Publishes to RubyGems via Trusted Publishing
   - Creates GitHub release with changelog
   - Total time: ~3-5 minutes

### Developer Workflow

**Adding Features** (minor bump):
```bash
git checkout -b feat/synced-folders
# ... implement feature ...
git commit -m "feat: add synced folders support [SPI-1234]"
git push origin feat/synced-folders
# Create PR, get approval, merge to main
# → Release-Please creates/updates release PR automatically
```

**Fixing Bugs** (patch bump):
```bash
git checkout -b fix/ssh-timeout
# ... fix bug ...
git commit -m "fix: resolve SSH timeout on slow machines [SPI-1235]"
# → Same process: PR → merge → automatic release PR
```

**Documentation/Chores** (patch bump, hidden in changelog):
```bash
git commit -m "docs: update troubleshooting guide"
git commit -m "chore: update dependencies"
# → These still create releases but don't appear in user-facing changelog
```

### Commit Type Reference

| Type | Version Impact | Changelog Section | Example |
|------|---------------|-------------------|---------|
| `feat` | MINOR (0.1→0.2) | Added | New feature, capability |
| `fix` | PATCH (0.1.0→0.1.1) | Fixed | Bug fix, regression fix |
| `docs` | PATCH | Documentation | README, guides, comments |
| `refactor` | PATCH | Changed | Code restructuring |
| `test` | PATCH | (hidden) | Test additions |
| `chore` | PATCH | (hidden) | Dependencies, tooling |

**Breaking Changes**: Add `BREAKING CHANGE:` in commit footer → MAJOR bump

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed commit message guidelines.

### When Release PR Appears

Release-Please creates/updates a release PR when:
- Releasable commits exist since last release (feat, fix, docs, refactor)
- No PR exists yet, or existing PR needs updating with new commits

Release-Please does NOT create PR when:
- Only non-releasable commits (test-only, no user-facing changes)
- No commits since last release

### Release PR Review Checklist

Before merging the release PR:
- [ ] Version bump is correct (feat = minor, fix = patch, BREAKING = major)
- [ ] Changelog accurately reflects changes
- [ ] All features/fixes have Linear issue references
- [ ] Categorization matches intent (Added vs Fixed vs Changed)
- [ ] No unintended changes in version.rb or CHANGELOG.md
- [ ] CI checks pass (RuboCop, RSpec, build)

### Monitoring Releases

After release PR merges:
1. **Watch GitHub Actions**: Release workflow should complete in ~3-5 min
2. **Check RubyGems**: https://rubygems.org/gems/vagrant-orbstack
3. **Verify GitHub Release**: https://github.com/spiralhouse/vagrant-orbstack-provider/releases
4. **Test installation**: `vagrant plugin install vagrant-orbstack --version X.Y.Z`

## Prerequisites

### One-Time Setup (Already Completed)

1. **RubyGems Trusted Publisher Configured**
   - Repository: `spiralhouse/vagrant-orbstack-provider`
   - Workflow: `release.yml`
   - Environment: `release` (optional)
   - Configured at: https://rubygems.org/gems/vagrant-orbstack/trusted_publishers

2. **GitHub Actions Workflow**
   - Location: `.github/workflows/release.yml`
   - Triggers: On version tags (`v*.*.*`)
   - Uses: `rubygems/release-gem@v1` action with OIDC

## Manual Release Process (Fallback/Reference)

**Note**: This manual process is preserved as a fallback if automation fails. The automated process above is now the primary release method.

### Step 1: Update Version

Edit `lib/vagrant-orbstack/version.rb`:

```ruby
module VagrantPlugins
  module OrbStack
    VERSION = "0.2.0"  # Update this
  end
end
```

### Step 2: Update CHANGELOG.md

Move changes from `[Unreleased]` to a new version section:

```markdown
## [Unreleased]

### Added

### Changed

### Fixed

## [0.2.0] - 2026-01-15

### Added
- New feature descriptions

### Fixed
- Bug fix descriptions
```

Update footer links:
```markdown
[Unreleased]: https://github.com/spiralhouse/vagrant-orbstack-provider/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/spiralhouse/vagrant-orbstack-provider/releases/tag/v0.2.0
[0.1.0]: https://github.com/spiralhouse/vagrant-orbstack-provider/releases/tag/v0.1.0
```

### Step 3: Commit Changes

```bash
git checkout main
git pull origin main
git checkout -b release/v0.2.0

git add lib/vagrant-orbstack/version.rb CHANGELOG.md
git commit -m "chore: prepare v0.2.0 release

- Update version to 0.2.0
- Update CHANGELOG with release notes"

git push origin release/v0.2.0
```

### Step 4: Create Pull Request

Create PR with title: `chore: prepare v0.2.0 release`

**PR Checklist:**
- [ ] Version updated in `version.rb`
- [ ] CHANGELOG updated with all changes
- [ ] CHANGELOG footer links updated
- [ ] All tests passing
- [ ] RuboCop clean

### Step 5: Merge and Create Tag

After PR approval and merge:

```bash
git checkout main
git pull origin main

# Create annotated tag
git tag -a v0.2.0 -m "Version 0.2.0

Brief description of this release.

See CHANGELOG.md for full details."

# Push tag to trigger release workflow
git push origin v0.2.0
```

### Step 6: Automated Release (GitHub Actions)

The workflow automatically:

1. ✅ **Validates** version matches gemspec
2. ✅ **Runs quality checks** (RuboCop, RSpec)
3. ✅ **Builds gem** from current code
4. ✅ **Verifies gem contents** (no test files)
5. ✅ **Publishes to RubyGems** via Trusted Publishing (zero manual auth!)
6. ✅ **Extracts CHANGELOG** for this version
7. ✅ **Creates GitHub Release** with changelog and gem file
8. ✅ **Verifies publication** on RubyGems

**Total time:** ~3-5 minutes (fully automated)

### Step 7: Verify Release

After workflow completes:

1. **Check RubyGems**: https://rubygems.org/gems/vagrant-orbstack
   - Latest version should be visible
   - Metadata should be correct

2. **Check GitHub Release**: https://github.com/spiralhouse/vagrant-orbstack-provider/releases
   - Release created with changelog
   - Gem file attached

3. **Test installation**:
   ```bash
   vagrant plugin install vagrant-orbstack --version 0.2.0
   vagrant plugin list | grep vagrant-orbstack
   ```

## How Trusted Publishing Works

**Traditional approach** (what we avoided):
- ❌ Generate long-lived API key
- ❌ Store in GitHub Secrets
- ❌ Rotate periodically
- ❌ Risk of key leakage
- ❌ Manual OTP authentication

**Trusted Publishing** (what we're using):
- ✅ Zero API keys to manage
- ✅ GitHub generates short-lived OIDC token automatically
- ✅ RubyGems verifies token against trusted publisher config
- ✅ Only your specific workflow can publish
- ✅ No secrets to leak or rotate
- ✅ Fully automated

**Security:**
- Only `spiralhouse/vagrant-orbstack-provider` repository
- Only `.github/workflows/release.yml` workflow
- Only when triggered by version tag
- Optional: Require manual approval via GitHub environment

## Troubleshooting

### Release-Please Not Creating PR

**Cause**: No releasable commits since last release.

**Solution**:
- Check commits since last tag: `git log v0.1.0..HEAD --oneline`
- Verify commits use conventional format (`feat:`, `fix:`, etc.)
- Ensure commits are on main branch
- Manually trigger: GitHub Actions → Release-Please workflow → Run workflow

### Release PR Has Wrong Version Bump

**Cause**: Commit types don't match intent (e.g., `fix:` used for feature).

**Solution**:
1. Close the release PR
2. Rewrite commit messages on main (if recent): `git rebase -i HEAD~3`
3. Force push: `git push --force-with-lease origin main`
4. Release-Please will recreate PR with correct version

**Prevention**: Use correct commit types (feat for features, fix for bugs).

### Changelog Missing Expected Changes

**Cause**: Commits hidden by changelog-types configuration.

**Solution**:
- Types `test`, `chore`, `research` are intentionally hidden from user-facing changelog
- Use `feat:` or `fix:` for user-visible changes
- Internal changes (tests, deps) don't need changelog visibility

### "Version mismatch" in Release Workflow

**Cause**: Manual edit to version.rb after Release-Please PR merged.

**Solution**:
- Never manually edit version.rb after Release-Please creates it
- Let Release-Please manage version bumping
- If manual edit needed, update release PR before merging

### "Trusted publisher verification failed"

**Cause**: Workflow name, repository, or environment doesn't match RubyGems configuration.

**Solution**:
1. Check RubyGems trusted publisher config matches workflow exactly
2. Verify workflow file is named `release.yml`
3. Ensure repository name is correct: `spiralhouse/vagrant-orbstack-provider`

### "Version mismatch" (Git tag vs version.rb)

**Cause**: Git tag version doesn't match `version.rb` (manual release scenario).

**Solution**:
1. Ensure `version.rb` was updated and committed
2. Tag should match: `v0.2.0` tag → `VERSION = "0.2.0"` in code

### "Tests failed"

**Cause**: Quality checks didn't pass.

**Solution**:
1. Run tests locally: `bundle exec rspec`
2. Run RuboCop: `bundle exec rubocop`
3. Fix issues, commit, retag

### "Gem already exists"

**Cause**: Trying to republish same version.

**Solution**:
1. RubyGems doesn't allow republishing same version
2. Increment version number
3. Create new tag

## Emergency: Manual Release

If automation fails, you can still publish manually:

```bash
# Build gem
gem build vagrant-orbstack.gemspec

# Publish with biometric authentication
gem push pkg/vagrant-orbstack-0.2.0.gem
# Follow WebAuthn URL to authenticate

# Create GitHub release manually
gh release create v0.2.0 \
  --title "v0.2.0" \
  --notes-file <(sed -n "/## \[0.2.0\]/,/## \[/p" CHANGELOG.md | sed '$d') \
  pkg/vagrant-orbstack-0.2.0.gem
```

## Future Improvements

Potential enhancements to consider:

1. ~~**Automatic version bumping**~~ - ✅ **Implemented via Release-Please (SPI-1294)**
2. **Pre-release testing** - Deploy to test environment before production
3. ~~**Changelog generation**~~ - ✅ **Implemented via Release-Please (SPI-1294)**
4. **Rollback capability** - Automated rollback on critical issues
5. **Release notifications** - Slack/Discord notifications on publish

## References

- RubyGems Trusted Publishing: https://guides.rubygems.org/trusted-publishing/
- GitHub Actions OIDC: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- Release Gem Action: https://github.com/rubygems/release-gem
- Semantic Versioning: https://semver.org/

---

**Last Updated**: 2026-01-02
**For**: vagrant-orbstack v0.1.0+
