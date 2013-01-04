-module (ot_text_test).

-compile([export_all]).

-include_lib("eunit/include/eunit.hrl").

name_test()->
  ?assertEqual(text, ot_text:name()).

create_test()->
  ?assertEqual(<<"">>, ot_text:create()).

apply_insert_test()->
  Op = [
    {[{<<"p">>,5},{<<"i">>, <<" Happy">>}]}
  ],
  NewSnapshot = ot_text:apply(<<"Hello World!">>, Op),
  ?assertEqual(<<"Hello Happy World!">>, NewSnapshot).

apply_delete_test()->
  Op = [
    {[{<<"p">>,5},{<<"d">>, <<" Happy">>}]}
  ],
  NewSnapshot = ot_text:apply(<<"Hello Happy World!">>, Op),
  ?assertEqual(<<"Hello World!">>, NewSnapshot).
