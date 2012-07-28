-module (ot_simple_test).

-compile([export_all]).

-include_lib("eunit/include/eunit.hrl").

name_test()->
  ?assertEqual(simple, ot_simple:name()).

