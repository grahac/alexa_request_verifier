# AlexaRequestVerifier

## Description
Alexa Request Verifier is a library that handles all of the certificate and request verification for Alexa Requests for certified skills. (See the [Alexa Skills Documentation](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/developing-an-alexa-skill-as-a-web-service) for more information)  

Specifically, it will:
* Confirm the URL for the certificate is a valid Alexa URL
* Validate the certificate is valid
* Confirm the request is recent (to avoid playback attacks)
* Validate the message signature

Alexa Request Verifier uses ConCache to cache certificates once they have been verified.


## Installation

1. If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `alexa_request_verifier` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:alexa_request_verifier, "~> 0.1.3"}]
end
```
2.You will need to add AlexaRequestVerifier as an application in the same mix.exs file.
```elixir
applications: [..., :alexa_request_verifier] 
```

3. You will also need to modify your endpoint.ex file by changing the parser as follows:
```elixir
parsers: [AlexaRequestVerifier.JSONRawBodyParser, :urlencoded, :multipart, :json],
```

4. You will need to add the verifier plug to your pipeline in your router.ex file
```elixir
pipeline :alexa_api do
    plug :accepts, ["json"]
    plug AlexaRequestVerifier
end
```

## Kudos
A big thanks to the Elixir Forum for helping me navigate all of the semi-documented Erlang :public_key libraries.  [Forum thread](https://elixirforum.com/t/x-509-request-cert-chain-validation-plug-for-alexa-skills/4463/23).


The Hex documentation can be found at [https://hexdocs.pm/alexa_request_verifier](https://hexdocs.pm/alexa_request_verifier).

