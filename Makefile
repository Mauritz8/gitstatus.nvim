.PHONY: test
test:
	busted --coverage --lpath=./lua/?.lua ./test
