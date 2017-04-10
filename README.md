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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `alexa_request_verifier` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:alexa_request_verifier, "~> 0.1.0"}]
end
```


You will also need to modify your Endpoint.ex file by changing the parser as follows:

    parsers: [AlexaRequestVerifier.JSONRawBodyParser, :urlencoded, :multipart, :json],

Finally, you will need to add AlexaRequestVerifier as an application.

    applications: [..., :alexa_request_verifier] 


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/alexa_request_verifier](https://hexdocs.pm/alexa_request_verifier).

