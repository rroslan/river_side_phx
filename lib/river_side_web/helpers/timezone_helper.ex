defmodule RiverSideWeb.Helpers.TimezoneHelper do
  @moduledoc """
  Helper functions for timezone conversion, specifically for Malaysian time (UTC+8).
  """

  @malaysia_offset_hours 8

  @doc """
  Converts a UTC datetime to Malaysian time (UTC+8).
  """
  def to_malaysian_time(nil), do: nil

  def to_malaysian_time(datetime) when is_struct(datetime, DateTime) do
    DateTime.add(datetime, @malaysia_offset_hours * 60 * 60, :second)
  end

  def to_malaysian_time(naive_datetime) when is_struct(naive_datetime, NaiveDateTime) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> to_malaysian_time()
  end

  @doc """
  Formats a datetime in Malaysian time with the given format string.
  """
  def format_malaysian_time(datetime, format_string \\ "%Y-%m-%d %I:%M %p") do
    datetime
    |> to_malaysian_time()
    |> Calendar.strftime(format_string)
  end

  @doc """
  Formats a datetime in Malaysian time, showing only the time portion.
  """
  def format_malaysian_time_only(datetime) do
    format_malaysian_time(datetime, "%I:%M %p")
  end

  @doc """
  Formats a datetime in Malaysian time, showing date and time.
  """
  def format_malaysian_datetime(datetime) do
    format_malaysian_time(datetime, "%d %b %Y, %I:%M %p")
  end

  @doc """
  Gets the current time in Malaysian timezone.
  """
  def malaysian_now do
    DateTime.utc_now()
    |> to_malaysian_time()
  end

  @doc """
  Gets today's date in Malaysian timezone.
  """
  def malaysian_today do
    malaysian_now()
    |> DateTime.to_date()
  end
end
