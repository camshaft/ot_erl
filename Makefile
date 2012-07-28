.PHONY: deps

all: compile

deps:
	@./rebar get-deps

compile:
	@./rebar compile

clean:
	@./rebar clean

test: compile
	@./rebar eunit skip_deps=true