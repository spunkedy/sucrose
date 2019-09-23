defmodule Sucrose do
  @moduledoc """
  Welcome to Sucrose, a policy framework for Absinthe.


  Here is a quick overview:

  1. Create a Policy Handler
  1. Put claim(s) into the context
  1. Modify your schema to include the middleware referencing your Handler


  ## Create a Policy Handler

  There are samples in the tests as well.

  ```
  defmodule SampleHandler do
    def can_query?(%{claim: :reader}), do: true
    def can_query?(_), do: false
    def can_mutate?(%{claim: :author}), do: true
    def can_mutate?(_), do: false
  end
  ```

  This example will allow context claims with `:reader` to be able to query and
  a claim of `:author` to be able to mutate.

  So if you use the `Sucrose.Middleware.SimplePolicy`, you would not be able to query
  as an author.

  If you use the `Sucrose.Middleware.SimpleOrPolicy` you would be able to have both
  claims of `[:author, :reader]` then be able to read and write.

  You could also do multiple pattern matches if you want to stay simple like:

  ```
  def can_mutate?(%{claim: :author}), do: true
  def can_mutate?(_), do: false
  ```

  ## Put claim(s) into the context

  This is out context of this documentation however you can look it up [here](https://github.com/absinthe-graphql/absinthe/blob/master/guides/context-and-authentication.md)

  ```
  def call(conn, _) do
    context = build_context(conn)
    |> Map.put(:claims, [:author, :reader])
    Absinthe.Plug.put_options(conn, context: context)
  end
  ```

  ## Modify your schema

  ```
  alias Sucrose.Middleware.SimplePolicy
  def middleware(middleware, _field, %Absinthe.Type.Object{identifier: _ident}) do
    [
      {SimplerPolicy, %{handler: SampleHandler}}
    ] ++
    middleware ++
    []
  end
  ```

  This will match on every type, if you want to only do for the top level, you can
  pattern match on the indentifier to be `:mutation` or `:query` for the top level
  entry points.



  """
end
