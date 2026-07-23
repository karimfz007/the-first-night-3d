# Operations protocol v1.3

## Authority

The project lead can decide routine implementation, dependencies, organization,
refactors, tests, and recoverable technical tradeoffs. Escalation is reserved
for changes to identity, camera, visual direction, commercial strategy, major
gameplay philosophy, external authentication, or irreversible remote history.

## Cycle

1. Read canon, current state, decisions, and latest audit.
2. Select the smallest complete player-facing outcome.
3. Audit maintained libraries before implementing generic infrastructure.
4. Keep tunables centralized and simulation scene-free.
5. Implement with continuous headless checks.
6. Export web, Windows, and Android from the same commit.
7. Run an independent acceptance audit.
8. Record as-built behavior, limitations, and next slice.

## Branch and repository discipline

- Default branch: `main`.
- `main` must stay buildable; risky dependency experiments remain isolated.
- Pull requests require the `verify-and-export` check.
- Large art/audio uses Git LFS.
- Secrets, signing credentials, `.godot`, and export products are never
  committed.
- Version tags are immutable and generate prerelease artifacts.

## Quality rules

- Save schema changes require migrations and corrupt-save recovery.
- Any offline rule needs deterministic tests at boundary durations.
- Every audio cue has a visual equivalent.
- No interaction relies on haptics.
- Performance claims require profiler/device evidence.
- Failed package evaluations remain in the dependency ledger.
- An audit is independent only when performed from a clean process/context
  against the actual repository state.

## Definition of done

Code, data, tests, documentation, export configuration, and audit evidence are
all committed. A local scene that has not passed CI exports is not a delivered
build.

