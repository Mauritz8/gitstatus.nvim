.PHONY: test
test:
	busted --coverage --lpath=./lua/?.lua ./test

lint:
	luacheck . --globals vim
