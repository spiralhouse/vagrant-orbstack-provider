# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0](https://github.com/spiralhouse/vagrant-orbstack-provider/compare/v0.1.0...v0.2.0) (2026-01-03)


### Features

* add automated release workflow with RubyGems Trusted Publishing ([#38](https://github.com/spiralhouse/vagrant-orbstack-provider/issues/38)) ([eb4aef0](https://github.com/spiralhouse/vagrant-orbstack-provider/commit/eb4aef070b656d5ec8fa4adaefb31aa991e39332))
* implement automated release versioning with Release-Please [SPI-1294] ([#39](https://github.com/spiralhouse/vagrant-orbstack-provider/issues/39)) ([bfc560a](https://github.com/spiralhouse/vagrant-orbstack-provider/commit/bfc560a15f3a50dec498bd7f9233a57efe4557c1))


### Bug Fixes

* resolve E2E SSH test failures [SPI-1301] ([#41](https://github.com/spiralhouse/vagrant-orbstack-provider/issues/41)) ([19fbdf3](https://github.com/spiralhouse/vagrant-orbstack-provider/commit/19fbdf3d89b322c1bd9a52ba865523312b08a30e))

## [Unreleased]

### Added

### Changed

### Fixed

## [0.1.0] - 2026-01-01

### Added

- **SSH Connectivity** ([SPI-1225](https://linear.app/spiral-house/issue/SPI-1225))
  - Implemented Provider#ssh_info method for SSH connection parameters
  - Added OrbStack SSH proxy architecture support (localhost:32222 with ProxyCommand)
  - Enabled SSH agent forwarding via `forward_agent` configuration attribute
  - Configured automatic SSH key path resolution (~/.orbstack/ssh/id_ed25519)
  - `vagrant ssh-config` command generates correct SSH configuration
  - Direct SSH access works using Vagrant-generated configuration
  - SSH readiness waiting after machine boot ([SPI-1226](https://linear.app/spiral-house/issue/SPI-1226))
  - SSH verification tests ([SPI-1227](https://linear.app/spiral-house/issue/SPI-1227))
  - SSH run action for `vagrant ssh -c` ([SPI-1240](https://linear.app/spiral-house/issue/SPI-1240))
  - SSH error handling ([SPI-1224](https://linear.app/spiral-house/issue/SPI-1224))
  - `ssh_username` configuration attribute ([SPI-1222](https://linear.app/spiral-house/issue/SPI-1222))

- **Machine Lifecycle Management**
  - `vagrant up --provider=orbstack` creates and starts OrbStack machines ([SPI-1200](https://linear.app/spiral-house/issue/SPI-1200))
  - `vagrant halt` stops running machines ([SPI-1201](https://linear.app/spiral-house/issue/SPI-1201))
  - `vagrant destroy` removes machines and cleans up metadata ([SPI-1203](https://linear.app/spiral-house/issue/SPI-1203))
  - `vagrant reload` restarts machines with fresh configuration ([SPI-1202](https://linear.app/spiral-house/issue/SPI-1202))
  - Automatic machine naming with format `vagrant-<name>-<short-id>`
  - Idempotent operations (safe to run commands multiple times)
  - Multi-machine support with unique name collision avoidance
  - State-aware operations (checks machine state before acting)

- **Machine State Query** ([SPI-1199](https://linear.app/spiral-house/issue/SPI-1199))
  - Provider#state method returns accurate Vagrant::MachineState
  - StateCache utility class with 5-second TTL for performance optimization
  - State mapping: OrbStack states (running, stopped) → Vagrant states (:running, :stopped, :not_created)
  - `vagrant status` command works correctly
  - Cache invalidation support for fresh state queries

- **OrbStack CLI Integration** ([SPI-1198](https://linear.app/spiral-house/issue/SPI-1198))
  - `list_machines` - retrieve all OrbStack machines
  - `machine_info(name)` - query specific machine details
  - `create_machine(name, distribution:)` - create new machines
  - `start_machine(name)` - start stopped machines
  - `stop_machine(name)` - stop running machines
  - `delete_machine(name)` - remove machines
  - Command execution with timeout support (default 30 seconds)
  - Error handling (CommandTimeoutError, CommandExecutionError)
  - OrbStack detection and availability checking

- **Configuration**
  - `distro` - Linux distribution selection (default: "ubuntu")
  - `version` - Distribution version specification
  - `machine_name` - Custom machine naming
  - `ssh_username` - SSH username configuration
  - `forward_agent` - SSH agent forwarding control

- **Error Handling**
  - I18n error messages and localization
  - OrbStackNotInstalled error
  - OrbStackNotRunning error
  - CommandExecutionError for CLI failures
  - CommandTimeoutError for CLI timeouts
  - SSHNotReady error for SSH connectivity issues
  - SSHConnectionFailed error

- **Development Infrastructure**
  - Comprehensive test suite (617 passing tests)
  - RuboCop configuration and compliance
  - Git pre-push hooks for quality gates
  - CI/CD pipeline with GitHub Actions
  - YARD documentation
  - Test coverage reporting

### Fixed

- I18n parameter passing in error classes ([SPI-1272](https://linear.app/spiral-house/issue/SPI-1272))
- Plugin loading errors ([SPI-1220](https://linear.app/spiral-house/issue/SPI-1220))
- E2E test exclusion from default rake task ([SPI-1278](https://linear.app/spiral-house/issue/SPI-1278))

### Changed

- Gemspec metadata updated for RubyGems publication ([SPI-1289](https://linear.app/spiral-house/issue/SPI-1289))
  - Real author, email, homepage (Spiral House organization)
  - Complete metadata hash with 6 required URIs
  - `allowed_push_host` restriction to rubygems.org

### Known Limitations

- Box support not yet implemented (must use distribution-based creation)
- Synced folders not yet supported
- Networking configuration limited to OrbStack defaults
- Provisioners tested but not all scenarios covered
- macOS-only (OrbStack platform requirement)

## [0.0.1] - 2025-11-17

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

[Unreleased]: https://github.com/spiralhouse/vagrant-orbstack-provider/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/spiralhouse/vagrant-orbstack-provider/releases/tag/v0.1.0
[0.0.1]: https://github.com/spiralhouse/vagrant-orbstack-provider/releases/tag/v0.0.1
