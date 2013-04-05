/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

class Main
  {
  private static bool version = false;
  private static string dotfile;
  private static string machine;
  private static string sysname;

  [CCode (array_length = false, array_null_terminated = true)]
  private static string[] request_urls;

  private const OptionEntry[] options =
    {
      {"version", 'v', 0, OptionArg.NONE, ref version, "print version string", null},
      {"dotfile", 'g', 0, OptionArg.FILENAME, ref dotfile, "output graphviz dot file", "FILENAME"},
      {"sysname", 's', 0, OptionArg.STRING, ref sysname, "the system name", "SYSNAME"},
      {"machine", 'm', 0, OptionArg.STRING, ref machine, "the hardware name", "MACHINE"},
      {"", 0, 0, OptionArg.STRING_ARRAY, ref request_urls, null, null},
      {null}
    };

  public static int main(string[] args)
    {
#if WIN32
    machine = Environment.get_variable("PROCESSOR_ARCHITECTURE");
    sysname = "Windows";
#else
    var uts = Posix.utsname();
    machine = uts.machine;
    sysname = uts.sysname;
#endif

    try
      {
      var opt_context = new OptionContext("- OptionContext example");
      opt_context.set_help_enabled(true);
      opt_context.add_main_entries(options, null);
      opt_context.parse(ref args);
      }
    catch (OptionError e)
      {
      stdout.printf("error: %s\n", e.message);
      stdout.printf("Run '%s --help' to see a full list of available command line options.\n", args[0]);
      return 0;
      }
    if (version)
      {
      stdout.printf("Karrot 0.1\n");
      return 0;
      }
    try
      {
      var engine = new Karrot.Engine("http://purplekarrot.net/2013/");
      var listsfile = new CMake.Listsfile();
      new CMake.Injector(listsfile, new ArchiveDriver(machine, sysname)).add(engine);
      new CMake.Injector(listsfile, new Subversion()).add(engine);
      new CMake.Injector(listsfile, new GitDriver()).add(engine);
#if WIN32
      new MsiDriver().add(engine);
#else
      new PackageKit().add(engine);
#endif
      foreach (var url in request_urls)
        {
        engine.add_request(url, true);
        }
      if (dotfile != null)
        {
        engine.dot_filename(dotfile);
        }
      int result = engine.run();
      if (result < 0)
        {
        stderr.printf("Error: %s\n", engine.error_message());
        return -1;
        }
      if (result > 0)
        {
        stdout.printf("The request is not satisfiable!\n");
        return -1;
        }
      listsfile.write();
      }
    catch (Error e)
      {
      stderr.printf("Error: %s\n", e.message);
      return -1;
      }
    return 0;
    }
  }
