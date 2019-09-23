defmodule SimpleOrPolicyTest do
  use ExUnit.Case
  alias Sucrose.Middleware.SimpleOrPolicy

  defmodule SampleHandler do
    def can_query?(%{child: :content}), do: :error_out
    def can_query?(%{claim: :reader}), do: true
    def can_query?(_), do: false
    def can_mutate?(_), do: true
  end

  defmodule SimpleOrPolicyTestSchema do
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

    claims = [:non_real_auto_false, :reader]

    {:ok, %{data: res}} =
      Absinthe.run(query, SimpleOrPolicyTestSchema, context: %{claims: claims})

    # At this point we shouldn't have any content but all of the authors
    post = res["posts"] |> hd
    refute is_nil(post["author"])
  end
end
