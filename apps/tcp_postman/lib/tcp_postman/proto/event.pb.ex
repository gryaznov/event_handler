defmodule TcpPostman.Proto.EventPayload do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:payload_type, 1, type: :string, json_name: "payloadType")
  field(:text, 2, type: :string)
end

defmodule TcpPostman.Proto.Event do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:from, 1, type: :string)
  field(:payload, 2, type: TcpPostman.Proto.EventPayload)
end
