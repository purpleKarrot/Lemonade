/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

[Compact]
class Progress
  {
  public Progress(string name)
    {
    this.name = name;
    this.steps = {0, 0, 0};
    }
  ~Progress()
    {
    stdout.puts("\n");
    }
  public void update(int step, size_t completed, size_t total)
      {
      assert(step < 3);
      steps[step] = total > 0 ? (60 * completed) / total : 0;
      }
  public void print()
      {
      size_t i = 1;
      stdout.printf("%-16s[", name);
      for (; i <= steps[0]; ++i)
        {
        stdout.putc('#');
        }
      for (; i <= steps[1]; ++i)
        {
        stdout.putc('=');
        }
      for (; i <= steps[2]; ++i)
        {
        stdout.putc('-');
        }
      for (; i <= 60; ++i)
        {
        stdout.putc(' ');
        }
      stdout.puts("]\r");
      }
  public string name;
  public size_t steps[3];
  }
