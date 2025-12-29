# Vagrant Plugin Publication Research

**Research Date**: December 29, 2025
**Issue**: [SPI-1288](https://linear.app/spiral-house/issue/SPI-1288)
**Objective**: Understand how established Vagrant provider plugins handle publication and discovery to ensure vagrant-orbstack follows ecosystem conventions.

---

## Executive Summary

**Key Finding**: Provider plugins are distributed **exclusively via RubyGems**, not Vagrant Cloud. Vagrant Cloud is only for box file hosting, which is separate from provider plugin distribution.

**Discovery Mechanisms**:
1. **RubyGems.org** (primary) - searchable gem repository
2. **Community Lists** - GitHub wiki, vagrant-lists.github.io, Awesome Vagrant
3. **CLI Search** - `gem list --remote vagrant-`
4. **Documentation** - Vagrant docs and provider-specific sites

**Common Patterns**:
- All plugins use `vagrant-*` naming convention
- README badges for gem version, build status, coverage
- External documentation sites (GitHub Pages, custom domains)
- MIT license is standard
- Comprehensive changelogs (`CHANGELOG.md`)
- Metadata URIs in gemspec for homepage, source, bugs, changelog

---

## Plugin Discovery Analysis

### How Users Find Vagrant Plugins

Based on research from [Available Vagrant Plugins](https://github.com/hashicorp/vagrant/wiki/available-vagrant-plugins), [Vagrant Plugin CLI](https://developer.hashicorp.com/vagrant/docs/cli/plugin), and [vagrant-lists.github.io](https://vagrant-lists.github.io/):

#### 1. RubyGems.org (Primary Channel)
- **Search**: Users search for `vagrant-` prefix on [RubyGems.org](https://rubygems.org)
- **Installation**: `vagrant plugin install vagrant-<name>`
- **Visibility**: Gem description, homepage URL, download stats

#### 2. Community Curated Lists
- **GitHub Wiki**: [Available Vagrant Plugins](https://github.com/hashicorp/vagrant/wiki/available-vagrant-plugins)
- **vagrant-lists.github.io**: Comprehensive plugin directory
- **Awesome Lists**: [Awesome Vagrant](https://project-awesome.org/iJackUA/awesome-vagrant)

#### 3. Command Line Discovery
```bash
gem list --remote vagrant-  # Browse all vagrant plugins
vagrant plugin search <term>  # Not widely supported
```

#### 4. Documentation References
- Vagrant official docs link to popular providers
- Provider-specific documentation sites
- Blog posts and tutorials

### Vagrant Cloud vs RubyGems

**Critical Distinction** (source: [Vagrant Cloud Box Architecture](https://developer.hashicorp.com/vagrant/vagrant-cloud/boxes/architecture)):

| Aspect | Provider Plugins | Box Files |
|--------|------------------|-----------|
| **Distribution** | RubyGems only | Vagrant Cloud OR self-hosted |
| **Discovery** | RubyGems search, community lists | Vagrant Cloud catalog |
| **Installation** | `vagrant plugin install` | `vagrant box add` |
| **Requirements** | None (free) | Vagrant Cloud account for hosting (upgraded tier) |
| **Purpose** | Enables provider functionality | Pre-configured machine images |

**Conclusion**: **Provider plugins do NOT require Vagrant Cloud registration**. We only need RubyGems publication.

---

## Provider Plugin Analysis

### 1. vagrant-parallels

**Repository**: [Parallels/vagrant-parallels](https://github.com/Parallels/vagrant-parallels)
**RubyGems**: [vagrant-parallels](https://rubygems.org/gems/vagrant-parallels)

#### Gemspec Metadata
```ruby
spec.name          = 'vagrant-parallels'
spec.authors       = ['Mikhail Zholobov', 'Youssef Shahin']
spec.email         = ['legal90@gmail.com', 'yshahin@gmail.com']
spec.summary       = 'Parallels provider for Vagrant.'
spec.description   = 'Enables Vagrant to manage Parallels virtual machines.'
spec.homepage      = 'https://github.com/Parallels/vagrant-parallels'
spec.license       = 'MIT'
spec.metadata['rubygems_metadata_key'] = 'vagrant-parallels'
```

#### File Patterns
- `lib/**/*`
- `locales/**/*`
- `README.md`, `CHANGELOG.md`, `LICENSE.txt`

#### Dependencies
- **Runtime**: nokogiri
- **Development**: rake, rspec, rspec-its, webrick

#### README Structure
- Badges: Gem Version, Build Status, Code Climate
- Clear installation instructions
- External documentation link (parallels.github.io/vagrant-parallels/docs/)
- Issue tracker for support
- License and contributor info

#### Key Observations
- **72 releases** with semantic versioning
- External documentation site using GitHub Pages
- Active maintenance with 956 commits
- 1k stars, 91 forks - good community adoption

---

### 2. vagrant-libvirt

**Repository**: [vagrant-libvirt/vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)
**RubyGems**: [vagrant-libvirt](https://rubygems.org/gems/vagrant-libvirt)

#### Gemspec Metadata
```ruby
spec.name          = 'vagrant-libvirt'
spec.license       = 'MIT'
spec.description   = 'libvirt provider for Vagrant'
spec.homepage      = VagrantPlugins::ProviderLibvirt::HOMEPAGE
spec.authors       = ['Lukas Stanek', 'Dima Vasilets', 'Brian Pitts', 'Darragh Bailey']
```

#### File Patterns
- Source: `lib`, `locales`
- Docs: `LICENSE`, `README.md`
- Executables: `bin/` directory

#### Dependencies
- **Runtime**: fog-libvirt (>= 0.6.0), fog-core (~> 2), rexml, xml-simple, diffy, nokogiri (~> 1.6)
- **Development**: rake, rspec-core/expectations/mocks (>= 3.5)

#### README Structure
- Badges: Gitter chat, GitHub Actions, Coveralls, RubyGems version
- QA status matrix showing cross-distro testing
- External docs at vagrant-libvirt.github.io/vagrant-libvirt/
- Gitter chat for community support

#### Key Observations
- **2.4k stars**, 514 forks - highest community adoption
- **213 contributors** - very active community
- **35 releases** with v0.12.2 latest
- Multiple runtime dependencies for libvirt integration

---

### 3. vagrant-vmware-desktop (Official HashiCorp)

**Repository**: [hashicorp/vagrant-vmware-desktop](https://github.com/hashicorp/vagrant-vmware-desktop)
**RubyGems**: vagrant-vmware-desktop

#### README Structure
- **Development-focused** - no end-user installation instructions
- Platform-specific build instructions (Linux/macOS vs Windows)
- Certificate configuration guidance
- Box format specifications

#### Release Process
- **14 releases** with structured tagging (desktop-v3.0.5)
- Separate changelogs: `CHANGELOG-plugin.md`, `CHANGELOG-utility.md`
- `RELEASE.md` file for process documentation

#### License
- **MPL-2.0** (Mozilla Public License 2.0)

#### Key Observations
- Minimal README for end users (assumes docs elsewhere)
- Focus on developer setup
- Coordinated versioning between plugin and utility
- 301 stars, 50 forks

---

## RubyGems Best Practices

Source: [RubyGems Specification Reference](https://guides.rubygems.org/specification-reference/), [Vagrant Plugin Packaging](https://developer.hashicorp.com/vagrant/docs/plugins/packaging)

### Required Fields

```ruby
spec.name          # Must start with 'vagrant-'
spec.version       # Semantic versioning (MAJOR.MINOR.PATCH)
spec.authors       # Array of author names
spec.email         # Array of email addresses
spec.summary       # One-line description (< 140 chars)
spec.description   # Longer description
spec.homepage      # Project homepage URL
spec.license       # 'MIT', 'Apache-2.0', etc.
spec.files         # Files to include in gem
spec.require_paths # Usually ['lib']
```

### Recommended Metadata (2025)

Source: [RubyGems Patterns](https://guides.rubygems.org/patterns/)

```ruby
spec.metadata = {
  "homepage_uri"      => "https://github.com/org/vagrant-plugin",
  "source_code_uri"   => "https://github.com/org/vagrant-plugin",
  "bug_tracker_uri"   => "https://github.com/org/vagrant-plugin/issues",
  "changelog_uri"     => "https://github.com/org/vagrant-plugin/blob/main/CHANGELOG.md",
  "documentation_uri" => "https://docs.example.com",
  "allowed_push_host" => "https://rubygems.org"
}
```

**April 2025 Update**: Gemspec metadata fields are now sorted for reproducible builds (source: [April 2025 RubyGems Updates](https://blog.rubygems.org/2025/05/20/april-rubygems-updates.html))

### Vagrant-Specific Rules

**IMPORTANT** (source: [Vagrant Plugin Packaging](https://developer.hashicorp.com/vagrant/docs/plugins/packaging)):

> "Do not depend on Vagrant for your gem. Vagrant is no longer distributed as a gem, and you can assume that it will always be available when your plugin is installed."

**Required Ruby Version**:
- Vagrant 2.2+ requires Ruby 2.7+
- Vagrant 2.3+ requires Ruby 3.0+
- Specify: `spec.required_ruby_version = '>= 3.0.0'`

### File Inclusion Best Practices

```ruby
spec.files = Dir['lib/**/*.rb', 'locales/**/*.yml'] + [
  'README.md',
  'CHANGELOG.md',
  'LICENSE',
  'LICENSE.txt'  # Some prefer .txt extension
]
```

**Include**:
- All `lib/**/*.rb` source files
- All `locales/**/*.yml` I18n files
- Documentation: `README.md`, `CHANGELOG.md`
- License file (required)

**Exclude**:
- Test files (`spec/**/*`, `test/**/*`)
- Development tooling (`.github/**/*`, `.git`, `.rspec`)
- Build artifacts (`pkg/`, `.gem`)
- Local config (`.env`, `Vagrantfile`)

---

## README Best Practices

### Essential Sections

Based on analysis of top providers:

1. **Header with Badges**
   ```markdown
   # Vagrant OrbStack Provider

   [![Gem Version](https://badge.fury.io/rb/vagrant-orbstack.svg)](https://badge.fury.io/rb/vagrant-orbstack)
   [![Build Status](https://github.com/org/vagrant-orbstack/workflows/CI/badge.svg)](https://github.com/org/vagrant-orbstack/actions)
   ```

2. **Introduction**
   - What is this plugin?
   - Why use it?
   - Key benefits vs alternatives

3. **Requirements**
   - OrbStack version
   - macOS version
   - Vagrant version

4. **Installation**
   ```bash
   vagrant plugin install vagrant-orbstack
   ```

5. **Quick Start**
   ```ruby
   Vagrant.configure("2") do |config|
     config.vm.box = "ubuntu/noble64"
     config.vm.provider :orbstack do |os|
       # Provider configuration
     end
   end
   ```

6. **Documentation Link**
   - Link to full docs (GitHub Pages or custom site)
   - Link to examples

7. **Support/Community**
   - Issue tracker
   - Discussions (if enabled)
   - Gitter/Discord (optional)

8. **License**
   - Clear license statement
   - Link to LICENSE file

9. **Contributing**
   - Link to CONTRIBUTING.md
   - Contributor list (optional)

### Badge Options

Common badges for Vagrant plugins:
- **Gem Version**: `https://badge.fury.io/rb/vagrant-<name>.svg`
- **Build Status**: GitHub Actions workflow badge
- **Code Coverage**: Coveralls, Codecov
- **Code Climate**: Maintainability score
- **Gitter Chat**: Community chat (optional)

---

## Documentation Hosting

### Options Analysis

| Option | Used By | Pros | Cons |
|--------|---------|------|------|
| **GitHub Pages** | vagrant-parallels, vagrant-libvirt | Free, integrated, versioned | Requires setup |
| **README.md only** | vagrant-vmware-desktop | Simple, no extra hosting | Limited for complex docs |
| **Custom Domain** | Some providers | Professional, flexible | Cost, maintenance |

### Recommendation for v0.1.0

**Start with comprehensive README.md**:
- Quick start example
- Configuration reference
- Troubleshooting section
- Link to GitHub wiki for extended docs

**Defer to post-v0.1.0**:
- GitHub Pages site
- Custom domain
- Interactive documentation

**Rationale**: Get feedback first, then invest in documentation infrastructure.

---

## Release Process Patterns

### Semantic Versioning

All analyzed plugins use [SemVer](https://semver.org/):
- **MAJOR**: Breaking changes (v1.0.0 → v2.0.0)
- **MINOR**: New features, backward-compatible (v1.1.0 → v1.2.0)
- **PATCH**: Bug fixes (v1.1.0 → v1.1.1)
- **Pre-release**: v1.0.0-beta.1, v1.0.0-rc.2

### CHANGELOG.md

Common format (based on [Keep a Changelog](https://keepachangelog.com/)):

```markdown
# Changelog

## [Unreleased]
### Added
### Changed
### Fixed

## [1.0.0] - 2025-01-15
### Added
- Initial release
- OrbStack provider implementation
- SSH integration
```

### Release Steps (Common Pattern)

1. **Update Version**
   - `lib/vagrant-orbstack/version.rb`

2. **Update CHANGELOG**
   - Move [Unreleased] to [X.Y.Z] with date
   - List changes under Added/Changed/Fixed/Removed

3. **Commit and Tag**
   ```bash
   git commit -m "Release v1.0.0"
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin main --tags
   ```

4. **Build and Publish Gem**
   ```bash
   gem build vagrant-orbstack.gemspec
   gem push vagrant-orbstack-1.0.0.gem
   ```

5. **Create GitHub Release**
   - Use tag v1.0.0
   - Copy CHANGELOG entry
   - Attach .gem file (optional)

6. **Announce**
   - GitHub Discussions
   - Vagrant mailing list (if applicable)
   - Social media

### Automation Options

- **GitHub Actions**: Auto-publish to RubyGems on tag push
- **Release Drafter**: Auto-generate release notes from PRs
- **Conventional Commits**: Auto-update CHANGELOG from commit messages

---

## Current Gemspec Gap Analysis

### Our Current State
```ruby
spec.name          = 'vagrant-orbstack'
spec.version       = VagrantPlugins::OrbStack::VERSION
spec.authors       = ['Vagrant OrbStack Contributors']
spec.email         = ['noreply@example.com']
spec.summary       = 'Vagrant provider for OrbStack'
spec.description   = 'Enables OrbStack as a Vagrant provider for managing Linux development environments on macOS'
spec.homepage      = 'https://github.com/example/vagrant-orbstack-provider'
spec.license       = 'MIT'
spec.required_ruby_version = '>= 3.2.0'
spec.files         = Dir['lib/**/*.rb', 'locales/**/*.yml'] + ['README.md', 'LICENSE']
spec.require_paths = ['lib']
```

### Required Fixes

#### 1. Update Homepage URL ❌
**Current**: `https://github.com/example/vagrant-orbstack-provider`
**Required**: Actual GitHub repository URL

#### 2. Update Authors ❌
**Current**: `['Vagrant OrbStack Contributors']`
**Recommendation**: Actual maintainer names

#### 3. Update Email ❌
**Current**: `['noreply@example.com']`
**Recommendation**: Real contact email or GitHub-based

#### 4. Add Metadata URIs ❌
**Missing**:
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

#### 5. Add CHANGELOG.md ❌
**Missing**: No CHANGELOG.md file in repository

#### 6. Verify LICENSE ✅
**Status**: LICENSE file exists (MIT)

#### 7. Downgrade Ruby Requirement? ⚠️
**Current**: `>= 3.2.0`
**Consideration**: Vagrant 2.4.x supports Ruby 2.7+
**Risk**: Requiring 3.2+ may limit compatibility
**Recommendation**: Research Vagrant's current Ruby requirement

---

## Recommendations for vagrant-orbstack

### Pre-Publication Checklist

#### Gemspec Updates
- [ ] Update `spec.homepage` to actual GitHub URL
- [ ] Update `spec.authors` with maintainer names
- [ ] Update `spec.email` with contact email
- [ ] Add `spec.metadata` with all URI fields
- [ ] Verify `spec.required_ruby_version` aligns with Vagrant support
- [ ] Ensure `spec.files` includes all necessary files

#### Repository Files
- [ ] Create comprehensive `CHANGELOG.md`
- [ ] Enhance `README.md` with badges, quick start, examples
- [ ] Verify `LICENSE` file is present and correct
- [ ] Add `CONTRIBUTING.md` (if accepting contributions)

#### Documentation
- [ ] Add installation instructions to README
- [ ] Include configuration examples
- [ ] Document troubleshooting common issues
- [ ] Link to issue tracker for support

#### Testing
- [ ] Verify `gem build vagrant-orbstack.gemspec` succeeds
- [ ] Test local installation: `vagrant plugin install vagrant-orbstack-0.1.0.gem`
- [ ] Verify plugin loads correctly
- [ ] Test basic workflow (up, ssh, halt, destroy)

#### RubyGems Account
- [ ] Create account on rubygems.org (if not exists)
- [ ] Enable 2FA for security
- [ ] Generate API key for publishing
- [ ] Consider adding co-maintainers

#### GitHub Release
- [ ] Create release notes from CHANGELOG
- [ ] Tag release: `git tag -a v0.1.0 -m "Initial release"`
- [ ] Push tags: `git push --tags`
- [ ] Create GitHub Release with notes
- [ ] Attach .gem file to release (optional)

### Publication Steps

1. **Build Gem**
   ```bash
   gem build vagrant-orbstack.gemspec
   ```

2. **Test Locally**
   ```bash
   vagrant plugin install vagrant-orbstack-0.1.0.gem
   # Test functionality
   vagrant plugin uninstall vagrant-orbstack
   ```

3. **Publish to RubyGems**
   ```bash
   gem push vagrant-orbstack-0.1.0.gem
   ```

4. **Verify on RubyGems**
   - Check gem page appears: https://rubygems.org/gems/vagrant-orbstack
   - Verify metadata displays correctly
   - Test installation: `vagrant plugin install vagrant-orbstack`

5. **Announce**
   - GitHub Release
   - Update README with installation instructions
   - Submit to community lists (Awesome Vagrant, vagrant-lists.github.io)

### Post-Publication

- Monitor issue tracker for bug reports
- Respond to community questions
- Plan next release based on feedback
- Consider GitHub Pages documentation for v0.2.0+

---

## References

### Documentation
- [Vagrant Plugin Development](https://developer.hashicorp.com/vagrant/docs/plugins)
- [Vagrant Plugin Packaging](https://developer.hashicorp.com/vagrant/docs/plugins/packaging)
- [RubyGems Specification Reference](https://guides.rubygems.org/specification-reference/)
- [RubyGems Patterns](https://guides.rubygems.org/patterns/)

### Community Resources
- [Available Vagrant Plugins (GitHub Wiki)](https://github.com/hashicorp/vagrant/wiki/available-vagrant-plugins)
- [vagrant-lists.github.io](https://vagrant-lists.github.io/)
- [Awesome Vagrant](https://project-awesome.org/iJackUA/awesome-vagrant)

### Provider Examples
- [vagrant-parallels](https://github.com/Parallels/vagrant-parallels)
- [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)
- [vagrant-vmware-desktop](https://github.com/hashicorp/vagrant-vmware-desktop)

### Tools
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Shields.io](https://shields.io/) - Badge generation

---

**Research completed**: December 29, 2025
**Next steps**: Create `RELEASE_CHECKLIST.md` and update SPI-1129 epic with implementation tasks.
