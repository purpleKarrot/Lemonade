/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

public void extract(string archive, string directory) throws Error
{
	string temp = directory + "-tmp";
	var tempdir = new TempDir(temp);

	extract_local(archive);
	var wanted = analyze_extracted(temp);
	copy_folder(wanted, directory);
}

[Compact]
class TempDir
{
	public TempDir(string dir) throws Error
	{
		saved = Environment.get_current_dir();
		DirUtils.create_with_parents(dir, 0700);
		Environment.set_current_dir(dir);
	}

	~TempDir()
	{
		var tmp = Environment.get_current_dir();
		Environment.set_current_dir(saved);
		DirUtils.remove(tmp);
	}

	public string saved;
}

int extract_local(string archive_path)
{
	Archive.Result ret;

	/* Select which attributes we want to restore. */
	Archive.ExtractFlags flags
		= Archive.ExtractFlags.TIME
		| Archive.ExtractFlags.PERM
		| Archive.ExtractFlags.ACL
		| Archive.ExtractFlags.FFLAGS
		;

	var a = new Archive.Read();
	a.support_filter_all();
	a.support_format_all();

	var ext = new Archive.WriteDisk();
	ext.set_options(flags);
	ext.set_standard_lookup();

	if ((ret = a.open_filename(archive_path, 10240)) != Archive.Result.OK)
	{
		return ret;
	}

	while (true)
	{
		unowned Archive.Entry entry;
		ret = a.next_header(out entry);
		if (ret == Archive.Result.EOF)
		{
			return Archive.Result.OK;
		}
		if (ret != Archive.Result.OK)
		{
			warning(a.error_string());
		}
		if (ret < Archive.Result.WARN)
		{
			return ret;
		}

		ret = ext.write_header(entry);
		if (ret != Archive.Result.OK)
		{
			warning(ext.error_string());
		}
		else if (entry.size() > 0)
		{
			ret = copy_data(a, ext);
			if (ret != Archive.Result.OK)
			{
				warning(ext.error_string());
			}
			if (ret < Archive.Result.WARN)
			{
				return ret;
			}
		}

		ret = ext.finish_entry();
		if (ret != Archive.Result.OK)
		{
			warning(ext.error_string());
		}
		if (ret < Archive.Result.WARN)
		{
			return ret;
		}
	}
}

string analyze_extracted(string directory) throws Error
{
	bool found = false;
	string nested = directory;
	Dir dir = Dir.open (directory, 0);
	string? name = null;

	while ((name = dir.read_name()) != null)
	{
		string path = Path.build_filename(directory, name);

		if (found || !FileUtils.test(path, FileTest.IS_DIR))
		{
			return directory;
		}

		nested = path;
		found = true;
	}

	return nested;
}

void copy_folder(string src, string dst) throws Error
{
	DirUtils.create(dst, 0700);
	Dir dir = Dir.open(src, 0);
	string? name = null;

	while ((name = dir.read_name()) != null)
	{
		string child_src = Path.build_filename(src, name);
		string child_dst = Path.build_filename(dst, name);

		if (!FileUtils.test(child_src, FileTest.IS_DIR))
		{
			FileUtils.remove(child_dst);
		}

		if (!FileUtils.test(child_dst, FileTest.EXISTS))
		{
			FileUtils.rename(child_src, child_dst);
			continue;
		}

		copy_folder(child_src, child_dst);
	}
}

Archive.Result copy_data(Archive.Read ar, Archive.Write aw)
{
	while (true)
	{
		void* buff;
		size_t size;
		Posix.off_t offset;
		Archive.Result ret = ar.read_data_block(out buff, out size, out offset);
		if (ret == Archive.Result.EOF)
		{
			return Archive.Result.OK;
		}
		if (ret != Archive.Result.OK)
		{
			return ret;
		}

		aw.write_data_block(buff, size, offset);
	}
}
