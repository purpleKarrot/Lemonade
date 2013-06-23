/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

//#include "line.hpp"
//
//#include <fstream>
//#include <iostream>
//
//#include <boost/spirit/home/qi.hpp>

[Compact]
public class Patch
{
	public Patch(string filename)
	{
		patch = FileStream.open(filename, "r");
		next_line();
	}

	public void apply()
	{
		string left, right;
		while (parse_header(out left, out right))
		{
			var original = FileStream.open(left, "r");
			var patched  = FileStream.open(right, "w");

			apppy_hunks(original, patched);

			while (!original.eof())
			{
				patched.puts(original.read_line());
			}
		}
	}

	void apppy_hunks(FileStream original, FileStream patched)
	{
		int left_line = 1;
		int right_line = 1;

		int r1, r2, r3, r4;
		while (parse_hunk(out r1, out r2, out r3, out r4))
		{
			while (left_line < r1)
			{
				patched.puts(original.read_line());
				++left_line;
				++right_line;
			}

			if (right_line != r3)
			{
				error("rollback!");
			}

			while (r2 != 0 || r4 != 0)
			{
				next_line();

				if (line[0] == '-' || line[0] == ' ')
				{
					string original_line = original.read_line();
					if (line.substring(1) != original_line)
					{
						error("rollback!");
					}

					++left_line;
					--r2;
				}

				if (line[0] == '+' || line[0] == ' ')
				{
					patched.puts(line.substring(1));
					++right_line;
					--r4;
				}

				if (r2 < 0 || r4 < 0)
				{
					error("rollback!");
				}
			}
		}
	}

	bool parse_header(out string left, out string right)
	{
		while (true)
		{
			MatchInfo info;
			if (/^--- (\S+)/.match(line, 0, out info))
			{
				left = info.fetch(1);
			}
			else
			{
				next_line();
				continue;
			}

			if (!next_line())
			{
				return false;
			}

			if (/^\+\+\+ (\S+)/.match(line, 0, out info))
			{
				right = info.fetch(1);
				return true;
			}
		}
	}

	bool parse_hunk(out int r1, out int r2, out int r3, out int r4)
	{
		MatchInfo info;
		if (/^@@ -(\d+),(\d+) \+(\d+),(\d+) @@/.match(line, 0, out info))
		{
			r1 = int.parse(info.fetch(1));
			r2 = int.parse(info.fetch(2));
			r3 = int.parse(info.fetch(3));
			r4 = int.parse(info.fetch(4));
			return true;
		}

		return false;
	}

	bool next_line()
	{
		return (line = patch.read_line()) == null;
	}

	public FileStream patch;
	public string? line;
}

public int patch(string[] args)
{
	return 0;
}
