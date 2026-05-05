.PHONY: test
test:
	busted --coverage --lpath=./lua/?.lua ./test

.PHONY: lint
lint:
	stylua --check . && luacheck .

.PHONY: format
format:
	stylua .
