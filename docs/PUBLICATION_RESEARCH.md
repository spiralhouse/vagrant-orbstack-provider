# Vagrant Plugin Publication Research

**Research Date**: December 29, 2025
**Issue**: [SPI-1288](https://linear.app/spiral-house/issue/SPI-1288)
**Objective**: Understand how established Vagrant provider plugins handle publication and discovery to ensure vagrant-orbstack follows ecosystem conventions.

---

## Executive Summary

**Key Finding**: Providers distributed via RubyGems only (NOT Vagrant Cloud - that's for box files).

**Discovery**: RubyGems.org search, community lists, `gem list --remote vagrant-`

**Common Patterns**: `vagrant-*` naming, README badges, MIT license, `CHANGELOG.md`, gemspec metadata URIs

---

## Discovery Channels

1. RubyGems.org - `vagrant-` search, `vagrant plugin install`
2. Community lists - GitHub wiki, vagrant-lists.github.io, Awesome Vagrant
3. CLI - `gem list --remote vagrant-`

**Vagrant Cloud vs RubyGems**: Plugins = RubyGems only. Box files = Vagrant Cloud. Plugins don't need Vagrant Cloud.

---

## Provider Examples

**vagrant-parallels**: 72 releases, GitHub Pages docs, MIT license, 1k stars
**vagrant-libvirt**: 35 releases, 2.4k stars, 213 contributors, comprehensive README badges
**vagrant-vmware-desktop** (HashiCorp): MPL-2.0 license, 14 releases, dev-focused README

---

## Gemspec Requirements

**Required**: `name` (vagrant-*), `version` (SemVer), `authors`, `email`, `summary`, `description`, `homepage`, `license`, `files`, `require_paths`

**Metadata URIs**: `homepage_uri`, `source_code_uri`, `bug_tracker_uri`, `changelog_uri`, `documentation_uri`, `allowed_push_host`

**Vagrant-specific**: Don't depend on Vagrant gem. Set `required_ruby_version >= 3.0.0`.

**Files**: Include `lib/**/*.rb`, `locales/**/*.yml`, `README.md`, `CHANGELOG.md`, `LICENSE`. Exclude tests, dev tooling, build artifacts.

---

## README Structure

**Sections**: Header with badges (Gem Version, Build Status), Introduction, Requirements, Installation, Quick Start, Docs link, Support, License, Contributing

**Common badges**: Gem version, build status, coverage, code climate

---

## Documentation

**v0.1.0 approach**: Comprehensive README.md with quick start, config reference, troubleshooting. Link to GitHub wiki for extended docs.

**Post-v0.1.0**: Consider GitHub Pages or custom domain based on feedback.

---

## Release Process

**SemVer**: MAJOR.MINOR.PATCH (breaking.features.fixes)

**CHANGELOG.md**: Keep a Changelog format (Unreleased → X.Y.Z with date)

**Steps**:
1. Update version in `lib/vagrant-orbstack/version.rb`
2. Update CHANGELOG
3. Commit, tag (`git tag -a vX.Y.Z`), push with tags
4. Build (`gem build`), publish (`gem push`)
5. Create GitHub Release with CHANGELOG entry
6. Announce

**Automation**: GitHub Actions for auto-publish on tags, Release Drafter for notes

---

## Gemspec Gaps

**Fix needed**:
- Homepage URL (currently placeholder)
- Authors (currently generic)
- Email (currently noreply)
- Add metadata URIs (homepage_uri, source_code_uri, bug_tracker_uri, changelog_uri)
- Create CHANGELOG.md
- Review Ruby version requirement (3.2+ may be too strict, check Vagrant compat)

---

## Pre-Publication Checklist

**Gemspec**: Update homepage, authors, email, add metadata URIs, verify Ruby version, ensure files list complete

**Repo**: Create CHANGELOG.md, enhance README (badges, quick start), verify LICENSE, add CONTRIBUTING.md

**Docs**: Installation instructions, config examples, troubleshooting, issue tracker link

**Testing**: `gem build` succeeds, local install works, plugin loads, basic workflow (up/ssh/halt/destroy)

**RubyGems**: Account with 2FA, API key, co-maintainers

**Release**: Tag (`git tag -a v0.1.0`), GitHub Release, announce

## Publication Steps

1. Build: `gem build vagrant-orbstack.gemspec`
2. Test locally: `vagrant plugin install vagrant-orbstack-0.1.0.gem`
3. Publish: `gem push vagrant-orbstack-0.1.0.gem`
4. Verify on RubyGems.org, test install
5. Announce: GitHub Release, community lists

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
