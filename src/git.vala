/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

//static int fetch_progress(const git_transfer_progress *stats, void *payload)
//  {
//  Progress &progress = *reinterpret_cast<Progress*>(payload);
//  progress.update(2, stats->received_objects, stats->total_objects);
//  progress.update(1, stats->indexed_objects, stats->total_objects);
//  progress.print();
//  return 0;
//  }

class GitDriver: Driver, Object
  {
  public unowned string name()
    {
    return "git";
    }
  public unowned string[] fields()
    {
    const string fields[] = {};
    return fields;
    }
  public void filter(Karrot.Dictionary fields, Karrot.AddFun add_fun)
    {
    }
  public void download(Karrot.Implementation impl, bool requested) throws Error
    {
    unowned string href = impl.values.lookup("href");
    unowned string hash = impl.values.lookup("tag");
    unowned string path = impl.name;

    var progress = new Progress(path);
    Git.TransferProgress transfer_progress = (stats) =>
      {
      progress.update(2, stats.received_objects, stats.total_objects);
      progress.update(1, stats.indexed_objects, stats.total_objects);
      progress.print();
      return Git.Error.OK;
      };
    Git.Progress checkout_progress = (path, completed_steps, total_steps) =>
      {
      progress.update(0, completed_steps, total_steps);
      progress.print();
      };

    Git.Remote origin;
    Git.Repository repo;
    if (Git.Repository.open(out repo, path) == Git.Error.OK)
      {
      if (repo.get_remote(out origin, "origin") != Git.Error.OK)
        {
        throw_error();
        }
      if (origin.url != href)
        {
        error("different origin");
        }
      }
    else
      {
      if (Git.Repository.init(out repo, path, false) != Git.Error.OK)
        {
        throw_error();
        }
      if (repo.create_remote(out origin, "origin", href) != Git.Error.OK)
        {
        throw_error();
        }
      }
    origin.update_fetchhead = false;
    origin.set_cred_acquire((out cred, url, username_from_url, allowed_types) =>
      {
      string username, password;
      stdout.printf("cred required for %s\n", url);
      stdout.puts("username: ");
      if (username_from_url != null)
        {
        stdout.printf("%s\n", username_from_url);
        username = username_from_url;
        }
      else
        {
        username = stdin.read_line();
        }
      stdout.puts("password: ");
      password = stdin.read_line();
      return Git.cred.create_userpass_plaintext(out cred, username, password);
      });
    if (origin.connect(Git.Direction.FETCH) != Git.Error.OK)
      {
      throw_error();
      }
    if (origin.download(transfer_progress) != Git.Error.OK)
      {
      throw_error();
      }
    if (origin.update_tips() != Git.Error.OK)
      {
      throw_error();
      }
    Git.Object object;
    if (repo.parse(out object, hash) != Git.Error.OK)
      {
      throw_error();
      }
    if (repo.set_head_detached(object.id) != Git.Error.OK)
      {
      throw_error();
      }
    var checkout_opts = Git.checkout_opts();
    checkout_opts.version = Git.checkout_opts.VERSION;
    checkout_opts.checkout_strategy = Git.CheckoutStategy.SAFE;
    checkout_opts.progress = checkout_progress;
    if (repo.checkout_tree(object, checkout_opts) != Git.Error.OK)
      {
      throw_error();
      }
    }
  private static void throw_error() throws Error
    {
    unowned Git.ErrorInfo giterr = Git.ErrorInfo.get_last();
    throw new Error(Quark.from_string("GIT"), giterr.class, giterr.message);
    }
  }
