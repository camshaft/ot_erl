-module (ot_count_test).

-compile([export_all]).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

name_test()->
  ?assertEqual(count, ot_count:name()).

transform_test()->
  proper:quickcheck(?MODULE:prop_transform_values_are_correct(), 10000).

prop_transform_values_are_correct()->
  ?FORALL({Val, Inc1, Inc2},
          {pos_integer(),pos_integer(),pos_integer()},
          begin
            AddedVal = Val+Inc2,
            equals({AddedVal, Inc1}, ot_count:transform({Val,Inc1},{Val,Inc2}))
          end
  ).