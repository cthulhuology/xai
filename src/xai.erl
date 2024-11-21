%%
%% MIT No Attribution  
%% Copyright 2023 David J Goehrig <dave@dloh.org>
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy 
%% of this software and associated documentation files (the "Software"), to 
%% deal in the Software without restriction, including without limitation the 
%% rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
%% sell copies of the Software, and to permit persons to whom the Software is 
%% furnished to do so.  
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
%% IN THE SOFTWARE.


-module(xai).
-author({ "David J Goehrig", "dave@dloh.org"}).
-copyright(<<"© 2024 David J. Goehrig"/utf8>>).
-export([ authorization/0, start/0,
	models/0, model/1,
	chat/1, chat/2, then/1, message/1 ]).

-define(ENDPOINT, "https://api.x.ai/v1").

authorization() ->
	Auth = list_to_binary(os:getenv("XAI_KEY")),
	<<"Bearer ", Auth/binary>>.

model() ->
	case os:getenv("XAI_MODEL") of
		false -> <<"grok-beta">>;
		M -> list_to_binary(M)
	end.

message(JSON) ->
	[Choices] = proplists:get_value(<<"choices">>,json:decode(JSON)),
	Message = proplists:get_value(<<"message">>,Choices),
	proplists:get_value(<<"content">>,Message).

start() ->
	Self = self(),
	HTTP = http:start(),
	http:then(fun(JSON) -> Self ! JSON end),
	HTTP.

then(Fun) ->
	http:then(Fun).
	
models() ->
	http:get(?ENDPOINT ++ "/models", [ { <<"Authorization">>, authorization() } ]).


model(Id) ->
	http:get(?ENDPOINT ++ "/models/" ++ Id, [ { <<"Authorization">>, authorization() } ]).

chat(Prompt,System) when is_list(Prompt) ->
	chat(list_to_binary(Prompt),System);
chat(Prompt,System) when is_list(System) ->
	chat(Prompt,list_to_binary(System));
chat(Prompt,System) ->
	completion([ 
		[{<<"role">>, <<"user">>}, {<<"content">>, Prompt }],
		[{<<"role">>, <<"system">>}, {<<"content">>, System }]
	]).

chat(Prompt) when is_list(Prompt) ->
	chat(list_to_binary(Prompt));
chat(Prompt) ->
	completion([[{<<"role">>, <<"user">>}, {<<"content">>, Prompt }]]).

completion(Messages) ->
	Payload = json:encode([
		{ <<"model">>, model()}, 
		{ <<"stream">>, false },
		{ <<"messages">>, Messages }]),
	http:post(?ENDPOINT ++ "/chat/completions", [
		{ <<"content-type">>, <<"application/json">> },
		{ <<"content-length">>, integer_to_binary(byte_size(Payload)) }, 
		{ <<"Authorization">>, authorization() } ], Payload).

