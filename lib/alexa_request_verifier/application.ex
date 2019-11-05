defmodule AlexaRequestVerifier.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: AlexaRequestVerifier.Worker.start_link(arg1, arg2, arg3)
      # worker(AlexaRequestVerifier.Worker, [arg1, arg2, arg3]),
      supervisor(ConCache, [[], [name: :cert_signature_cache]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlexaRequestVerifier.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
