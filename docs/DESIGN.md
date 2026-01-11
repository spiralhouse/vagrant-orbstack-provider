# Design Document: Vagrant OrbStack Provider

## Overview

This document describes the technical design and architecture of the Vagrant OrbStack provider plugin.

## Architecture

User → Vagrant → Provider Plugin → OrbStack CLI → OrbStack Engine → Linux Machine

**Components:**
- Plugin: Registers with Vagrant
- Config: `distro`, `version`, `machine_name`
- Provider: Delegates to action middleware
- Actions: Create, Destroy, Halt, Start, Reload, SSH

## Component Design

### Provider Class

**Methods**: `action(name)`, `ssh_info`, `state`, `to_s`

**Storage**: `.vagrant/machines/<name>/orbstack/id` and `metadata.json`

**Metadata API**: `read/write_machine_id`, `read/write_metadata`, `machine_id_changed` callback

### Configuration Class

| Option | Default | Validation |
|--------|---------|------------|
| `distro` | `"ubuntu"` | Must be supported distro |
| `version` | Latest | Must be valid for distro |
| `machine_name` | Auto-generated | Must follow OrbStack naming rules |

### Action Middleware

**Create**: Validates config, executes `orb create`, stores metadata
**Destroy**: Executes `orb delete`, removes metadata
**Halt**: `orb stop`, invalidates state cache
**Start**: `orb start`, invalidates state cache
**Reload**: Composition action (Halt → Start → optional Provision)
**SSH Info**: Returns `{host, port, username, private_key_path}` for OrbStack SSH proxy

### Action Patterns

**Direct Actions** (Create, Halt, Start, Destroy):
- Include `MachineValidation` module
- Call `Util::OrbStackCLI` methods
- Invalidate state cache
- Provide UI feedback

**Composition Actions** (Reload):
- Orchestrate existing actions via `Action::Builder`
- No direct CLI calls
- Delegate state management to composed actions

## Integration Points

### Vagrant Plugin System

Gem name `vagrant-orbstack`, provider name `orbstack`. Auto-discovered via `vagrant-` prefix.

### OrbStack CLI

Execute via `Vagrant::Util::Subprocess`, parse stdout/stderr/exit_code. Commands: `create`, `delete`, `start`, `stop`, `list`, `info`.

### SSH Integration

**CRITICAL**: OrbStack uses SSH proxy, NOT direct VM IP connections.

**Required ssh_info() return**:
```ruby
{
  host: '127.0.0.1',              # NOT VM IP
  port: 32222,                    # OrbStack SSH proxy port
  username: @machine.id,          # Machine ID for proxy routing
  private_key_path: '~/.orbstack/ssh/id_ed25519'
}
```

**Connection syntax**: `ssh <machine-id>@orb`

**User mapping**: OrbStack creates user matching macOS username (NOT "vagrant"). Get via `orb info <id> --format json | jq -r '.record.config.default_username'`

**Docs**: https://docs.orbstack.dev/machines/ssh

## Technical Decisions

**CLI Interface**: Use OrbStack CLI exclusively (stable, documented, aligns with user workflows)

**State Caching**: 5-second cache for state queries (reduces latency), invalidate on state changes

**Machine Naming**: `vagrant-<machine-name>-<short-id>` (predictable, avoids collisions)

**Distribution Mapping**: Explicit config (no magic box-to-distro mapping)

**Synced Folders**: Document OrbStack's native `/mnt/mac` and `~/OrbStack` (defer automatic mounting - YAGNI)

## Implementation Considerations

### Error Handling

**Dependency**: Detect missing `orb`, provide install instructions
**Configuration**: Validate early, clear error messages
**Operational**: Parse OrbStack errors, suggest fixes, cleanup partial state
**State**: Idempotent operations, log warnings not errors

### Testing

See `docs/TDD.md`. 70% unit / 20% integration / 10% E2E.

### Logging

Debug: CLI commands, cache, state transitions
Info: Operations, config, SSH details
Warn: Unexpected conditions, deprecated options
Error: Failures, invalid configs

### Security

Use OrbStack's SSH keys (don't generate). Sanitize input, use `Vagrant::Util::Subprocess`. Store minimal metadata, cleanup on destroy.

## References

### Vagrant Provider Development
- [Provider Plugin Documentation](https://developer.hashicorp.com/vagrant/docs/plugins/providers)
- [Plugin Development Guide](https://developer.hashicorp.com/vagrant/docs/plugins)

### OrbStack Integration
- [OrbStack CLI Commands](https://docs.orbstack.dev/machines/commands)
- [Linux Machines Guide](https://docs.orbstack.dev/machines/)
- [OrbStack SSH Documentation](https://docs.orbstack.dev/machines/ssh)

---

**Note**: This design document evolves as implementation progresses and new insights emerge.
