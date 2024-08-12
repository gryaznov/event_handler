defmodule TcpPostman do
  @moduledoc """
  Accepts an event and sends it to the target.
  """
  use GenServer

  alias TcpPostman.{Client, Request}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: TcpPostman)
  end

  def process_event(pid, event) do
    GenServer.cast(pid, {:process_event, event})
  end

  @impl true
  def init(_), do: {:ok, nil}

  @impl true
  def handle_cast({:process_event, event}, state) do
    event
    |> Request.new()
    |> start_client()

    {:noreply, state}
  end

  defp start_client(request) do
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {TcpPostman.DynamicSupervisors, self()}},
      {Client, request}
    )
  end
end
