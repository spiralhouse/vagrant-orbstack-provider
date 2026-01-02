# Vagrant OrbStack Provider - Release Checklist

This checklist ensures all steps are completed before publishing a new release to RubyGems.

**Based on**: [PUBLICATION_RESEARCH.md](./PUBLICATION_RESEARCH.md) analysis of established Vagrant provider plugins.

---

## Pre-Release Preparation

### 1. Gemspec Metadata Review

**File**: `vagrant-orbstack.gemspec`

- [ ] **name** is set to `vagrant-orbstack`
- [ ] **version** correctly references `VagrantPlugins::OrbStack::VERSION`
- [ ] **authors** contains actual maintainer names (not placeholder)
- [ ] **email** contains real contact email (not `noreply@example.com`)
- [ ] **summary** is concise (< 140 characters)
- [ ] **description** accurately describes the plugin
- [ ] **homepage** points to actual GitHub repository URL
- [ ] **license** is set correctly (MIT)
- [ ] **required_ruby_version** aligns with Vagrant compatibility
- [ ] **files** includes all necessary files:
  - [ ] `lib/**/*.rb`
  - [ ] `locales/**/*.yml`
  - [ ] `README.md`
  - [ ] `CHANGELOG.md`
  - [ ] `LICENSE` or `LICENSE.txt`

### 2. Gemspec Metadata Hash

**Required fields** (RubyGems 2025 best practices):

```ruby
spec.metadata = {
  "homepage_uri"      => "https://github.com/spiralhouse/vagrant-orbstack-provider",
  "source_code_uri"   => "https://github.com/spiralhouse/vagrant-orbstack-provider",
  "bug_tracker_uri"   => "https://github.com/spiralhouse/vagrant-orbstack-provider/issues",
  "changelog_uri"     => "https://github.com/spiralhouse/vagrant-orbstack-provider/blob/main/CHANGELOG.md",
  "documentation_uri" => "https://github.com/spiralhouse/vagrant-orbstack-provider",
  "allowed_push_host" => "https://rubygems.org"
}
```

Verify:
- [ ] All URIs are correct and accessible
- [ ] `allowed_push_host` restricts to RubyGems only
- [ ] Metadata hash is properly formatted

### 3. Version Update

**File**: `lib/vagrant-orbstack/version.rb`

