/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

[DBus (name = "org.freedesktop.PackageKit")]
interface Connection : Object
  {
  public abstract string distro_id {owned get;}
  public abstract string get_tid() throws IOError;
  }

[DBus (name = "org.freedesktop.PackageKit.Transaction")]
interface Transaction : Object
  {
  public abstract void resolve(string filter, string[] packages) throws IOError;
  public abstract void install_packages(bool only_trusted, string[] package_ids) throws IOError;
  public signal void package(string info, string package_id, string summary);
  public signal void item_progress(string id, uint percentage);
  public signal void finished(string exit, uint runtime);
  }

class PackageKit: Driver, Object
  {
  public PackageKit() throws IOError
    {
    this.connection = Bus.get_proxy_sync(BusType.SYSTEM,
      "org.freedesktop.PackageKit", "/org/freedesktop/PackageKit");
    var distro_id = connection.distro_id;
    this.distro = distro_id.substring(0, distro_id.index_of_char(';'));
    }
  ~PackageKit()
    {
    if (package_ids.length == 0)
      {
      return;
      }
    try
      {
      var loop = new MainLoop();
      Transaction transaction = Bus.get_proxy_sync(
          BusType.SYSTEM,
          "org.freedesktop.PackageKit",
          connection.get_tid());
      transaction.item_progress.connect((id, percent) =>
        {
        stdout.printf("%02d%% %s\n", (int)percent, id);
        });
      transaction.finished.connect((exit, runtime) =>
        {
        loop.quit();
        });
      transaction.install_packages(true, package_ids);
      loop.run();
      }
    catch (Error e)
      {
      stderr.printf("bad: %s\n", e.message);
      }
    }
  private unowned string name()
    {
    return "packagekit";
    }
  private unowned string[] fields()
    {
    const string fields[] = {"name", null, "distro", "*"};
    return fields;
    }
  private void filter (Karrot.Dictionary fields, Karrot.AddFun add_fun)
    {
    unowned string distro = fields.lookup("distro");
    if (distro != "*" && distro != this.distro)
      {
      return;
      }
    try
      {
      var loop = new MainLoop();
      Transaction transaction = Bus.get_proxy_sync(
          BusType.SYSTEM,
          "org.freedesktop.PackageKit",
          connection.get_tid());
      transaction.package.connect((info, package_id) =>
        {
        int begin = package_id.index_of_char(';') + 1;
        int end = package_id.index_of_char(';', begin);
        string[] values =
          {
          "version", package_id.slice(begin, end),
          "packageid", package_id,
          "info", info
          };
        add_fun(values, true);
        });
      transaction.finished.connect((exit, runtime) =>
        {
        loop.quit();
        });
      transaction.resolve("none", {fields.lookup("name")});
      loop.run();
      }
    catch (Error e)
      {
      stderr.printf("bad: %s\n", e.message);
      }
    }
  private void download (Karrot.Implementation impl, bool requested) throws Error
    {
    if (impl.values.lookup("info") != "installed")
      {
      package_ids += impl.values.lookup("packageid");
      }
    }
  private Connection connection;
  private string[] package_ids;
  private string distro;
  }
