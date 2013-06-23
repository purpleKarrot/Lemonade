/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#include <karrot.h>
#include "ar_driver.h"

typedef struct Driver Driver;

struct Driver
{
	KDriver base;
	gchar* sysname;
	gchar* machine;
	GError *error;
	Downloader* downloader;
};

static int
fields(KDriver const *driver, KDictionary *dict)
{
	k_dictionary_set(dict, "sysname", "*");
	k_dictionary_set(dict, "machine", "*");
	k_dictionary_set(dict, "href", NULL );
	k_dictionary_set(dict, "checksum", NULL );
	return 0;
}

static int
filter(KDriver const *driver, KDictionary const *fields, KAdd add, void *target)
{
	Driver *self = (Driver*) driver;

	gchar const *sysname = k_dictionary_get(fields, "sysname");
	if (g_strcmp0(sysname, "*") != 0 && g_strcmp0(sysname, self->sysname) != 0)
	{
		return 0;
	}

	gchar const *machine = k_dictionary_get(fields, "machine");
	if (g_strcmp0(machine, "*") != 0 && g_strcmp0(machine, self->machine) != 0)
	{
		return 0;
	}

	add(fields, FALSE, target);
	return 0;
}

static int
handle(KDriver const *driver, KImplementation const *impl, int requested)
{
	Driver *self = (Driver*) driver;

	KDictionary const *values = k_implementation_get_values(impl);
	gchar const *href = k_dictionary_get(values, "href");
	gchar const *checksum = k_dictionary_get(values, "checksum");

	gchar const *directory = k_implementation_get_name(impl);
	gchar *file_path = downloader_get(self->downloader, href, checksum);

	GError *error = NULL;
	extract(file_path, directory, &error);

	if (error)
	{
		g_free(file_path);
		g_propagate_error(&self->error, error);
		return -1;
	}

	g_free(file_path);
	return 0;
}

static char const *
get_error(KDriver const *driver)
{
	Driver *self = (Driver*) driver;
	return self->error ? self->error->message : NULL ;
}

KARROT_EXPORT KDriver*
k_driver_new(void)
{
	Driver *driver = (Driver*) g_slice_alloc0(sizeof(Driver));
	driver->base.fields = fields;
	driver->base.filter = filter;
	driver->base.handle = handle;
	driver->base.get_error = get_error;

	driver->sysname = g_strdup("Linux");
	driver->machine = g_strdup("x86_64");

	driver->downloader = downloader_new();

	return (KDriver*) driver;
}

KARROT_EXPORT void
k_driver_free(KDriver *driver)
{
	Driver *self = (Driver*) driver;
	g_free(self->sysname);
	g_free(self->machine);
	g_error_free(self->error);
	downloader_free(self->downloader);
	g_slice_free(Driver, self);
}
