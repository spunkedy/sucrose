defmodule Sucrose.Middleware.SimpleOrPolicy do
  alias Absinthe.Resolution
  alias Sucrose.Common

  @behaviour Absinthe.Middleware

  @error_message :no_proper_resolution_or_config

  def call(resolution = %{context: %{claims: claims}}, %{handler: handler}) do
    check = simple_resolution(resolution)

    response = claims_check(check, claims, handler)
    # IO.puts("\n\nBEGIN")
    # IO.inspect(response)
    # IO.inspect("For: #{inspect(Map.take(check, [:child, :parent]))}")
    # IO.inspect("For Claims: #{inspect(claims)}")
    # IO.puts("END\n\n")
    Common.handle_response(response, check)
    # rescue
    # _ ->
    # {:error, @error_message}
  end

  def call(_, _) do
    {:error, @error_message}
  end

  def claims_check(check, claims, handler, last \\ :error)
  def claims_check(_check, [], _handler, last), do: last

  def claims_check(check, [head | rest], handler, last) do
    new_check = Map.put(check, :claim, head)

    current_claim_check =
      case new_check do
        %{from: :mutation} -> handler.can_mutate?(new_check)
        _ -> handler.can_query?(new_check)
      end

    # IO.inspect("For: #{inspect(Map.take(new_check, [:child, :parent, :claim]))}")
    # IO.inspect(current_claim_check)

    case current_claim_check do
      # immediate exits
      :ok -> :ok
      true -> :ok
      {:censor, _} -> claims_check(check, rest, handler, current_claim_check)
      :error_out -> :error
      {:error_out, msg} -> {:error, msg}
      # Continue on for anything else
      _ -> claims_check(check, rest, handler, last)
    end
  end

  @spec simple_resolution(map()) :: %{
          child: :atom,
          parent: :atom,
          resolution: map()
        }
  def simple_resolution(resolution) do
    %{
      child: resolution.definition.schema_node.identifier,
      parent: resolution.parent_type.identifier,
      resolution: resolution
    }
  end
end