- [ ] Version follows [Semantic Versioning](https://semver.org/)
  - MAJOR.MINOR.PATCH (e.g., 1.0.0)
  - Breaking changes → MAJOR
  - New features → MINOR
  - Bug fixes → PATCH
- [ ] Version number is updated from previous release
- [ ] Version matches what's documented in CHANGELOG

### 4. CHANGELOG Update

**File**: `CHANGELOG.md`

- [ ] [Unreleased] section moved to [X.Y.Z] with release date
- [ ] Changes categorized under:
  - [ ] **Added** - new features
  - [ ] **Changed** - modifications to existing features
  - [ ] **Deprecated** - features to be removed
  - [ ] **Removed** - deleted features
  - [ ] **Fixed** - bug fixes
  - [ ] **Security** - security improvements
- [ ] Each entry is clear and user-focused
- [ ] Breaking changes are clearly marked
- [ ] Links to issues/PRs included where relevant
- [ ] New [Unreleased] section created for next version

**Example**:
```markdown
## [Unreleased]

## [1.0.0] - 2025-01-15
### Added
- Initial release
- OrbStack provider implementation
- SSH integration for interactive sessions
- Machine lifecycle management (up, halt, destroy)

### Fixed
- I18n error parameter passing (#31)
```

### 5. README Review

**File**: `README.md`

- [ ] **Badges** section includes:
  - [ ] Gem Version badge
  - [ ] Build Status badge
  - [ ] Coverage badge (if available)
- [ ] **Installation** section with correct command:
  ```bash
  vagrant plugin install vagrant-orbstack
  ```
- [ ] **Requirements** clearly stated:
  - [ ] OrbStack version
  - [ ] macOS version
  - [ ] Vagrant version
- [ ] **Quick Start** example that works
- [ ] **Configuration** reference or link to docs
- [ ] **Troubleshooting** section with common issues
- [ ] **Support** section with link to issue tracker
- [ ] **License** section with link to LICENSE file
- [ ] **Contributing** section (if accepting contributions)

### 6. Documentation Files

- [ ] `LICENSE` file exists and is correct (MIT)
- [ ] `CONTRIBUTING.md` exists (if accepting contributions)
- [ ] `CODE_OF_CONDUCT.md` exists (optional, recommended)
- [ ] Documentation is up-to-date with latest features
- [ ] Examples in README work with current version

### 7. Test Suite Verification

- [ ] All tests passing: `bundle exec rspec`
- [ ] No pending tests that should be implemented
- [ ] Code coverage is acceptable (>80% recommended)
- [ ] RuboCop violations resolved: `bundle exec rubocop`
- [ ] Pre-push hooks pass successfully

### 8. Build Verification

- [ ] Gem builds successfully:
  ```bash
  gem build vagrant-orbstack.gemspec
  ```
- [ ] No build warnings
- [ ] Gem file size is reasonable (check for accidental inclusions)
- [ ] Inspect gem contents:
  ```bash
  tar -tzf vagrant-orbstack-*.gem | head -50
  ```
- [ ] Verify no test files or development artifacts included

---

## Local Testing

### 9. Local Installation Test

- [ ] Install gem locally:
  ```bash
  vagrant plugin install vagrant-orbstack-0.1.0.gem --local
  ```
- [ ] Verify plugin lists correctly:
  ```bash
  vagrant plugin list | grep orbstack
  ```
- [ ] Test basic workflow:
  - [ ] `vagrant up --provider=orbstack`
  - [ ] `vagrant ssh`
  - [ ] `vagrant halt`
  - [ ] `vagrant destroy`
- [ ] Verify error messages are properly localized (no "Translation missing")
- [ ] Uninstall plugin:
  ```bash
  vagrant plugin uninstall vagrant-orbstack
  ```

### 10. Clean Install Test

- [ ] Test on fresh macOS environment (if possible)
- [ ] Verify all dependencies install correctly
- [ ] Test with minimal Vagrantfile
- [ ] Check for any unexpected warnings or errors

---

## RubyGems Account Setup

### 11. RubyGems Account Verification

- [ ] Account exists on [rubygems.org](https://rubygems.org)
- [ ] Two-Factor Authentication (2FA) enabled
- [ ] Profile information complete
- [ ] API key generated and stored securely
- [ ] Co-maintainers added (if applicable)

### 12. Gem Ownership Verification

- [ ] Gem name `vagrant-orbstack` is available
  ```bash
  gem search -r ^vagrant-orbstack$
  ```
- [ ] If exists, verify you have push permissions
- [ ] If new, be first to claim the name

---

## Git Repository Preparation

### 13. Clean Git State

- [ ] All changes committed to main branch
- [ ] No uncommitted changes: `git status`
- [ ] Branch is up-to-date with remote
- [ ] All PRs merged that should be in release

### 14. Git Tag Creation

- [ ] Create annotated tag:
  ```bash
  git tag -a v0.1.0 -m "Version 0.1.0 - Initial release"
  ```
- [ ] Verify tag:
  ```bash
  git tag -l -n9 v0.1.0
  ```
- [ ] **DO NOT push tags yet** (push after RubyGems publication)

---

## Publication

### 15. RubyGems Publication

- [ ] Build final gem:
  ```bash
  gem build vagrant-orbstack.gemspec
  ```
- [ ] Publish to RubyGems:
  ```bash
  gem push vagrant-orbstack-0.1.0.gem
  ```
- [ ] Verify publication succeeded
- [ ] Check gem page on RubyGems.org within 5 minutes

### 16. RubyGems Verification

- [ ] Gem page accessible: `https://rubygems.org/gems/vagrant-orbstack`
- [ ] Version number correct
- [ ] Metadata displays correctly:
  - [ ] Homepage link
  - [ ] Source code link
  - [ ] Bug tracker link
  - [ ] Changelog link
  - [ ] Documentation link
- [ ] Description readable
- [ ] License shown correctly

### 17. Installation Verification

- [ ] Install from RubyGems:
  ```bash
  vagrant plugin install vagrant-orbstack
  ```
- [ ] Verify correct version installed:
  ```bash
  vagrant plugin list | grep orbstack
  ```
- [ ] Test basic functionality again
- [ ] Uninstall and reinstall to verify repeatability

---

## GitHub Release

### 18. Push Git Tags

- [ ] Push tag to GitHub:
  ```bash
  git push origin v0.1.0
  ```
- [ ] Verify tag appears on GitHub

### 19. Create GitHub Release

- [ ] Navigate to [Releases](https://github.com/spiralhouse/vagrant-orbstack-provider/releases)
- [ ] Click "Draft a new release"
- [ ] Select tag: `v0.1.0`
- [ ] Release title: `v0.1.0 - Initial Release`
- [ ] Copy CHANGELOG entry to description
- [ ] Format with Markdown for readability
- [ ] **Optional**: Attach `.gem` file to release
- [ ] Mark as pre-release if appropriate
- [ ] Click "Publish release"

### 20. Verify GitHub Release

- [ ] Release appears on releases page
- [ ] Changelog content displays correctly
- [ ] Links work (to issues, PRs, etc.)
- [ ] .gem file downloads correctly (if attached)
- [ ] Release is discoverable from repository homepage

---

## Communication & Announcement

### 21. Update Repository Files

- [ ] Update README badges to reflect new version
- [ ] Update any "getting started" version references
- [ ] Commit post-release documentation updates

### 22. Community Announcement

**Optional but recommended**:

- [ ] Submit to community plugin lists:
  - [ ] [Available Vagrant Plugins (GitHub Wiki)](https://github.com/hashicorp/vagrant/wiki/available-vagrant-plugins)
  - [ ] [vagrant-lists.github.io](https://vagrant-lists.github.io/)
  - [ ] [Awesome Vagrant](https://project-awesome.org/iJackUA/awesome-vagrant)
- [ ] Post in GitHub Discussions (if enabled)
- [ ] Announce on social media (Twitter, LinkedIn, etc.)
- [ ] Write blog post or article (optional)

### 23. Documentation Updates

- [ ] Update external documentation (if applicable)
- [ ] Update any tutorials or guides
- [ ] Notify documentation hosting (GitHub Pages, etc.)

---

## Post-Release Monitoring

### 24. Monitor for Issues

- [ ] Watch GitHub issue tracker for bug reports
- [ ] Monitor RubyGems download stats
- [ ] Check for installation issues in first 24-48 hours
- [ ] Respond to community questions promptly

### 25. Prepare for Next Release

- [ ] Create milestone for next version
- [ ] Add [Unreleased] section to CHANGELOG
- [ ] Review feedback for future features
- [ ] Plan next release timeline

---

## Rollback Procedure (If Needed)

If critical issues discovered immediately after release:

### 26. Emergency Rollback

- [ ] Yank broken version from RubyGems:
  ```bash
  gem yank vagrant-orbstack -v 0.1.0
  ```
- [ ] **Warning**: Yanking is permanent and breaks existing users
- [ ] Only yank for security issues or data loss bugs
- [ ] For minor issues, publish patch release instead

### 27. Hotfix Release

- [ ] Create hotfix branch from release tag
- [ ] Fix critical issue
- [ ] Update CHANGELOG with patch notes
- [ ] Increment PATCH version (e.g., 0.1.0 → 0.1.1)
- [ ] Follow full release checklist again
- [ ] Announce hotfix in GitHub Release notes

---

## Version-Specific Notes

### For v0.1.0 (Initial Release)

- [ ] Clearly mark as "initial release" in CHANGELOG
- [ ] Set expectations in README about stability
- [ ] Encourage feedback via issue tracker
- [ ] Monitor closely for first few weeks
- [ ] Be prepared for rapid patch releases

### For v1.0.0 (Stable Release)

- [ ] Ensure all core features complete
- [ ] Comprehensive testing across macOS versions
- [ ] Documentation is production-ready
- [ ] Breaking changes clearly documented
- [ ] Migration guide for v0.x users (if applicable)

### For v2.0.0+ (Major Releases)

- [ ] Migration guide is essential
- [ ] Deprecation warnings in v1.x releases
- [ ] Backwards compatibility strategy
- [ ] Extended testing period (beta, RC)
- [ ] Clear communication about breaking changes

---

## Success Criteria

A successful release meets all of these:

- ✅ Gem published to RubyGems and installable
- ✅ GitHub Release created with complete changelog
- ✅ README badges reflect current version
- ✅ No critical bugs reported in first 48 hours
- ✅ Community can successfully install and use plugin
- ✅ Documentation is accurate and helpful
- ✅ Issue tracker monitored and responsive

---

## Reference Commands

Quick command reference for common tasks:

```bash
# Build gem
gem build vagrant-orbstack.gemspec

# Install locally for testing
vagrant plugin install vagrant-orbstack-*.gem --local

# Publish to RubyGems
gem push vagrant-orbstack-*.gem

# Create and push tag
git tag -a v0.1.0 -m "Version 0.1.0"
git push origin v0.1.0

# Verify installation from RubyGems
vagrant plugin install vagrant-orbstack
vagrant plugin list | grep orbstack

# Yank release (emergency only)
gem yank vagrant-orbstack -v 0.1.0
```

---

## Additional Resources

- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [RubyGems Publishing Guide](https://guides.rubygems.org/publishing/)
- [Vagrant Plugin Development](https://developer.hashicorp.com/vagrant/docs/plugins)
- [PUBLICATION_RESEARCH.md](./PUBLICATION_RESEARCH.md)

---

**Last Updated**: December 29, 2025
**For**: vagrant-orbstack v0.1.0 and future releases
