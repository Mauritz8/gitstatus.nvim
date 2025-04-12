.PHONY: test
test:
	busted --coverage --lpath=./lua/?.lua ./test

.PHONY: lint
lint:
	luacheck . --globals vim

.PHONY: format
format:
	stylua .
