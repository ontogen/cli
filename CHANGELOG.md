# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## v0.1.1 - 2024-08-19

The executables for this release (distributed via Homebrew) are built on a 
machine where the produced binaries support colored output. This hopefully  
ensures that users should experience the intended colored user interface.

### Fixed

- The commands were not adequately protected against execution in an 
  uninitialized repository. As a result, numerous cryptic internal errors 
  became visible to CLI users in this state.


[Compare v0.1.0...v0.1.1](https://github.com/ontogen/cli/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2024-08-08

Initial release
