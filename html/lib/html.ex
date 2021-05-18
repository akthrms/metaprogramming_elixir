defmodule Html do
  @external_resource tags_path = Path.join([__DIR__, "tags.txt"])

  @tags (for line <- File.stream!(tags_path, [], :line) do
           line
           |> String.trim()
           |> String.to_atom()
         end)

  for tag <- @tags do
    defmacro unquote(tag)(attrs, do: inner) do
      tag = unquote(tag)

      quote do
        tag(unquote(tag), unquote(attrs), do: unquote(inner))
      end
    end

    defmacro unquote(tag)(attrs \\ []) do
      tag = unquote(tag)

      quote do
        tag(unquote(tag), unquote(attrs))
      end
    end
  end

  defmacro markup(do: block) do
    quote do
      import Kernel, except: [div: 2]

      {:ok, var!(buffer, Html)} = start_buffer([])
      unquote(block)
      result = render(var!(buffer, Html))
      :ok = stop_buffer(var!(buffer, Html))
      result
    end
  end

  def start_buffer(state), do: Agent.start_link(fn -> state end)

  def stop_buffer(buffer), do: Agent.stop(buffer)

  def put_buffer(buffer, content), do: Agent.update(buffer, &[content | &1])

  def render(buffer), do: Agent.get(buffer, & &1) |> Enum.reverse() |> Enum.join()

  defmacro tag(name, attrs \\ []) do
    {inner, attrs} = Keyword.pop(attrs, :do)

    quote do
      tag(unquote(name), unquote(attrs), do: unquote(inner))
    end
  end

  defmacro tag(name, attrs, do: inner) do
    quote do
      put_buffer(var!(buffer, Html), open_tag(unquote_splicing([name, attrs])))
      unquote(inner)
      put_buffer(var!(buffer, Html), "</#{unquote(name)}>")
    end
  end

  def open_tag(name, []) do
    "<#{name}>"
  end

  def open_tag(name, attrs) do
    attr_html =
      for {key, val} <- attrs, into: "" do
        " #{key}=\"#{val}\""
      end

    "<#{name}#{attr_html}>"
  end

  defmacro text(string) do
    quote do
      put_buffer(var!(buffer, Html), to_string(unquote(string)))
    end
  end
end
