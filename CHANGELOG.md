# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


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
