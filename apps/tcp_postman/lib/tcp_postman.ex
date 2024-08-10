defmodule TcpPostman do
  @moduledoc """
  Manages connections and sends events to given TCP targets.
  Logs results to a log file.
  """
  @behaviour :gen_statem

  alias TcpPostman.{Request, Proto}

  # client API

  @doc """
  On a very first start we do not have any connection data yet (and no event to send as well).
  So, we just start a process in a disconnected state and wait for any `send_event` call to come.
  """
  @spec start_link(any()) :: {:ok, pid()} | {:error, any()}
  def start_link(_) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, Request.new(), [])
  end

  @doc """
  Establishes a connection to the target and attempts to send a converted event.
  """
  @spec send_event(pid(), map()) :: tuple()
  def send_event(pid, %{from: from, host: host, port: port} = event) do
    content = convert_event(event, :protobuf)
    :gen_statem.call(pid, {:send_event, {from, host, port, content}})
  end

  # callbacks

  @impl true
  def callback_mode(), do: [:state_functions]

  @impl true
  def init(request), do: {:ok, :idle, request}

  def idle({:call, from}, {:send_event, {event_from, host, port, content}}, request) do
    request = %{
      request
      | host: String.to_charlist(host),
        port: String.to_integer(port),
        content: content,
        from: from,
        event_from: event_from
    }

    action = [{:next_event, :internal, :connect}]
    {:next_state, :disconnected, request, action}
  end

  def disconnected(:internal, :connect, %Request{host: host, port: port} = request) do
    case establish_connection(host, port) do
      {:ok, socket} ->
        request = Request.set_socket(request, socket)
        {:next_state, :connected, request, [{:next_event, :internal, :send_request}]}

      {:error, _} ->
        action = [{{:timeout, :reconnect}, retry_interval(request.attempt), request.attempt}]
        request = %{request | attempt: request.attempt + 1}
        {:keep_state, request, action}
    end
  end

  def disconnected({:timeout, :reconnect}, 4, request) do
    log_and_exit(request, :error)
  end

  def disconnected({:timeout, :reconnect}, _, request) do
    actions = [{:next_event, :internal, :connect}]
    {:keep_state, request, actions}
  end

  def connected(:internal, :send_request, %Request{socket: socket, content: content} = request) do
    case :gen_tcp.send(socket, content) do
      :ok ->
        log_and_exit(request, :ok)

      {:error, _} ->
        :ok = close_connection(socket)
        action = [{:next_event, :internal, :connect}]
        {:next_state, :disconnected, request, action}
    end
  end

  def connected(:info, {:tcp_closed, _socket}, _) do
    {:next_state, :idle, Request.new()}
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # helpers

  @spec establish_connection(list(), non_neg_integer()) ::
          {:ok, :inet.socket()} | {:error, String.t()}
  defp establish_connection(host, port) do
    :gen_tcp.connect(host, port, [:binary, active: true], 3000)
  end

  @spec close_connection(:inet.socket()) :: :ok
  defp close_connection(socket), do: :gen_tcp.close(socket)

  @spec log_and_exit(Request.t(), :ok | :error) :: tuple()
  defp log_and_exit(request, atom) do
    result = compose_result(request, atom)
    log_result(result)

    :gen_statem.reply(request.from, {atom, result})

    {:next_state, :idle, Request.new()}
  end

  @spec convert_event(map(), atom()) :: TcpPostman.Proto.Event.t()
  defp convert_event(event, :protobuf) do
    event |> Proto.Event.new() |> Proto.Event.encode()
  end

  defp convert_event(event, _), do: event

  defp compose_result(%Request{event_from: from}, :ok) do
    time = DateTime.now!("Etc/UTC") |> Calendar.strftime("%d-%m-%Y %H:%M:%S")
    "#{time} :: #{from} :: Delievered"
  end

  defp compose_result(%Request{event_from: from}, :error) do
    time = DateTime.now!("Etc/UTC") |> Calendar.strftime("%d-%m-%Y %H:%M:%S")
    "#{time} :: #{from} :: Failed"
  end

  defp retry_interval(n), do: 500 * n

  defp log_result(result) do
    File.open(
      "./logs/#{Date.utc_today() |> Date.to_string()}_log.txt",
      [:append],
      &IO.binwrite(&1, result <> "\n")
    )
  end
end
