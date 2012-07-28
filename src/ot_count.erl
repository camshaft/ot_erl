-module (ot_count).

-export ([
  name/0,
  create/0,
  apply/2,
  transform/2,
  compose/2
]).

-spec name() -> atom().
name()->
  count.

-spec create() -> integer().
create()->
  1.

-spec apply(integer(), {integer(), integer()}) -> integer().
apply(Snapshot, {Value, Increment})->
  case Snapshot == Value of
    true ->
      Snapshot+Increment;
    false ->
      error
  end.

transform({Val1, Inc1}, {Val2, Inc2})->
  case Val1 == Val2 of
    true ->
      {Val1+Inc2, Inc1};
    false ->
      error
  end.

compose({Val1, Inc1}, {Val2, Inc2})->
  case Val1+Inc1 == Val2 of
    true ->
      {Val1+Inc1, Inc2};
    false ->
      error
  end.

-ifdef (TEST).

-compile([export_all]).

generate_random_op(Doc)->
  {{Doc, 1}, Doc+1}.


-endif.
