-module (ot_json_test).

-compile([export_all]).

-include_lib("eunit/include/eunit.hrl").

name_test()->
  ?assertEqual(json, ot_json:name()).

create_test()->
  ?assertEqual(null, ot_json:create()).

component_helper()->
  [
    {<<"p">>, [<<"test">>, 0]},
    {<<"si">>,<<"StringInsert">>},
    {<<"sd">>,<<"StringDelete">>},
    {<<"oi">>,<<"ObjectInsert">>},
    {<<"od">>,<<"ObjectDelete">>},
    {<<"li">>,<<"ListInsert">>},
    {<<"ld">>,<<"ListDelete">>},
    {<<"na">>,5}
  ].

component_test_helper(Component, Inverted)->
  ?assertEqual(proplists:get_value(<<"si">>, Component), proplists:get_value(<<"sd">>, Inverted)),
  ?assertEqual(proplists:get_value(<<"sd">>, Component), proplists:get_value(<<"si">>, Inverted)),
  ?assertEqual(proplists:get_value(<<"oi">>, Component), proplists:get_value(<<"od">>, Inverted)),
  ?assertEqual(proplists:get_value(<<"od">>, Component), proplists:get_value(<<"oi">>, Inverted)),
  ?assertEqual(proplists:get_value(<<"li">>, Component), proplists:get_value(<<"ld">>, Inverted)),
  ?assertEqual(proplists:get_value(<<"ld">>, Component), proplists:get_value(<<"li">>, Inverted)),
  ?assertEqual(-proplists:get_value(<<"na">>, Component), proplists:get_value(<<"na">>, Inverted)).
  

invert_component_test()->
  Component = component_helper(),
  {Inverted} = ot_json:invert_component({Component}),
  component_test_helper(Component, Inverted).

invert_test()->
  [{Component1}, {Component2}] = Operation = [{component_helper()}, {component_helper()}],
  [{Inverted1}, {Inverted2}] = ot_json:invert(Operation),
  component_test_helper(Component1, Inverted1),
  component_test_helper(Component2, Inverted2).

find_elem_test()->
  Elem = [
    {<<"test">>,[
      {[
        {<<"hello">>, 5}
      ]},
      {[
        {<<"world">>, 42}
      ]}
    ]}
  ],
  % Parent = proplists:get_value(<<"test">>, Elem),
  Expected = {<<"world">>, {[{<<"world">>,42}]}},
  Result = ot_json:find_elem([<<"test">>,1,<<"world">>], {Elem}),
  ?assertEqual(Expected, Result).

apply_component_na_test()->
  Arg = {<<"world">>, {[{<<"world">>,42}]}},
  ?assertMatch({[{<<"world">>, 43}]},ot_json:apply_component(Arg, [{<<"na">>, 1}])).

apply_component_si_test()->
  Arg = {10, <<"this is a test">>},
  ?assertMatch(<<"this is a cool test">>,ot_json:apply_component(Arg, [{<<"si">>, <<"cool ">>}])).

apply_component_sd_test()->
  Arg = {10, <<"this is a cool test">>},
  ?assertMatch(<<"this is a test">>,ot_json:apply_component(Arg, [{<<"sd">>, <<"cool ">>}])).

apply_component_li_test()->
  Arg = {3, [<<"This">>, <<"is">>, <<"a">>, <<"test">>]},
  ?assertMatch([<<"This">>, <<"is">>, <<"a">>, <<"cool">>, <<"test">>],ot_json:apply_component(Arg, [{<<"li">>, <<"cool">>}])).

apply_component_ld_test()->
  Arg = {3, [<<"This">>, <<"is">>, <<"a">>, <<"cool">>, <<"test">>]},
  ?assertMatch([<<"This">>, <<"is">>, <<"a">>, <<"test">>],ot_json:apply_component(Arg, [{<<"ld">>, <<"cool">>}])).

apply_component_l_replace()->
  Arg = {3, [<<"This">>, <<"is">>, <<"a">>, <<"cool">>, <<"test">>]},
  Component = [{<<"ld">>, <<"cool">>}, {<<"li">>, <<"sweet">>}],
  ?assertMatch([<<"This">>, <<"is">>, <<"a">>, <<"sweet">>, <<"test">>], ot_json:apply_component(Arg, Component)).
apply_component_l_replace2()->
  Arg = {3, [<<"This">>, <<"is">>, <<"a">>, <<"cool">>, <<"test">>]},
  Component = [{<<"li">>, <<"sweet">>}, {<<"ld">>, <<"cool">>}],
  ?assertMatch([<<"This">>, <<"is">>, <<"a">>, <<"sweet">>, <<"test">>], ot_json:apply_component(Arg, Component)).

apply_component_oi_test()->
  Arg = {<<"test">>, {[{<<"world">>,42}]}},
  ?assertMatch({[{<<"world">>, 42},{<<"test">>,43}]},ot_json:apply_component(Arg, [{<<"oi">>, 43}])).

apply_component_od_test()->
  Arg = {<<"test">>, {[{<<"world">>, 42},{<<"test">>,43}]}},
  ?assertMatch({[{<<"world">>, 42}]},ot_json:apply_component(Arg, [{<<"od">>, 43}])).

apply_test_()->
  Snapshot = [
    {<<"test">>,[
      {[
        {<<"hello">>, <<"I'm cool">>}
      ]},
      {[
        {<<"world">>, 42}
      ]}
    ]}
  ],
  lists:map(fun({Expected, Operation}) ->
      Result = ot_json:apply({Snapshot}, Operation),
      ?_assertEqual(Expected, Result)
  end, [
    {
      {[
        {<<"test">>, [
          <<"string here">>,
          {[
            {<<"hello">>, <<"I'm cool">>}
          ]},
          {[
            {<<"world">>, 42}
          ]}
        ]}
      ]},
      [
        {[{<<"p">>, [<<"test">>,0]}, {<<"li">>, <<"string here">>}]}
      ]
    }
  ]).

put_elem_test()->
  Snapshot = [
    {<<"test">>, [
      {[
        {<<"hello">>, 5}
      ]},
      {[
        {<<"world">>, 42}
      ]}
    ]}
  ],
  ?assertMatch({[{<<"test">>, <<"hello">>}]}, ot_json:put_elem([<<"test">>], <<"hello">>, {Snapshot})),
  Replace = [<<"replaced">>, {[[<<"world">>, 42]]}],
  ?assertMatch({[
    {<<"test">>, Replace}
  ]}, ot_json:put_elem([<<"test">>, 0], Replace, {Snapshot})).
