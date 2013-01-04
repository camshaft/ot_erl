-module (ot_json).

-export ([
  name/0,
  create/0,
  invert_component/1,
  invert/1,
  check_list/1,
  check_obj/1,
  apply/2
]).

-ifdef (TEST).
-compile(export_all).
-endif.

name()->
  json.

create()->
  null.

invert_component({Component})->
  Path = proplists:get_value(<<"p">>, Component, []),
  InvertedComponent = invert_component(Path, Component, []),
  {InvertedComponent}.

invert_component(Path, [], Inverted)->
  case proplists:is_defined(<<"p">>, Inverted) of
    true ->
      Inverted;
    false ->
      Inverted++[<<"p">>, Path]
  end;
invert_component(Path, [{<<"p">>, Path}|OtherProperties], Inverted)->
  %% Do Nothing
  invert_component(Path, OtherProperties, Inverted);
invert_component(Path, [{<<"si">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"sd">>, Value}]);
invert_component(Path, [{<<"sd">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"si">>, Value}]);
invert_component(Path, [{<<"oi">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"od">>, Value}]);
invert_component(Path, [{<<"od">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"oi">>, Value}]);
invert_component(Path, [{<<"li">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"ld">>, Value}]);
invert_component(Path, [{<<"ld">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"li">>, Value}]);
invert_component(Path, [{<<"na">>, Value}|OtherProperties], Inverted)->
  invert_component(Path, OtherProperties, Inverted++[{<<"na">>, -Value}]);
invert_component(Path, [{<<"lm">>, Value}|OtherProperties], Inverted)->
  Lm = lists:nth(length(Path), Path),
  invert_component(Path, OtherProperties, Inverted++[{<<"lm">>, Lm},{<<"p">>, Path++[Value]}]).

invert(Operation)->
  invert(Operation, []).

invert([], InvertedComponents)->
  InvertedComponents;
invert([Component|OtherComponents], InvertedComponents)->
  invert(OtherComponents, InvertedComponents++[invert_component(Component)]).

check_valid_op(_Op)->
  true.

check_list(Elem)->
  case is_list(Elem) of
    true ->
      true;
    false ->
      throw({error, {elem_not_a_list, Elem}})
  end.

check_obj(Elem)->
  case is_tuple(Elem) of
    true ->
      true;
    false ->
      throw({error, {elem_not_a_obj, Elem}})
  end.

apply(Snapshot, Operation)->
  try check_valid_op(Operation) of
    _ ->
      apply_components(Snapshot, Operation)
  catch
    Error ->
      Error
  end.

apply_components(Snapshot, [])->
  Snapshot;
apply_components(Snapshot, [{Component}|OtherComponents])->
  Path = proplists:get_value(<<"p">>, Component),
  case apply_component(find_elem(Path, Snapshot), Component) of
    {error, Error} ->
      throw({error, Error});
    NewElem ->
      NewSnapshot = put_elem(Path, NewElem, Snapshot),
      apply_components(NewSnapshot, OtherComponents)
  end.

apply_component(undefined, Component)->
  Path = proplists:get_value(<<"p">>, Component),
  {error, {invalid_path, Path}};
apply_component({Key, Elem}, [{<<"na">>, OpValue}|_Rest])->
  Value = get_value(Key, Elem),
  case is_number(Value) of
    true ->
      set_value(Key, Value+OpValue, Elem);
    false ->
      {error, badtype}
  end;
apply_component({Key, Elem}, [{<<"si">>, OpValue}|_Rest]) when is_binary(OpValue), is_binary(Elem)->
  FirstPart = binary:part(Elem, {0, Key}),
  SecondPart = binary:part(Elem, {Key, byte_size(Elem)-Key}),
  <<FirstPart/binary, OpValue/binary, SecondPart/binary>>;
apply_component({Key, Elem}, [{<<"sd">>, OpValue}|_Rest]) when is_binary(OpValue), is_binary(Elem)->
  %% Make sure the values match
  OpValue = binary:part(Elem, {Key, byte_size(OpValue)}),
  FirstPart = binary:part(Elem, {0, Key}),
  SecondPart = binary:part(Elem, {Key+byte_size(OpValue), byte_size(Elem)-Key-byte_size(OpValue)}),
  <<FirstPart/binary, SecondPart/binary>>;
apply_component({Key, Elem}, [{<<"li">>, OpValue}|Rest])->
  check_list(Elem),
  case proplists:get_value(<<"ld">>, Rest) of
    undefined ->
      {List1, List2} = lists:split(Key, Elem),
      List1++[OpValue]++List2;
    DeleteValue ->
      %% Make sure the values match
      DeleteValue = get_value(Key, Elem),
      set_value(Key, OpValue, Elem)
  end;
apply_component({Key, Elem}, [{<<"ld">>, OpValue}|Rest])->
  check_list(Elem),
  case proplists:get_value(<<"li">>, Rest) of
    undefined ->
      OpValue = get_value(Key, Elem),
      {List1, List2} = lists:split(Key, Elem),
      List1++tl(List2);
    DeleteValue ->
      %% Make sure the values match
      DeleteValue = get_value(Key, Elem),
      set_value(Key, OpValue, Elem)
  end;
% TODO
% apply_component({Key, Elem}, [{<<"lm">>, OpValue}|_Rest])->
%   undefined;
apply_component({Key, Elem}, [{<<"oi">>, OpValue}|_Rest])->
  check_obj(Elem),
  set_value(Key, OpValue, Elem);
apply_component({Key, {Elem}}, [{<<"od">>, OpValue}|_Rest])->
  check_obj({Elem}),
  OpValue = get_value(Key, {Elem}),
  {proplists:delete(Key, Elem)};
apply_component(Value, [{<<"p">>, _}|Rest])->
  apply_component(Value, Rest);
apply_component(_, [_Component|_Rest]) ->
  {error, invalid_component}.

%% Helpers
find_elem([Path|[]], Elem)->
  {Path, Elem};
find_elem(_, undefined)->
  undefined;
find_elem([Path|Rest], Elem) ->
  find_elem(Rest, get_value(Path, Elem));
find_elem([], _)->
  undefined.

put_elem([Key|[]], Elem, Snapshot)->
  set_value(Key, Elem, Snapshot);
put_elem([Key|Rest], Elem, Snapshot) when is_number(hd(Rest)), length(Rest) == 1->
  set_value(Key, Elem, Snapshot);
put_elem([Key|Rest], Elem, Snapshot)->
  set_value(Key, put_elem(Rest, Elem, get_value(Key, Snapshot)), Snapshot).

get_value(Key, Elem) when is_list(Elem), is_number(Key) ->
  lists:nth(Key+1, Elem);
get_value(Key, {Elem}) when is_list(Elem) ->
  proplists:get_value(Key, Elem);
get_value(_, _)->
  undefined.

set_value(Key, Value, Elem) when is_number(Key), is_list(Elem) ->
  {List1, List2} = lists:split(Key, Elem),
  List1++[Value]++tl(List2);
set_value(Key, Value, {Elem}) when is_list(Elem) ->
  List1 = proplists:delete(Key, Elem),
  {List1++[{Key, Value}]};
set_value(_, _, _)->
  throw({error, badarg}).
