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
  public class Error
    {
    public void set (string message);
    }
  [Compact, Immutable]
  public class Dictionary
    {
    public unowned string lookup (string key);
    public void @foreach (Mapping func);
    }
  [Compact, Immutable]
  public class Implementation
    {
    public string name { get; }
    public string component { get; }
    public string version { get; }
    public Dictionary variant { get; }
    public Dictionary values { get; }
    }
  public struct Driver
    {
    public unowned string name;
    public unowned string[] fields;
    public Filter filter;
    public Download download;
    }
  [Compact]
  public class Engine
    {
    public Engine (string namespace_uri);
    public void add_driver (owned Driver driver);
    public void add_request (string url, bool source);
    public void dot_filename (string filename);
    public unowned string error_message ();
    public int run ();
    }
  public delegate void AddFun (string[] values, bool native);
  public delegate void Download (Implementation impl, bool requested, Error error);
  public delegate void Filter (Dictionary fields, AddFun add_fun);
  public delegate void Mapping (string key, string value);
  }
