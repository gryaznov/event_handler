defmodule TcpPostman.Client do
  @moduledoc """
  Manages connections and sends events to given TCP targets.
  Logs results to a log file.
  """
  @behaviour :gen_statem

  alias TcpPostman.Request

  # client API

  @doc """
  Establishes a connection to the target and attempts to send a converted event.
  """
  @spec start_link(Request.t()) :: {:ok, pid()} | {:error, any()}
  def start_link(request) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, request, [])
  end

  # callbacks

  @impl true
  def callback_mode, do: [:state_functions]

  @impl true
  def init(request) do
    {:ok, :disconnected, request, [{:next_event, :internal, :connect}]}
  end

  @impl true
  def terminate(_, :disconnected, request), do: log(request, :error)
  def terminate(_, :connected, request), do: log(request, :ok)

  def disconnected(:internal, :connect, %Request{host: host, port: port} = request) do
    case :gen_tcp.connect(host, port, [:binary, active: true], 3000) do
      {:ok, socket} ->
        request = Request.set_socket(request, socket)
        {:next_state, :connected, request, [{:next_event, :internal, :send_request}]}

      {:error, _} ->
        action = [{{:timeout, :reconnect}, retry_interval(request.attempt), request.attempt}]
        request = %{request | attempt: request.attempt + 1}
        {:keep_state, request, action}
    end
  end

  def disconnected({:timeout, :reconnect}, 4, _) do
    {:stop, :shutdown}
  end

  def disconnected({:timeout, :reconnect}, _, request) do
    {:keep_state, request, [{:next_event, :internal, :connect}]}
  end

  def connected(:internal, :send_request, %Request{socket: socket, content: content} = request) do
    case :gen_tcp.send(socket, content) do
      :ok ->
        :ok = :gen_tcp.close(socket)
        {:stop, :shutdown}

      {:error, _} ->
        :ok = :gen_tcp.close(socket)
        action = [{:next_event, :internal, :connect}]
        {:next_state, :disconnected, request, action}
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient
    }
  end

  # helpers

  @spec log(Request.t(), :ok | :error) :: any()
  defp log(request, atom) do
    request
    |> compose_result(atom)
    |> log_result()
  end

  @spec compose_result(Request.t(), :ok | :error) :: String.t()
  defp compose_result(%Request{event_from: from}, result) do
    time = DateTime.now!("Etc/UTC") |> Calendar.strftime("%d-%m-%Y %H:%M:%S")
    "#{time} :: #{from} :: #{if result == :ok, do: "Delivered", else: "Failed"}"
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
