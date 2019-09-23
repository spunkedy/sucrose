defmodule Sucrose.MixProject do
  use Mix.Project

  def project do
    [
      app: :sucrose,
      package: %{
        description: """
        Absinthe Policies
        """,
        licenses: ["MIT"],
        links: %{
          "github" => "https://github.com/spunkedy/sucrose"
        }
      },
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.4.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}

      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
