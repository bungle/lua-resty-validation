# Changelog

All notable changes to `lua-resty-validation` will be documented in this file.

## [2.6] - 2017-02-05
### Added
- Added callable validator
- Added requisite and requisites group validators
  (see also: https://github.com/bungle/lua-resty-validation/issues/3)

## [2.5] - 2016-09-29
### Added
- Support for the official OpenResty package manager (opm).

### Changed
- Changed the change log format to keep-a-changelog.

## [2.4] - 2016-09-16
### Added
- Added support for custom (inline) validators.
- Added resty.validation.injection extension (uses libinjection).

## [2.3] - 2016-03-22
### Added
- Added resty.validation.utf8 extension (uses utf8rewind).

## [2.2] - 2015-11-27
### Fixed
- There was a typo in a code that leaked a global variable in fields:__call method.

## [2.1] - 2015-10-10
### Fixed
- Fixed leaking global new function.

## [2.1] - 2015-10-10
### Changed
- Total rewrite.

## [1.0] - 2014-08-28
### Added
- LuaRocks support via MoonRocks.
