% A simple text implementation
%
% Operations are lists of components.
% Each component either inserts or deletes at a specified position in the document.
%
% Components are either:
%  {[{<<"i">>,<<"str">>}, {<<"p">>,100}]}: Insert 'str' at position 100 in the document
%  {[{<<"d">>,<<"str">>}, {<<"p">>,100}]}: Delete 'str' at position 100 in the document
%
% Components in an operation are executed sequentially, so the position of components
% assumes previous components have already executed.
%
% Eg: This op:
%   [{[{<<"i">>,<<"abc">>}, {<<"p">>,0}]}]
% is equivalent to this op:
%   [
%     {[{<<"i">>,<<"a">>}, {<<"p">>,0}]},
%     {[{<<"i">>,<<"b">>}, {<<"p">>,1}]},
%     {[{<<"i">>,<<"c">>}, {<<"p">>,2}]}
%   ]
%

-module (ot_text).

-export([
  name/0,
  create/0,
  apply/2,
  invert/1
]).

-ifdef (TEST).
-compile([export_all]).
-endif.

name()->
  text.

create()->
  <<"">>.

invert_component(Component)->
  %% TODO
  Component.

invert(Operation)->
  invert(Operation, []).

invert([], InvertedComponents)->
  InvertedComponents;
invert([Component|OtherComponents], InvertedComponents)->
  invert(OtherComponents, InvertedComponents++[invert_component(Component)]).

apply(Snapshot, [])->
  Snapshot;
apply(Snapshot, [{Comp}|Rest])->
  case check_valid_component({Comp}) of
    true ->
      Position = proplists:get_value(<<"p">>, Comp),
      ?MODULE:apply(apply_component(Position, Snapshot, Comp), Rest);
    Error ->
      Error
  end.

apply_component(Position, Snapshot, [{<<"i">>, OpValue}|_Rest]) when is_binary(OpValue), is_binary(Snapshot)->
  FirstPart = binary:part(Snapshot, {0, Position}),
  SecondPart = binary:part(Snapshot, {Position, byte_size(Snapshot)-Position}),
  <<FirstPart/binary, OpValue/binary, SecondPart/binary>>;
apply_component(Position, Snapshot, [{<<"d">>, OpValue}|_Rest]) when is_binary(OpValue), is_binary(Snapshot)->
  %% Make sure the values match
  OpValue = binary:part(Snapshot, {Position, byte_size(OpValue)}),
  FirstPart = binary:part(Snapshot, {0, Position}),
  SecondPart = binary:part(Snapshot, {Position+byte_size(OpValue), byte_size(Snapshot)-Position-byte_size(OpValue)}),
  <<FirstPart/binary, SecondPart/binary>>;
apply_component(Position, Snapshot, [{<<"p">>, _}|Rest])->
  apply_component(Position, Snapshot, Rest);
apply_component(_Position, _Snapshot, [_Component|_Rest]) ->
  {error, invalid_component}.

check_valid_component(_)->
  %% TODO
  true.
