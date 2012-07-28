% A simple text implementation
%
% Operations are lists of components.
% Each component either inserts or deletes at a specified position in the document.
%
% Components are either:
%  [{i,"str"}, {p,100}]: Insert 'str' at position 100 in the document
%  [{d,"str"}, {p.100}]: Delete 'str' at position 100 in the document
%
% Components in an operation are executed sequentially, so the position of components
% assumes previous components have already executed.
%
% Eg: This op:
%   [[{i,"abc"}, {p,0}]]
% is equivalent to this op:
%   [[{i,"a"}, {p,0}], [{i,"b"}, {p,1}], [{i,"c"}, {p,2}]]
%

-module (ot_text).

-export([
  name/0,
  create/0,
  apply/2,
  compose/2,
  compress/1,
  normalize/1,
  transform_cursor/3,
  transform_component/4,
  invert/1
]).

-ifdef (TEST).
-compile([export_all]).
-endif.

-include ("text.hrl").

name()->
  text.

create()->
  "".

apply(Snapshot, [])->
  Snapshot;
apply(Snapshot, [Comp|Rest])->
  check_valid_component(Comp),

  I = Comp#ot_text_r.i,
  D = Comp#ot_text_r.d,
  P = Comp#ot_text_r.p,

  case I of
    undefined ->
      NewSnapshot = string_split(Snapshot, P, D),
      ?MODULE:apply(NewSnapshot, Rest);
    I ->
      NewSnapshot = string_inject(Snapshot, P, I),
      ?MODULE:apply(NewSnapshot, Rest)
  end;
apply(_,Ops)->
  Ops.

compose(Op1, Op2)->
  check_valid_op(Op1),
  check_valid_op(Op2),
  compose_comp(Op1, Op2).

% Attempt to compress the op components together 'as much as possible'.
% This implementation preserves order and preserves create/delete pairs.
compress(Op)->
  compose([], Op).

