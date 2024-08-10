defmodule Receiver.MixProject do
  use Mix.Project

  def project do
    [
      app: :receiver,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :wx, :runtime_tools],
      mod: {Receiver.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:tcp_postman, in_umbrella: true}
    ]
  end
end
