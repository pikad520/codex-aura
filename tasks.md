# Repository preparation

- [x] Inspect the existing standalone app, scripts and tests.
- [x] Copy sources and original assets; adapt test paths to this root.
- [x] Add ignore rules and three-language README, MIT license and descriptions.
- [x] Build locally and run migrated tests.
- [x] Verify documentation links, exclusions and absence of old workspace paths.

Verified on 2026-10-12: local build, Swift checks, renderer and one-shot regressions, two isolated installer tests, code signature, documentation links and Git ignore rules passed. No old workspace paths remain in tracked candidates. Runtime source and texture contents were preserved; only documentation, packaging and test paths changed.
