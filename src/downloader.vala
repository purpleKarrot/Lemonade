/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

[Compact]
private class Downloader
  {
  public Downloader()
    {
    curl.setopt(Curl.Option.WRITEFUNCTION, FileStream.write);
    curl.setopt(Curl.Option.USERAGENT, "karrot/0.1");
    curl.setopt(Curl.Option.FOLLOWLOCATION, true);
//  curl.setopt(Curl.Option.PROGRESSFUNCTION, progress);
//  curl.setopt(Curl.Option.NOPROGRESS, false);
    }
  public string get(string url, string checksum)
    {
    var filepath = Path.build_filename(".archives", urlencode(url));
    if (FileUtils.test(filepath, FileTest.EXISTS))
      {
      if (check_checksum(FileStream.open(filepath, "rb"), checksum))
        {
        return filepath;
        }
      }
    if (!download(url, FileStream.open(filepath, "wb")))
      {
      error("error downloading file");
      }
    if (!check_checksum(FileStream.open(filepath, "rb"), checksum))
      {
      error("file checksum mismatch!");
      }
    return filepath;
    }
  public bool download(string url, FileStream file)
    {
    curl.setopt(Curl.Option.URL, url);
    curl.setopt(Curl.Option.FILE, file);
    foreach (unowned string proxy in proxy_factory.get_proxies(url))
      {
      curl.setopt(Curl.Option.PROXY, proxy);
      var res = curl.perform();
      if (res == Curl.Code.OK)
        {
        return true;
        }
      }
    return false;
    }
  public static string urlencode(string input)
    {
    var escaped = new StringBuilder();
    var length = input.length;
    for (int i = 0; i < length; ++i)
      {
      char c = input[i];
      if ((48 <= c && c <= 57)
       || (65 <= c && c <= 90)
       || (97 <= c && c <= 122)
       || (c == '~' || c == '-' || c == '_' || c == '.'))
        {
        escaped.append_c(c);
        }
      else
        {
        char dig1 = (c & 0xF0) >> 4;
        char dig2 = (c & 0x0F);
        if (0 <= dig1 && dig1 <= 9)
          {
          dig1 += 48;
          }
        if (10 <= dig1 && dig1 <= 15)
          {
          dig1 += 65 - 10;
          }
        if (0 <= dig2 && dig2 <= 9)
          {
          dig2 += 48;
          }
        if (10 <= dig2 && dig2 <= 15)
          {
          dig2 += 65 - 10;
          }
        escaped.append_c('%');
        escaped.append_c(dig1);
        escaped.append_c(dig2);
        }
      }
    return (owned) escaped.str;
    }
  public static bool check_checksum(FileStream file, string sum)
    {
    string[] components = sum.split("=", 2);
    if (components.length != 2)
      {
      return false;
      }
    ChecksumType checksum_type;
    switch (components[0])
      {
      case "md5":
      case "MD5":
        checksum_type = ChecksumType.MD5;
        break;
      case "sha1":
      case "SHA1":
        checksum_type = ChecksumType.SHA1;
        break;
      case "sha256":
      case "SHA256":
        checksum_type = ChecksumType.SHA256;
        break;
      default:
        return false;
      }
    if (components[1].length != checksum_type.get_length() * 2)
      {
      return false;
      }
    size_t size;
    uint8 buffer[1024];
    var checksum = new Checksum(checksum_type);
    while ((size = file.read(buffer)) > 0)
      {
      checksum.update(buffer, size);
      }
    return components[1].down() == checksum.get_string();
    }
  public Curl.EasyHandle curl = new Curl.EasyHandle();
  public Libproxy.ProxyFactory proxy_factory = new Libproxy.ProxyFactory();
  }
