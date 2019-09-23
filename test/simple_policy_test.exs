defmodule SimplePolicyTest do
  use ExUnit.Case
  alias Sucrose.Middleware.SimplePolicy

  @known_good %{
    definition: %{
      schema_node: %{
        identifier: :add_post
      }
    },
    parent_type: %{
      identifier: :mutation
    },
    context: %{
      claim: :author
    }
  }

  defmodule SampleHandler do
    def can_query?(%{child: :author}), do: false
    def can_query?(_), do: true
    def can_mutate?(_), do: true
  end

  test "property testing" do
    assert SimplePolicy.call(@known_good, %{handler: SampleHandler, another: :prop})
    {:error, _} = SimplePolicy.call(%{}, %{handler: SampleHandler})
    assert SimplePolicy.call(@known_good, %{another: :prop})
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
        {SimplePolicy, %{handler: SampleHandler}}
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
