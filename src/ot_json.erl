-module (ot_json).

% -export ([
%   name/0,
%   create/0,
%   invert/1
% ]).

% name()->
%   json.

% create()->
%   null.

% invert([Op|Rest])->
%   lists:append([invert_component(Op)], invert(Rest));
% invert([])->
%   [].

% invert_component(Component)->
%   NewComponent = [{p, proplist:get_value(p, Component)}],
%   InverseProps = [{si, sd}, {sd, si}, {oi, od}, {od, oi}, {li, ld}, {ld, li}, na, lm],
%   invert_component_props(Component, NewComponent, InverseProps).
% invert_component_props(Component, NewComponent, [])->
%   NewComponent;
% invert_component_props(Component, NewComponent, [{Prop, InverseProp}|Rest])->
%   ModdedComponent = case proplist:is_defined(Prop, Component) of
%     true ->
%       lists:append([{InverseProp, proplist:get_value(Prop, Component)}],NewComponent);
%     _ ->
%       NewComponent
%   end,
%   invert_component_props(Component, ModdedComponent, Rest);
% invert_component_props(Component, NewComponent, [na|Rest])->
%   ModdedComponent = case proplist:is_defined(na, Component) of
%     true ->
%       lists:append([{na, -proplist:get_value(na, Component)}],NewComponent);
%     _ ->
%       NewComponent
%   end,
%   invert_component_props(Component, ModdedComponent, Rest);
% invert_component_props(Component, NewComponent, [lm|Rest])->
%   ModdedComponent = case proplist:is_defined(lm, Component) of
%     true ->
%       %% TODO not sure what he's doing here
%       Path = proplist:get_value(p, Component),
%       Lm = lists:last(Path),
%       P = lists:seq(0, length(Path)-1),
%       lists:append([{lm, Path}],NewComponent);
%     _ ->
%       NewComponent
%   end,
%   invert_component_props(Component, ModdedComponent, Rest).

% check_valid_op(Op)->
%   true.

% apply(Snapshot, Op)->
%   case check_valid_op(Op) of
%     true->

%   end
