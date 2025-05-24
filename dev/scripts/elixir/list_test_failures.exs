args = System.argv()

{options, args} = OptionParser.parse!(args, strict: [only_files: :boolean])
only_files = Keyword.get(options, :only_files, false)

[manifest_path] = args

if not File.exists?(manifest_path) do
  IO.puts("Can't find test manifest file at #{manifest_path}")
  System.stop()
  Process.sleep(:infinity)
end

failures =
  manifest_path
  |> File.read!()
  |> :erlang.binary_to_term()
  |> elem(1)
  |> Enum.group_by(fn {_, file} -> file end, fn {{_mod, name}, _file} -> name end)

if only_files do
  # Print only the file names
  failures
  |> Map.keys()
  |> Enum.uniq()
  |> Enum.sort()
  |> Enum.each(fn file ->
    IO.puts(file)
  end)
else
  # Print detailed failures with test names
  failures
  |> Enum.each(fn {file, tests} ->
    IO.puts([
      IO.ANSI.red(),
      "Failures in #{file}:\n",
      Enum.map_join(tests, "\n", &"  * #{&1}"),
      "\n",
      IO.ANSI.reset()
    ])
  end)
end
