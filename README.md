# vagrant-orbstack-provider

A Vagrant provider plugin that enables [OrbStack](https://orbstack.dev/) as a backend for managing Linux development environments on macOS.

![Development Status](https://img.shields.io/badge/status-alpha-orange)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Project Overview

OrbStack is a high-performance alternative to traditional VM solutions on macOS, offering:
- Sub-3-second startup times
- Near-zero idle resource consumption
- Native macOS integration with excellent file sharing
- First-class support for Apple Silicon and Intel Macs

This provider allows you to leverage OrbStack's performance while maintaining the familiar Vagrant workflow.

> **Development Status**: This provider is under active development. Most features are not yet implemented. See [Project Status](#project-status) for details.

## Requirements

### System Requirements
- **Operating System**: macOS 12 (Monterey) or later
- **Architecture**: Apple Silicon (ARM64) or Intel (x86_64)
- **Vagrant**: Version 2.2.0 or higher
- **Ruby**: Version 2.6 or higher
- **OrbStack**: Latest stable version with CLI tools installed

### Installation

OrbStack must be installed and running on your system:
1. Download and install [OrbStack](https://orbstack.dev/)
2. Verify OrbStack CLI is available: `orb version`

## Installation

Since the plugin is not yet published to RubyGems, you'll need to build and install it locally:

```bash
# Clone the repository
git clone https://github.com/johnburbridge/vagrant-orbstack-provider.git
cd vagrant-orbstack-provider

# Install dependencies
bundle install

# Build the gem
gem build vagrant-orbstack.gemspec

# Install the plugin locally
vagrant plugin install pkg/vagrant-orbstack-0.1.0.gem
```

Verify the installation:

```bash
vagrant plugin list
```

You should see `vagrant-orbstack (0.1.0)` in the output.

## Quick Start

Create a `Vagrantfile` in your project directory:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu"  # Currently ignored - to be implemented

  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
    os.machine_name = "my-dev-env"
  end
end
```

Basic commands:

```bash
# Create and start the machine
vagrant up --provider=orbstack

# SSH into the machine
vagrant ssh

# Stop the machine
vagrant halt

# Destroy the machine
vagrant destroy
```

> **Important Note**: Most provider features are stubs in v0.1.0. The commands above will execute but machine lifecycle operations are not yet implemented. See [Project Status](#project-status) for what's currently functional.

## Configuration Options

The following configuration options are available in the `config.vm.provider :orbstack` block:

### `distro`
- **Type**: String
- **Default**: `"ubuntu"`
- **Description**: Linux distribution to use for the machine

### `version`
- **Type**: String
- **Default**: `nil`
- **Description**: Distribution version to use (e.g., "22.04")

### `machine_name`
- **Type**: String
- **Default**: `nil` (auto-generated)
- **Description**: Custom name for the OrbStack machine

### Example Configuration

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :orbstack do |os|
    os.distro = "debian"
    os.version = "12"
    os.machine_name = "my-debian-machine"
  end
end
```

## Project Status

### Implemented (v0.1.0)

- Plugin registration and gem structure (SPI-1130)
- Configuration class with `distro`, `version`, `machine_name` attributes
- Provider interface (stubs only)
- Test infrastructure (RSpec)
- YARD documentation for public APIs
- 39 passing tests with 100% coverage of implemented features
- RuboCop clean (0 offenses)

### Planned (MVP - v0.2.0+)

- Machine lifecycle operations (create, start, stop, destroy)
- SSH integration
- State detection and reporting
- OrbStack CLI integration
- Provisioner support
- Synced folder support
- Error handling and recovery

For complete roadmap, see [`docs/PRD.md`](./docs/PRD.md).

## Development

### Setup

```bash
# Clone and setup
git clone https://github.com/johnburbridge/vagrant-orbstack-provider.git
cd vagrant-orbstack-provider
bundle install
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/vagrant-orbstack/provider_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Code Quality

```bash
# Run RuboCop (linter)
bundle exec rubocop

# Auto-fix offenses
bundle exec rubocop -A

# Generate YARD documentation
yard doc
```

### Local Testing

```bash
# Build and install gem locally
gem build vagrant-orbstack.gemspec
vagrant plugin install pkg/vagrant-orbstack-0.1.0.gem

# Create test environment
mkdir test-env && cd test-env
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.provider :orbstack do |os|
    os.distro = "ubuntu"
    os.version = "22.04"
  end
end
EOF

# Test (note: most features are stubs currently)
vagrant up --provider=orbstack
```

## Documentation

- **[Product Requirements (PRD)](./docs/PRD.md)**: Complete feature requirements and roadmap
- **[Technical Design (DESIGN)](./docs/DESIGN.md)**: Architecture and implementation details
- **[TDD Workflow (TDD)](./docs/TDD.md)**: Test-driven development process
- **[Development Guide (DEVELOPMENT)](./DEVELOPMENT.md)**: Contributor documentation

## Contributing

This project follows Test-Driven Development (TDD). See [`CLAUDE.md`](./CLAUDE.md) for our development workflow and [`docs/TDD.md`](./docs/TDD.md) for TDD guidelines.

### Development Workflow

1. Create feature branch: `git checkout -b feat/your-feature`
2. Write tests first (RED phase)
3. Implement feature (GREEN phase)
4. Refactor (REFACTOR phase)
5. Ensure tests pass: `bundle exec rspec`
6. Ensure RuboCop passes: `bundle exec rubocop`
7. Commit with conventional commits: `git commit -m "feat: add feature [SPI-XXX]"`
8. Create pull request

### Conventions

- Follow Ruby community style guide
- Use 2-space indentation
- Write YARD documentation for public methods
- Follow conventional commits format (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`)
- Reference Linear issues in commits: `[SPI-XXX]`

## Support

- **Issues**: [GitHub Issues](https://github.com/johnburbridge/vagrant-orbstack-provider/issues)
- **Discussions**: [GitHub Discussions](https://github.com/johnburbridge/vagrant-orbstack-provider/discussions)

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Acknowledgments

- [Vagrant](https://www.vagrantup.com/) - Development environment management
- [OrbStack](https://orbstack.dev/) - High-performance macOS virtualization
- Vagrant provider implementations for architectural guidance

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and release notes.

---

**Made with ❤️ by the Vagrant OrbStack Provider community**
