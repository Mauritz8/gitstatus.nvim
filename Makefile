.PHONY: test
test:
	busted --coverage --lpath=./lua/?.lua ./test

.PHONY: lint
lint:
	stylua --check . && luacheck . --globals vim && lua-language-server --check .

.PHONY: format
format:
	stylua .
