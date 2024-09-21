defmodule UeberauthTiktok.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_tiktok,
      version: "0.1.0",
      elixir: "~> 1.17",
      package: package(),
      description: description(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/theshapguy/ueberauth_tiktok"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ueberauth, "~> 0.10"},
      {:jason, "~> 1.0"},
      {:oauth2, "~> 2.0"},
      {:earmark, "~>1.4.47", only: :dev},
      {:ex_doc, "~>0.34.2", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"], main: "readme"]
  end

  defp description do
    "An Ueberauth strategy for using Tiktok to authenticate your users."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Shapath Neupane"],
      licenses: ["MIT"],
      links: %{Github: "https://github.com/theshapguy/ueberauth_tiktok"}
    ]
  end
end
