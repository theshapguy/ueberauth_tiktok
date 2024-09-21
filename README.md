# Überauth Tiktok

<!-- [![Build Status](https://travis-ci.org/ueberauth/ueberauth_github.svg?branch=master)](https://travis-ci.org/ueberauth/ueberauth_github)
[![Module Version](https://img.shields.io/hexpm/v/ueberauth_github.svg)](https://hex.pm/packages/ueberauth_github)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ueberauth_github/)
[![Total Download](https://img.shields.io/hexpm/dt/ueberauth_github.svg)](https://hex.pm/packages/ueberauth_github)
-->

[![Last Updated](https://img.shields.io/github/last-commit/theshapguy/ueberauth_tiktok.svg)](https://github.com/ueberauth/ueberauth_github/commits/master)

> Tiktok OAuth2 strategy for Überauth.

## Installation

1.  Setup your application with [Tiktok Developer Account](https://developers.tiktok.com/).

2.  Add `:ueberauth_tiktok` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:ueberauth_tiktok,  git: "https://github.com/theshapguy/ueberauth_tiktok"}
      ]
    end
    ```

3.  Add Tiktok to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        tiktok: {Ueberauth.Strategy.Tiktok, []}
      ]
    ```

4.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth,
      client_key: System.get_env("TIKTOK_CLIENT_KEY"),
      client_secret: System.get_env("TIKTOK_CLIENT_SECRET")
    ```

    Or, to read the client credentials at runtime:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth,
      client_key: {:system, "TIKTOK_CLIENT_KEY"},
      client_secret: {:system, "TIKTOK_CLIENT_SECRET"}
    ```

5.  Include the Überauth plug in your router:

    ```elixir
    defmodule MyApp.Router do
      use MyApp.Web, :router

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

6.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

7.  Your controller needs to implement callbacks to deal with `Ueberauth.Auth`
    and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/tiktok

Or with options:

    /auth/tiktok?scope=user.basic.info&code_verifier=

By default the requested scope is `"user.basic.info"`. This provides read access to the Tiktok user profile details. Tiktok API excludes user's email address
which results in a `nil` for `email` inside returned `%Ueberauth.Auth.Info{}`.

See more at [Tiktok's OAuth Documentation](https://developers.tiktok.com/doc/login-kit-manage-user-access-tokens/).

Scope can be configured either explicitly as a `scope` query value on the
request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Tiktok, [default_scope: "user.basic.info,user.basic.profile"]}
  ]
```


## Copyright and License

Copyright (c) 2024 Shapath Neupane

This library is released under the MIT License. See the [LICENSE.md](./LICENSE.md) file


## Installation via Hex
> Currently not published to Hex, once I find time to write the tests it will be published to Hex

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ueberauth_tiktok` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth_tiktok, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ueberauth_tiktok>.

