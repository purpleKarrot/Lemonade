/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef LEM_LIBRARY_HPP
#define LEM_LIBRARY_HPP

#if _WIN32
#  include <windows.h>
#else
#  include <dlfcn.h>
#endif

#include <memory>
#include <system_error>

namespace lem
{

class library
{
public:
	library(std::string const& name)
#if _WIN32
		: handle{LoadLibrary(name.c_str()), FreeLibrary}
#else
		: handle{dlopen(name.c_str(), RTLD_LAZY), dlclose}
#endif
	{
		if (!handle)
		{
			throw_exception("Failed to load shared library '" + name + "'.");
		}
	}

public:
	template<typename Function>
	void load(std::string const& name, Function& function)
	{
#if _WIN32
		function = (Function) GetProcAddress(handle.get(), name.c_str());
#else
		function = (Function) dlsym(handle.get(), name.c_str());
#endif
	}

	template<typename Function>
	void require(std::string const& name, Function& function)
	{
		load(name, std::forward<Function&>(function));
		if (!function)
		{
			throw_exception("Failed to load function '" + name + "'.");
		}
	}

private:
	static void throw_exception(std::string message)
	{
#if _WIN32
		std::error_code error{GetLastError(), std::system_category()};
		throw std::system_error{error, message};
#else
		char *error = dlerror();
		if (error != nullptr)
		{
			message += '\n';
			message += error;
		}

		throw std::runtime_error{message};
#endif
	}

private:
#if _WIN32
	std::unique_ptr<void, BOOL WINAPI (*)(HMODULE)> handle;
#else
	std::unique_ptr<void, int (*)(void*)> handle;
#endif
};

} // namespace lem

#endif /* LEM_LIBRARY_HPP */
