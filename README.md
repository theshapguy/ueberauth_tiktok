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
        {:ueberauth_tiktok, "~> 0.1.0"}
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

## Docs

Published at [HexDocs](https://hexdocs.pm/ueberauth_tiktok).

## Notes
1. The TikTok API does not allow redirect URIs with port numbers in the staging environment. For more information, see [this Stack Overflow answer](https://stackoverflow.com/a/73533804).
2. Use `TIKTOK_CLIENT_KEY` instead of `TIKTOK_CLIENT_ID` as TikTok's OAuth implementation provides a client key.