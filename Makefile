.PHONY: all get format fix lint test docs check

all: check

get:
	dart pub get

format:
	dart format lib test example

fix:
	dart fix --apply
	dart format lib test example

lint:
	dart analyze --fatal-infos

test:
	dart test

docs:
	dart doc --validate-links

check: get
	dart format --set-exit-if-changed lib test example
	dart analyze --fatal-infos
	dart test
