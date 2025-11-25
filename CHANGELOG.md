# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Machine state query implementation (SPI-1199):
  - Provider#state method returns accurate Vagrant::MachineState by querying OrbStack CLI
  - StateCache utility class with 5-second TTL for performance optimization
  - State mapping: OrbStack states (running, stopped) → Vagrant states (:running, :stopped, :not_created)
  - Cache invalidation support (per-key via `invalidate(key)` and global via `invalidate_all`)
  - Graceful error handling for CLI failures and timeouts
- OrbStack CLI integration wrapper (partial):
  - `list_machines` method for retrieving all OrbStack machines
  - `machine_info(name)` method for querying specific machine details
  - Command execution with timeout support (default 30 seconds)
  - Error handling (CommandTimeoutError, CommandExecutionError)
- Comprehensive test coverage:
  - 67 new tests for state management (35 StateCache unit tests + 32 Provider state tests)
  - 283 total tests passing (up from 39 in v0.1.0)
  - 100% coverage of implemented state management features

### Changed
- Provider interface: `state()` method fully implemented (was stub in v0.1.0)
- `vagrant status` command now works and returns accurate machine state

### Planned
- Machine lifecycle operations (create, start, stop, destroy)
- SSH integration for remote access
- OrbStack CLI wrapper completion (create, delete, start, stop commands)
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
