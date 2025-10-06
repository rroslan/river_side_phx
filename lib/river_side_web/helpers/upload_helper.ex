defmodule RiverSideWeb.Helpers.UploadHelper do
  @moduledoc """
  Security helper module for file uploads.
  Provides functions to safely handle file uploads and prevent directory traversal attacks.
  """

  @doc """
  Returns the default upload directory within the release.
  """
  def default_upload_dir do
    :river_side
    |> Application.app_dir("priv/static/uploads")
    |> to_string()
  end

  @doc """
  Returns the configured uploads directory or falls back to the default.
  """
  def uploads_dir do
    Application.get_env(:river_side, :uploads_dir, default_upload_dir())
  end

  @doc """
  Builds the public path clients can use to access an uploaded file.
  """
  def public_upload_path(filename, subdirectory \\ nil) do
    segments =
      case subdirectory do
        nil -> ["uploads"]
        subdir -> ["uploads", sanitize_subdirectory(subdir)]
      end

    full_segments = segments ++ [sanitize_filename(filename)]
    "/" <> Path.join(full_segments)
  end

  @doc """
  Sanitizes a filename to prevent directory traversal and other security issues.

  ## Examples

      iex> UploadHelper.sanitize_filename("../../../etc/passwd")
      "etc_passwd"

      iex> UploadHelper.sanitize_filename("my-image.jpg")
      "my-image.jpg"

      iex> UploadHelper.sanitize_filename("dangerous<script>.png")
      "dangerous_script_.png"
  """
  def sanitize_filename(filename) when is_binary(filename) do
    filename
    |> Path.basename()
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    # Limit filename length
    |> String.slice(0, 255)
  end

  @doc """
  Generates a unique filename with timestamp to prevent collisions.

  ## Examples

      iex> UploadHelper.generate_unique_filename("image.jpg")
      "1234567890_image.jpg"
  """
  def generate_unique_filename(original_filename) do
    timestamp = System.unique_integer([:positive])
    sanitized = sanitize_filename(original_filename)
    "#{timestamp}_#{sanitized}"
  end

  @doc """
  Validates file extension against allowed list.

  ## Examples

      iex> UploadHelper.valid_extension?("image.jpg", ~w(.jpg .jpeg .png .gif))
      true

      iex> UploadHelper.valid_extension?("script.exe", ~w(.jpg .jpeg .png .gif))
      false
  """
  def valid_extension?(filename, allowed_extensions) do
    ext = filename |> Path.extname() |> String.downcase()
    ext in allowed_extensions
  end

  @doc """
  Validates file size is within limits.

  ## Examples

      iex> UploadHelper.valid_size?(1_048_576, 5_242_880)  # 1MB file, 5MB limit
      true

      iex> UploadHelper.valid_size?(10_485_760, 5_242_880)  # 10MB file, 5MB limit
      false
  """
  def valid_size?(file_size, max_size) do
    file_size <= max_size
  end

  @doc """
  Safely constructs an upload path within the configured upload directory.
  Prevents directory traversal by ensuring the path stays within bounds.
  """
  def safe_upload_path(filename, subdirectory \\ nil) do
    base_path = uploads_dir()

    safe_path =
      if subdirectory do
        Path.join([base_path, sanitize_subdirectory(subdirectory), sanitize_filename(filename)])
      else
        Path.join(base_path, sanitize_filename(filename))
      end

    # Ensure the resolved path is still within the uploads directory
    expanded_path = Path.expand(safe_path)
    expanded_base = Path.expand(base_path)

    if String.starts_with?(expanded_path, expanded_base) do
      {:ok, safe_path}
    else
      {:error, :invalid_path}
    end
  end

  @doc """
  Ensures upload directory exists with proper permissions.
  """
  def ensure_upload_directory!(subdirectory \\ nil) do
    base_path = uploads_dir()

    dir_path =
      if subdirectory do
        Path.join(base_path, sanitize_subdirectory(subdirectory))
      else
        base_path
      end

    File.mkdir_p!(dir_path)
    dir_path
  end

  @doc """
  Validates and processes an upload, returning both disk and public paths or an error.
  """
  def process_upload(upload_path, destination_filename, opts \\ []) do
    allowed_extensions = Keyword.get(opts, :allowed_extensions, ~w(.jpg .jpeg .png .gif .webp))
    # 5MB default
    max_size = Keyword.get(opts, :max_size, 5_242_880)
    subdirectory = Keyword.get(opts, :subdirectory)

    with :ok <- validate_upload(upload_path, destination_filename, allowed_extensions, max_size),
         {:ok, safe_path} <- safe_upload_path(destination_filename, subdirectory),
         :ok <- ensure_upload_directory!(subdirectory) |> then(fn _ -> :ok end),
         :ok <- File.cp(upload_path, safe_path) do
      filename = Path.basename(safe_path)

      {:ok,
       %{
         disk_path: safe_path,
         public_path: public_upload_path(filename, subdirectory)
       }}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :upload_failed}
    end
  end

  defp validate_upload(upload_path, filename, allowed_extensions, max_size) do
    with true <- File.exists?(upload_path),
         true <- valid_extension?(filename, allowed_extensions),
         %{size: size} <- File.stat!(upload_path),
         true <- valid_size?(size, max_size) do
      :ok
    else
      false -> {:error, :file_not_found}
      %{size: size} when size > max_size -> {:error, :file_too_large}
      _ -> {:error, :invalid_file}
    end
  end

  defp sanitize_subdirectory(subdirectory) do
    subdirectory
    |> to_string()
    |> Path.basename()
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
  end
end
