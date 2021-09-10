%{
    title: "How to Download for any Platform",
    date: "2020-09-05",
    published: true,
    position: 0
}
---

A behaviour module for implementing supervisors.

A supervisor is a process which supervises other processes, which we refer to as child processes. Supervisors are used to build a hierarchical process structure called a supervision tree. Supervision trees provide fault-tolerance and encapsulate how our applications start and shutdown.

A supervisor may be started directly with a list of children via start_link/2 or you may define a module-based supervisor that implements the required callbacks. The sections below use start_link/2 to start supervisors in most examples, but it also includes a specific section on module-based ones.

## Examples
In order to start a supervisor, we need to first define a child process that will be supervised. As an example, we will define a GenServer that represents a stack:

```elixir
defmodule Stack do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end
end
```