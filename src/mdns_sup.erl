%% Copyright (c) 2012-2016 Peter Morgan <peter.james.morgan@gmail.com>
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(mdns_sup).
-behaviour(supervisor).

-export([init/1]).
-export([start_link/0]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Advertiser = mdns_erlang_tcp_advertiser,
    Procs = manage() ++ discover(Advertiser) ++ advertise(Advertiser) ++ mesh(),
    {ok, {#{intensity => 5, period => 5}, Procs}}.


manage() ->
    [worker(mdns_manage) || mdns_config:can(discover)].

discover(Advertiser) ->
    [spec(mdns_discover, Advertiser) || mdns_config:can(discover)].

advertise(Advertiser) ->
    [spec(mdns_advertise, Advertiser) || mdns_config:can(advertise)].

spec(Module, Advertiser) ->
    worker(id(Module, Advertiser), Module, transient, [Advertiser]).

id(Module, Advertiser) ->
    {Module, #{service => Advertiser:service()}}.

mesh() ->
    [worker(mdns_erlang_tcp_mesh) || mdns_config:can(mesh)].


worker(Module) ->
    worker(Module, transient).

worker(Module, Restart) ->
    worker(Module, Restart, []).

worker(Module, Restart, Parameters) ->
    worker(Module, Module, Restart, Parameters).

worker(Id, Module, Restart, Parameters) ->
    #{id => Id,
      start => {Module, start_link, Parameters},
      restart => Restart,
      shutdown => 5000}.
