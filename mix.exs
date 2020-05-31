defmodule IP.MixProject do
  use Mix.Project

  def project do
    [
      app: :net_address,
      version: "0.1.4",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env:
        [coveralls: :test,
         "coveralls.detail": :test,
         "coveralls.post": :test,
         "coveralls.html": :test],
      package: [
          description: "Net Address Modules",
          licenses: ["MIT"],
          files: ~w(lib mix.exs README* LICENSE* VERSIONS*),
          links: %{"GitHub" => "https://github.com/ityonemo/net_address"}
        ],
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps, do: [
    {:credo, "~> 1.3", only: [:dev, :test], runtime: false},
    {:excoveralls, "~> 0.11", only: :test, runtime: false},
    {:ex_doc, "~> 0.21.2", only: :dev, runtime: false},
    {:dialyxir, "~> 0.5.1", only: :dev, runtime: false}
  ]

end
