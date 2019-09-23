defmodule SimpleOrPolicyTest do
  use ExUnit.Case
  alias Sucrose.Middleware.SimpleOrPolicy

  defmodule SampleHandler do
    def can_query?(%{child: :author}), do: false
    def can_query?(_), do: true
    def can_mutate?(_), do: true
  end

  defmodule SimplePolicyTestSchema do
    use Absinthe.Schema

    object :post do
      field(:author, :string)
      field(:content, :string)
    end

    query do
      field :posts, non_null(list_of(non_null(:post))) do
        resolve(fn _, _, _ ->
          {:ok,
           [
             %{author: "author_one", content: "content_one"},
             %{author: "author_two", content: "content_two"}
           ]}
        end)
      end
    end

    def middleware(middleware, _field, %Absinthe.Type.Object{identifier: _ident}) do
      [
        {SimpleOrPolicy, %{handler: SampleHandler}}
      ] ++
        middleware ++
        []
    end
  end

  test "example query" do
    query = """
      query {
        posts {
          author,
          content,
        }
      }

    """

    {:ok, %{data: res}} = Absinthe.run(query, SimplePolicyTestSchema, context: %{claim: :author})

    post = res["posts"] |> hd
    assert is_nil(post["author"])
  end
end
