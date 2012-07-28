-module (ot_text_test).

-compile([export_all]).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-include ("text.hrl").

name_test()->
  ?assertEqual(text, ot_text:name()).

create_test()->
  ?assertEqual("", ot_text:create()).

apply_insert_test()->
  Op = #ot_text_r{p=5,i=" Happy"},
  NewSnapshot = ot_text:apply("Hello World!", [Op]),
  ?assertEqual("Hello Happy World!", NewSnapshot).

apply_delete_test()->
  Op = #ot_text_r{p=5,d=" Happy"},
  NewSnapshot = ot_text:apply("Hello Happy World!", [Op]),
  ?assertEqual("Hello World!", NewSnapshot).

compose_insert_test()->
  Op1 = #ot_text_r{p=0,i="Test123"},
  Op2 = #ot_text_r{p=4,i="Hello"},
  NewOp = ot_text:compose([Op1], [Op2]),
  ?assertEqual([#ot_text_r{p=0,i="TestHello123"}], NewOp).

compose_delete_test()->
  Op1 = #ot_text_r{p=0,i="Test123"},
  Op2 = #ot_text_r{p=4,d="123"},
  NewOp = ot_text:compose([Op1], [Op2]),
  ?assertEqual([#ot_text_r{p=0,i="Test123"}|#ot_text_r{p=4,d="123"}], NewOp).

compress_test()->
  Op1 = #ot_text_r{p=0,i="Test123"},
  Op2 = #ot_text_r{p=4,i="Hello"},
  NewOp = ot_text:compress([Op1, Op2]),
  ?assertEqual([#ot_text_r{p=0,i="TestHello123"}], NewOp).

transform_cursor_left_test()->
  Op = #ot_text_r{p=0,i="Test123"},
  ?assertEqual(0, ot_text:transform_cursor(0, [Op], left)).

transform_cursor_right_test()->
  Op = #ot_text_r{p=0,i="Test123"},
  ?assertEqual(7, ot_text:transform_cursor(0, [Op], right)).

string_inject_test()->
  NewString = ot_text:string_inject("This is test!!", 7," a"),
  ?assertEqual(
    "This is a test!!",
    NewString
  ).

string_split_test()->
  Text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  NewString = ot_text:string_split(Text, 8,"IJKLMNOPQRST"),
  ?assertEqual(
    "ABCDEFGHUVWXYZ",
    NewString
  ).

