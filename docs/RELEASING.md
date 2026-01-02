# Release Process

This document describes the automated release process for vagrant-orbstack using RubyGems Trusted Publishing.

## Overview

Releases are fully automated using **RubyGems Trusted Publishing** (OIDC-based authentication) via GitHub Actions. No manual authentication or API keys are required.

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

## Release Workflow

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

### "Trusted publisher verification failed"

**Cause**: Workflow name, repository, or environment doesn't match RubyGems configuration.

**Solution**:
1. Check RubyGems trusted publisher config matches workflow exactly
2. Verify workflow file is named `release.yml`
3. Ensure repository name is correct: `spiralhouse/vagrant-orbstack-provider`

### "Version mismatch"

**Cause**: Git tag version doesn't match `version.rb`.

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

1. **Automatic version bumping** - Script to update version + changelog
2. **Pre-release testing** - Deploy to test environment before production
3. **Changelog generation** - Auto-generate from commit messages
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
