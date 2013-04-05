/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

public interface Driver: Object
  {
  public void add(Karrot.Engine engine)
    {
    engine.add_driver({name(), fields(), filter, do_download});
    }
  protected void do_download(Karrot.Implementation impl, bool requested, Karrot.Error error)
    {
    try
      {
      download(impl, requested);
      }
    catch (Error e)
      {
      error.set("%s:%d: %s".printf(e.domain.to_string(), e.code, e.message));
      }
    }
  protected abstract unowned string name();
  protected abstract unowned string[] fields();
  protected abstract void filter(Karrot.Dictionary fields, Karrot.AddFun add_fun);
  protected abstract void download(Karrot.Implementation impl, bool requested) throws Error;
  }

class DriverDecorator: Driver, Object
  {
  public DriverDecorator(Driver component)
    {
    this.component = component;
    }
  private unowned string name()
    {
    return component.name();
    }
  private unowned string[] fields()
    {
    return component.fields();
    }
  private void filter(Karrot.Dictionary fields, Karrot.AddFun add_fun)
    {
    component.filter(fields, add_fun);
    }
  private void download(Karrot.Implementation impl, bool requested) throws Error
    {
    component.download(impl, requested);
    }
  private Driver component;
  }
