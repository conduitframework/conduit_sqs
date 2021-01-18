# Changelog

## 0.3.1 (2021-01-18)

- Support GenStage 1.X

## 0.3.0 (2019-04-30)

### Changed

- GenStage upgraded to 0.14.X

## 0.2.7 (2019-03-13)

### Fixed

- Handle [message that hackney is leaking](https://github.com/benoitc/hackney/issues/464) so poller doesn't crash.

## 0.2.6 (2018-08-12)

### Added

- More loggin around queue creation and polling

## 0.2.5 (2018-06-08)

### Fixed

- Subscriber options weren't being passed to GenStage worker

## 0.2.4 (2018-06-07)

### Added

- Ability to pass `:region` option at multiple levels

## 0.2.3 (2018-05-27)

### Fixed

- Use exponential backoff and try forever to create queues and request messages

### Added

- Can now specify backoff options globally and per action

## 0.2.2 (2018-05-12)

### Fixed

- Add poison as dependency for ExAws

## 0.2.1 (2018-05-12)

### Fixed

- Poller supervisor wasn't passing along queue name

## 0.2.0 (2018-04-15)

### Changed

- Support new ExAws

## 0.1.0 (2017-10-28)

- Initial version
