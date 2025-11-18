# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Machine lifecycle operations (create, start, stop, destroy)
- SSH integration for remote access
- State detection and reporting
- OrbStack CLI wrapper and integration
- Provisioner support (Shell, Ansible, Chef, Puppet)
- Synced folder configuration
- Error handling and recovery mechanisms
- Additional Linux distribution support

## [0.1.0] - 2025-11-17

### Added
- Plugin registration with Vagrant v2 API (SPI-1130)
- Configuration class with provider-specific options:
  - `distro` - Linux distribution selection (default: "ubuntu")
  - `version` - Distribution version specification
  - `machine_name` - Custom machine naming
- Provider class with Vagrant interface implementation (stubs)
- Version constant (`VERSION = "0.1.0"`)
- Comprehensive test suite:
  - 39 passing RSpec tests
  - 100% coverage of implemented features
  - Plugin registration verification
  - Configuration validation tests
  - Provider interface tests
- Development infrastructure:
  - RuboCop configuration for code quality
  - RSpec configuration for testing
  - Bundler setup for dependency management
  - Gemspec for gem packaging
- YARD documentation for all public APIs
- Complete documentation set:
  - README.md - User-facing documentation
  - DEVELOPMENT.md - Contributor guide
  - docs/PRD.md - Product requirements document
  - docs/DESIGN.md - Technical design document
  - docs/TDD.md - Test-driven development workflow
- Project conventions and standards:
  - Trunk-based development workflow
  - Conventional commits format
  - Ruby style guide compliance
  - Test-driven development process

### Technical Details
- Ruby 2.6+ compatibility
- Vagrant 2.2.0+ plugin API v2
- Zero RuboCop offenses
- MIT License
- macOS-only (OrbStack platform requirement)

### Notes
- This is an alpha release with foundational structure only
- Most provider features are stubs awaiting implementation
- Plugin can be installed but does not yet manage machines
- Focus of this release: establishing solid development foundation

## Release History

### Version Numbering
- **0.x.x**: Pre-release / Alpha versions
- **1.0.0**: First stable release with MVP features
- **1.x.x**: Post-MVP enhancements and features

### Upcoming Milestones
- **v0.2.0**: Machine lifecycle implementation (SPI-1132)
- **v0.3.0**: SSH connectivity and state management
- **v0.4.0**: Provisioner support
- **v1.0.0**: Production-ready MVP with full feature set

---

## Contributing

See [DEVELOPMENT.md](./DEVELOPMENT.md) for development guidelines and [CLAUDE.md](./CLAUDE.md) for our agent-based workflow.

[Unreleased]: https://github.com/johnburbridge/vagrant-orbstack-provider/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/johnburbridge/vagrant-orbstack-provider/releases/tag/v0.1.0