% Normalize should allow ops which are a single (unwrapped) component:
% [{i,"asdf"}, {p,23}]
% and turn it into:
% [[{i,"asdf"}, {p,23}]]
normalize(Op=#ot_text_r{})->
  compose_comp([], [Op]);
normalize(Op)->
  compose_comp([], Op).

transform_cursor(Pos, [], _)->
  Pos;
transform_cursor(Pos, [Comp|Rest], Side)->
  NewPos = transform_position(Pos, Comp, Side==right),
  transform_cursor(NewPos, Rest, Side).

% Simple insert
transform_component(Dest, Comp=#ot_text_r{i=I,p=P}, OtherComp, Side) when (I/=undefined)->
  check_valid_op(Comp),
  check_valid_op(OtherComp),
  Pos = transform_position(P, OtherComp, Side==right),
  append(Dest, #ot_text_r{i=I, p=Pos});
% Delete vs Insert
transform_component(Dest, _Comp=#ot_text_r{d=D,p=P}, _OtherComp=#ot_text_r{i=I2,p=P2}, _Side) when (I2/=undefined)->
  {S, NewDest} = case P<P2 of
    true ->
      Offset = P2-P+1,
      NewD = string:sub_string(D, 1, Offset),
      NewOp = #ot_text_r{d=NewD,p=P},
      ModDest = append(Dest, NewOp),
      {string:sub_string(D,Offset), ModDest};
    false ->
      {D, Dest}
  end,
  case S/="" of
    true ->
      SOp = #ot_text_r{d=S, p=P+length(I2)},
      append(NewDest, SOp);
    false ->
      NewDest
  end;
% Delete vs Delete
transform_component(Dest, _Comp=#ot_text_r{p=P,d=D}, _OtherComp=#ot_text_r{p=P2,d=D2}, _Side) when (P >= P2+length(D2)) ->
  append(Dest, #ot_text_r{d=D,p=P-length(D2)});
transform_component(Dest, Comp=#ot_text_r{p=P,d=D}, _OtherComp=#ot_text_r{p=P2}, _Side) when (P + length(D) =< P2) ->
  append(Dest, Comp);
% They overlap somewhere
transform_component(Dest, _Comp=#ot_text_r{p=P,d=D}, OtherComp=#ot_text_r{p=P2,d=D2}, _Side) ->
  NewD = case D of
    _ when (P<P2) ->
      string:sub_string(D, 1, P2-P+1);
    _ when (P+length(D) > P2+length(D2)) ->
      string:sub_string(D, P2+length(D2)-P+1);
    _ ->
      ""
  end,

  % This is entirely optional - just for a check that the deleted
  % text in the two ops matches
  NewComp = #ot_text_r{d=NewD,p=P},
  IntersectStart = max(P, P2),
  IntersectEnd = min(P+length(D), P2+length(D2)),
  CompIntersect = string:sub_string(D, IntersectStart-P, IntersectEnd-P),
  OtherIntersect = string:sub_string(D2, IntersectStart-P2, IntersectEnd-P2),
  CompIntersect = OtherIntersect,

  case NewD/="" of
    true  ->
      NewPos = transform_position(P, OtherComp, false),
      append(Dest, NewComp#ot_text_r{p=NewPos});
    _ ->
      Dest
  end.

invert(Op)->
  invert_components(Op, []).


%% Private
string_inject(S1, Pos, S2)->
  string:join([string:sub_string(S1, 1, Pos),S2,string:sub_string(S1,Pos+1)], "").

string_split(S1, Pos, S2)->
  Length = length(S2),
  Deleted = string:sub_string(S1, Pos+1, Pos+Length),
  S2 = Deleted,
  string:join([string:sub_string(S1, 1, Pos), string:substr(S1, Pos+Length+1)],"").

check_valid_component(_Comp=#ot_text_r{p=P,i=I,d=D}) when (is_integer(P) 
                                                    and (P >= 0)
                                                    and ((I/=undefined)
                                                      or (D/=undefined)))->
  ok;
check_valid_component(_Comp)->
  throw({error, <<"Invalid Op">>}).

check_valid_op([])->
  ok;
check_valid_op([Comp|Rest])->
  check_valid_component(Comp),
  check_valid_op(Rest).

append(Op, _Comp=#ot_text_r{i=I,d=D}) when ((I=="") or (D=="")) ->
  Op;
append([], Comp)->
  [Comp];
append(Op, Comp=#ot_text_r{i=I, p=P, d=D})->
  Last = lists:last(Op),
  % Compose the insert into the previous insert if possible
  LastP = Last#ot_text_r.p,
  LastI = Last#ot_text_r.i,
  LastD = Last#ot_text_r.d,

  case Last of
    _ when (LastI/=undefined)
      and  (I/=undefined)
      and  (LastP =< P)
      and  (P =< LastP+length(LastI)) ->
      NewI = string_inject(LastI, P-LastP, I),
      {NewOp,_}=lists:split(length(Op)-1, Op),
      NewOp++[#ot_text_r{i=NewI,p=LastP}];
    _ when (LastD/=undefined)
      and  (D/=undefined)
      and  (P =< LastP)
      and  (LastP =< P+length(D))->
      NewD = string_inject(D, LastP-P, LastD),
      {NewOp,_}=lists:split(length(Op)-1, Op),
      NewOp++[#ot_text_r{d=NewD,p=P}];
    _ ->
      Op++Comp
  end.

compose_comp(Op1, [])->
  Op1;
compose_comp(Op1, [Comp|Rest])->
  NewOp = append(Op1, Comp),
  compose_comp(NewOp, Rest).


transform_position(Pos, _Comp=#ot_text_r{i=I, p=P}, InsertAfter) when (I/=undefined) ->
  case (P<Pos) or ((P == Pos) and InsertAfter) of
    true ->
      Pos+length(I);
    _ ->
      Pos
  end;
transform_position(Pos, _Comp=#ot_text_r{d=D, p=P}, _InsertAfter)->
  case Pos of
    Pos when (Pos=<P) ->
      Pos;
    Pos when (Pos=<P+length(D)) ->
      P;
    Pos ->
      Pos - length(D)
  end.

invert_components([], Comps)->
  Comps;
invert_components([Comp|Rest], Comps)->
  NewComp = invert_component(Comp),
  invert_components(Rest, lists:append(Comps, [NewComp])).

invert_component(_Comp=#ot_text_r{i=I,p=P}) when (I/=undefined) ->
  #ot_text_r{d=I,p=P};
invert_component(_Comp=#ot_text_r{p=P,d=D}) ->
  #ot_text_r{i=D,p=P}.
