/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef LEM_DRIVER_HPP
#define LEM_DRIVER_HPP

#include <karrot.h>
#include <boost/filesystem/path.hpp>
#include "library.hpp"

namespace lem
{

class driver
{
	using new_fn_t = KDriver* (*)();
	using free_fn_t = void(*)(KDriver*);
	using impl_t = std::unique_ptr<KDriver, free_fn_t>;

public:
	driver(boost::filesystem::path const& path)
		: name_{path.stem().string()}
		, library_{path.string()}
	{
		new_fn_t new_fn;
		library_.require("k_driver_new", new_fn);
		library_.require("k_driver_free", free_fn);
		impl_ = new_fn();
	}

	~driver()
	{
		if (free_fn)
		{
			free_fn(impl_);
		}
	}

	driver(driver&& other)
		: name_{std::move(other.name_)}
		, library_{std::move(other.library_)}
		, free_fn{other.free_fn}
		, impl_{other.impl_}
	{
		other.free_fn = nullptr;
	}

	driver& operator=(driver&& other)
	{
		name_ = std::move(other.name_);
		library_ = std::move(other.library_);
		free_fn = other.free_fn;
		impl_ = other.impl_;
		other.free_fn = nullptr;
		return *this;
	}

	driver(driver const&) = delete;
	driver& operator=(driver const&) = delete;

	const char* get_name() const
	{
		return name_.c_str();
	}

	KDriver const* get_driver() const
	{
		return impl_;
	}

private:
	std::string name_;
	lem::library library_;
	free_fn_t free_fn;
	KDriver* impl_;
};

} // namespace lem

#endif /* LEM_DRIVER_HPP */
