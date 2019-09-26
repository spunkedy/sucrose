defmodule Sucrose.Common do
  alias Absinthe.Resolution
  require Logger

  @moduledoc """
  This is the common module to be shared / used amongst the
  middleware policies.
  """

  @doc """
  This is the default error handler to put when we want to deny something.
  """
  def handle_error(check, message \\ "Unauthorized") do
    Logger.warn(fn ->
      "Erroring out for: #{inspect(Map.take(check, [:child, :parent, :claim]))}"
    end)

    Resolution.put_result(check.resolution, {:error, message})
  end

  def handle_censor(check, censor) do
    Resolution.put_result(check.resolution, {:ok, censor})
  end

  @doc """
  Handle the responses, return, warn, or error based upon the response.

  1. `true` - return the normal response
  1. `{:ok, _}` -> return the normal response
  1. `{:censor, val}` -> censor the value and put the response
  1. `false` - return null / log warn message
  1. `:error` - return nil / log warn message
  1. `{:error, msg}` - return null / log warn message and return the `msg` on the payload
  """

  def handle_response(response, check) do
    case response do
      {:ok, _} ->
        check.resolution

      :ok ->
        check.resolution

      {:censor, val} ->
        handle_censor(check, val)

      true ->
        check.resolution
        # {:error, msg} -> handle_error(check, msg)
        # _ -> handle_error(check)
    end
  end
end
