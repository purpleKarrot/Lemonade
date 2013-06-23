/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

[CCode(cheader_filename = "karrot.h", cprefix = "K", lower_case_cprefix = "k_")]
namespace Karrot
{

[Compact]
public class Dictionary
{
	public Dictionary();
	public unowned string @get (string key);
	public void @set (string key, string? val);
	public void @foreach (Visit visit);
}

[Compact, Immutable]
public class Implementation
{
	public unowned string name { get; }
	public unowned string version { get; }
	public unowned string component { get; }
	public unowned string driver { get; }
	public Dictionary meta { get; }
	public Dictionary variant { get; }
	public Dictionary values { get; }
}

public delegate void Add (Dictionary values, bool native);
public delegate bool Visit (string key, string val);

} // namespace Karrot
