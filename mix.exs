defmodule AlexaRequestVerifier.Mixfile do
  use Mix.Project

  def project do
    [
      app: :alexa_request_verifier,
      version: "0.1.6",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [:logger, :con_cache, :inets],
      mod: {AlexaRequestVerifier.Application, []}
    ]
  end

  defp description do
    """
    Alexa Request Verifier is a library that handles all of the certificate and request verification for Alexa Requests for certified skills. (See the Alexa Skills Documentation for more information).
    """
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:plug, "~> 1.8"},
      {:certifi, "~> 2.5"},
      {:ssl_verify_fun, "~> 1.1"},
      {:con_cache, "~> 0.14"},
      {:ex_doc, "~> 0.19.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: :alexa_request_verifier,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Charlie Graham"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/grahac/alexa_request_verifier"}
    ]
  end
end
