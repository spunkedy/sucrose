defmodule Sucrose.Middleware.SimpleOrPolicy do
  alias Absinthe.Resolution
  require Logger

  @behaviour Absinthe.Middleware
  @moduledoc """
  This is a simple OR policy handler that takes a very simple approach to absinthe resolution handling
  The basis for all of the handlers is to have a common response type:

  ```
  true, false, :ok, :error, {:ok, _}, {:error, message}
  ```

  This will loop through until we have at least one claim that matches.

  Think of this one as an or logic.

  For posts a context with the claims of:

  ```
  [:author, :owner, :reader]
  ```

  For a mutation of deleting you might be ok with an `:author` or an `:owner`
  coming through and being able to delete a post.

  This Policy will stop the first chance it gets with a `true` condition.


  Another helper aspect of this will allow for a pattern of `:error_out` which means
  that if we ever reach this, we stop the or logic and hard escape out.

  However for this to work you MUST put this as your first because otherwise with the or
  logic it will exit the first `:ok` or `true` it gets.


  """

  @error_message :no_proper_resolution_or_config

  def call(resolution = %{context: %{claims: claims}}, %{handler: handler}) do
    check = simple_resolution(resolution)

    response = claims_check(check, claims, handler)
    # IO.puts("\n\nBEGIN")
    # IO.inspect(response)
    # IO.inspect("For: #{inspect(Map.take(check, [:child, :parent]))}")
    # IO.inspect("For Claims: #{inspect(claims)}")
    # IO.puts("END\n\n")

    case response do
      {:ok, _} -> resolution
      :ok -> resolution
      true -> resolution
      {:error, msg} -> handle_error(check, msg)
      _ -> handle_error(check)
    end
  rescue
    _ ->
      {:error, @error_message}
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
      :error_out -> :error
      {:error_out, msg} -> {:error, msg}
      # Continue on for anything else
      _ -> claims_check(check, rest, handler, last)
    end
  end

  @doc """
  This is the default error handler to put when we want to deny something.
  """
  def handle_error(check, message \\ "Unauthorized") do
    Logger.warn(fn ->
      "Erroring out for: #{inspect(Map.take(check, [:child, :parent, :claim]))}"
    end)

    Resolution.put_result(check.resolution, {:error, message})
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
