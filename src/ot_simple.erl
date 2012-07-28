-module (ot_simple).

-export ([
  name/0,
  create/0,
  apply/2,
  transform/3
]).

name()->
  simple.

create()->
  [{str, ""}].

apply(Snapshot, Op)->
  TextLen = length(proplists:get_value(str, Snapshot)),
  case proplists:get_value(position, Op) of
    Pos when (Pos > 0) and (Pos < TextLen) ->
      test;
    _ ->
      throw({invalid_position, <<"The position passed is an invalid number">>})
  end.

transform(Op1, Op2, Sym)->
  Pos = proplists:get_value(position, Op1),

  Text = proplists:get_value(text, Op2),

  NewPos = case proplists:get_value(position, Op2) of
    Op2Pos when Op2Pos < Pos ->
      Pos+length(Text);
    Op2Pos when (Op2Pos == Pos) and (Sym == left) ->
      Pos+length(Text);
    _ ->
      Pos
  end,

  [{position, NewPos}, {text, proplists:get_value(text, Op1)}].