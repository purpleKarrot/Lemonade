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

public class PkDriver
{
	public PkDriver() throws IOError
	{
		this.connection = Bus.get_proxy_sync(BusType.SYSTEM,
				"org.freedesktop.PackageKit", "/org/freedesktop/PackageKit");
		var distro_id = connection.distro_id;
		this.distro = distro_id.substring(0, distro_id.index_of_char(';'));
	}

	public int filter (Karrot.Dictionary fields, Karrot.Add add)
	{
		unowned string distro = fields["distro"];
		if (distro != "*" && distro != this.distro)
		{
			return 0;
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
				var values = new Karrot.Dictionary();
				values["version"] = package_id.slice(begin, end);
				values["packageid"] = package_id;
				values["info"] = info;
				add(values, true);
			});

			transaction.finished.connect((exit, runtime) => { loop.quit(); });
			transaction.resolve("none", {fields["name"]});
			loop.run();
		}
		catch (IOError error)
		{
			this.error_message = error.message;
			return -1;
		}

		return 0;
	}

	public int handle (Karrot.Implementation impl, bool required)
	{
		if (impl.values["info"] != "installed")
		{
			package_ids += impl.values["packageid"];
		}

		return 0;
	}

	public int commit ()
	{
		if (package_ids.length == 0)
		{
			return 0;
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
				stdout.printf("%02d%% %s\n", (int) percent, id);
			});

			transaction.finished.connect((exit, runtime) => { loop.quit(); });
			transaction.install_packages(true, package_ids);
			loop.run();
		}
		catch (IOError error)
		{
			this.error_message = error.message;
			return -1;
		}

		return 0;
	}

	public unowned string get_error_message ()
	{
		return error_message;
	}

	private Connection connection;
	private string[] package_ids;
	private string distro;
	private string error_message;
}
