defmodule Ueberauth.Strategy.Tiktok do
  @moduledoc """
  Provides an Überauth strategy for authenticating with Tiktok

  ### Setup

  Create an application in Tiktok for you to use.

  Register a new application at: [tiktok developer page](https://developers.tiktok.com/)
  and get the `client_key` and `client_secret`.

  Include the provider in your configuration for Ueberauth;

      config :ueberauth, Ueberauth,
        providers: [
          tiktok: { Ueberauth.Strategy.Tiktok, [] }
        ]

  Then include the configuration for Tiktok:

      config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth,
        client_key: System.get_env("TIKTOK_CLIENT_KEY"),
        client_secret: System.get_env("TIKTOK_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the
  `Ueberauth.Auth` struct:

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you
  register your provider.

  To set the `redirect_uri`:

      config :ueberauth, Ueberauth,
        providers: [
          tiktok: { Ueberauth.Strategy.Tiktok, [redirect_uri: "https://redirect-uri-example.com/auth/tiktok/callback"] }
        ]


  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          tiktok: { Ueberauth.Strategy.Tiktok, [default_scope: "user.basic.info"] }
        ]

  Default is user.basic.info which "Grants read-only access to some user profile information."
  """

  use Ueberauth.Strategy,
    oauth2_module: Ueberauth.Strategy.Tiktok.OAuth,
    send_redirect_uri: true,
    default_scope: "user.info.basic"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the tiktok authentication page.

  To customize the scope that are requested by tiktok include
  them as part of your url:

      "/auth/tiktok?scope=user.basic.info&code_verifier=[]"
  """

  def handle_request!(conn) do
    opts =
      []
      |> with_state_param(conn)
      |> with_scopes(conn)
      |> with_redirect_uri(conn)
      |> with_code_verifier(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Tiktok.

  When there is a failure from Tiktok the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Tiktok is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts =
      [code: code]
      # |> with_state_param(conn)
      |> with_redirect_uri(conn)

    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [opts])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      conn
      |> store_token(token)
      |> fetch_user(token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Tiktok
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:tiktok_user, nil)
    |> put_private(:tiktok_token, nil)
  end

  defp store_token(conn, token) do
    put_private(conn, :tiktok_token, token)
  end

  defp fetch_user(conn, token) do
    resp =
      Ueberauth.Strategy.Tiktok.OAuth.get(
        token,
        "/user/info/?fields=open_id,union_id,avatar_url,display_name"
      )

    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: body}}
      when status_code in 200..399 ->
        put_private(conn, :tiktok_user, body["data"]["user"])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  @doc """
  Includes the credentials from the Tiktok response.
  """
  def credentials(conn) do
    token = conn.private.tiktok_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: String.split(token.other_params["scope"], ","),
      other: %{
        expires_in: token.other_params["expires_in"],
        open_id: token.other_params["open_id"],
        refresh_expires_in: token.other_params["refresh_expires_in"]
      }
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.
  """
  def info(conn) do
    user = conn.private.tiktok_user

    %Info{
      image: user["avatar_url"],
      name: user["display_name"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Tiktok
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.tiktok_token,
        user: conn.private.tiktok_user
      }
    }
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_scopes(opts, conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    opts |> Keyword.put(:scope, scopes)
  end

  defp with_code_verifier(opts, conn) do
    code_verifier = conn.params["code_verifier"] || code_verifier_generator()
    opts |> Keyword.put(:code_verifier, code_verifier)
  end

  defp with_redirect_uri(opts, conn) do
    if option(conn, :send_redirect_uri) do
      opts |> Keyword.put(:redirect_uri, callback_url(conn))
    else
      opts
    end
  end

  defp code_verifier_generator(min_length \\ 43, max_length \\ 128) do
    charset =
      Enum.to_list(?A..?Z) ++
        Enum.to_list(?a..?z) ++
        Enum.to_list(?0..?9) ++
        ["-", "_", ".", "~"]

    length = Enum.random(min_length..max_length)

    1..length
    |> Enum.map(fn _ -> Enum.random(charset) end)
    |> List.to_string()
  end
end
