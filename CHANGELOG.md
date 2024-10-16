# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## v0.1.3 - 2024-10-16

This version includes important dependency updates:

- Ontogen v0.1.2 removes timeouts that may occur when dealing with larger
  amounts of data and improves some error messages (see the [full Ontogen changelog](https://github.com/ontogen/ontogen/blob/main/CHANGELOG.md))
- RDF.ex v2.0.1 fixes a bug in the Turtle/TriG encoder
- tzdata v1.1.2 fixes an error in the previous version where the :tzdata_release_updater
  was terminating unexpectedly

[Compare v0.1.2...v0.1.3](https://github.com/ontogen/cli/compare/v0.1.2...v0.1.3)



## v0.1.2 - 2024-08-20

### Fixed

- Update to Ontogen v0.1.1, replacing remaining `IO.ANSI.enabled?/0` checks
  with `Ontogen.ansi_enabled?/0`. This completes the transition started in CLI v0.1.1,
  ensuring consistent color output across all build environments, 
  including CI-built executables.

[Compare v0.1.1...v0.1.2](https://github.com/ontogen/cli/compare/v0.1.1...v0.1.2)




## v0.1.1 - 2024-08-19

### Fixed

- The commands were not adequately protected against execution in an 
  uninitialized repository. As a result, numerous cryptic internal errors 
  became visible to CLI users in this state.


[Compare v0.1.0...v0.1.1](https://github.com/ontogen/cli/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2024-08-08

Initial release
