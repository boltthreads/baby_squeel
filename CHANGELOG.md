## [Unreleased]

Nothing to see yet!

## [1.1.0] - 2017-02-10
> This version drops support for Active Record 4.1. If you're stil on 4.1, you should seriously consider upgrading to at least 4.2.

### Added
- DSLs for ActiveRecord::Relation::Calculations. You can now use `plucking`, `counting`, `summing`, `averaging`, `minimizing`, and `maximizing`.

## [1.0.3] - 2017-02-09
### Added
- Support for `pluck`.
- Support for `not_in`.

## [1.0.2] - 2017-02-07
### Added
- `BabySqueel::Association` now has `#==` and `#!=`. This is only supported for Rails 5+. Example: `Post.where { author: Author.last }`.

### Fixed
- Incorrect alias detection caused by not tracking the full path to a join (#37).

## [1.0.1] - 2016-11-07
### Added
- Add DSL#_ for wrapping expressions in Arel::Node::Grouping. Thanks to [@odedniv].

### Fixed
- Use strings for attribute names like Rails does. Symbols were preventing things like `unscope` from working. Thanks to [@chewi].
- `where.has {}` will now accept `nil`.
- Arel::Nodes::Function did not previously include Arel::Math, so now you can do math operations on the result of SQL functions.
- Arel::Nodes::Binary did not previously include Arel::AliasPredication. Binary nodes can now be aliased using `as`.

## [1.0.0] - 2016-09-09
### Added
- Polyamorous. Unfortunately, this *does* monkey-patch Active Record internals, but there just isn't any other reliable way to generate outer joins. Baby Squeel, itself, will still keep monkey patching to an absolute minimum.
- Within DSL blocks, you can use `exists` and `not_exists` with Active Record relations. For example: `Post.where.has { exists Post.where(title: 'Fun') }`.`
- Support for polymorphic associations.

### Deprecations
- Removed support for Active Record 4.0.x

### Changed
- BabySqueel::JoinDependency is no longer a class responsible for creating Arel joins. It is now a namespace for utilities used when working with the ActiveRecord::Association::JoinDependency class.
- BabySqueel::Nodes::Generic is now BabySqueel::Nodes::Node.
- Arel nodes are only extended with the behaviors they need. Previously, all Arel nodes were being extended with `Arel::AliasPredication`, `Arel::OrderPredications`, and `Arel::Math`.

### Fixed
- Fixed deprecation warnings on Active Record 5 when initializing an Arel::Table without a type caster.
- No more duplicate joins. Previously, Baby Squeel did a very poor job of ensuring that you didn't join an association twice.
- Alias detection should now *actually* work. The previous implementation was naive.

## [0.3.1] - 2016-08-02
### Added
- Ported backticks and #my from Squeel

### Changed
- DSL#sql now returns a node wrapped in a BabySqueel proxy.

## [0.3.0] - 2016-06-26
### Added
- Added Squeel compatibility mode that allows `select`, `order`, `joins`, `group`, `where`, and `having` to accept DSL blocks.
- Added the ability to query tables that aren't backed by Active Record models.
- Added `BabySqueel::[]`, which provides a `BabySqueel::Relation` for models, or a `BabySqueel::Table` for symbols/strings.

### Changed
- Renamed `BabySqueel::Association::AliasingError` to `BabySqueel::AssociationAliasingError`.

## [0.2.2] - 2016-03-30
### Added
- Support for `group` (`grouping`) and `having` (`when_having`).
- Support for sifters.
- Added `quoted` and `sql` helpers for quoting strings and SQL literals.
- More descriptive error messages when a column or association is not found.

### Fixed
- `Arel::Nodes::Grouping` does not include `Arel::Math`, so operations like `(id + 5) + 3` would fail unexpectedly.
- Fix missing bind values When joining through associations with default scope.
- Removed `ActiveRecord::VERSION` specific handling of the `WhereChain`.

## [0.2.1] - 2016-03-27
### Added
- Support for subqueries.

### Fixed
- Some Arel nodes did not have access to `as` expressions.

## [0.2.0] - 2016-03-25
### Added
- References to aliased joins in a `select`, `where`, or `order` expression now use the aliased table name.

### Changed
- Rely on `ActiveRecord::Relation#join_sources` for the implicit construction of join nodes, rather than using the `ActiveRecord::Associations::JoinDependency` directly.

### Fixed

- Associations referencing the same table weren't being aliased.

## [0.1.0] - 2016-03-16
### Added
- Initial support for selects, orders, wheres, and joins.

[Unreleased]: https://github.com/rzane/baby_squeel/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/rzane/baby_squeel/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/rzane/baby_squeel/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/rzane/baby_squeel/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/rzane/baby_squeel/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/rzane/baby_squeel/compare/v0.3.1...v1.0.0
[0.3.1]: https://github.com/rzane/baby_squeel/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/rzane/baby_squeel/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/rzane/baby_squeel/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/rzane/baby_squeel/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/rzane/baby_squeel/compare/v0.1.0...v0.2.0

[@chewi]: https://github.com/chewi
[@odedniv]: https://github.com/odedniv
