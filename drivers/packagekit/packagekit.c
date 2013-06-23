/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#include <karrot.h>
#include "pk_driver.h"

typedef struct Driver Driver;

struct Driver
{
	KDriver base;
	PkDriver* impl;
};

static int
fields(KDriver const *driver, KDictionary *dict)
{
	k_dictionary_set(dict, "name", NULL );
	k_dictionary_set(dict, "distro", "*");
	return 0;
}

static int
filter(KDriver const *driver, KDictionary const *fields, KAdd add, void *target)
{
	Driver *self = (Driver*) driver;
	return pk_driver_filter(self->impl, (KDictionary*) fields, add, target);
}

static int
handle(KDriver const *driver, KImplementation const *impl, int requested)
{
	Driver *self = (Driver*) driver;
	return pk_driver_handle(self->impl, (KImplementation*) impl, requested);
}

static int
commit(KDriver const *driver)
{
	Driver *self = (Driver*) driver;
	return pk_driver_commit(self->impl);
}

static char const *
get_error(KDriver const *driver)
{
	Driver *self = (Driver*) driver;
	return pk_driver_get_error_message(self->impl);
}

KARROT_EXPORT KDriver*
k_driver_new(void)
{
	Driver *driver = (Driver*) g_slice_alloc0(sizeof(Driver));
	driver->impl = pk_driver_new(NULL);
	driver->base.fields = fields;
	driver->base.filter = filter;
	driver->base.handle = handle;
	driver->base.commit = commit;
	driver->base.get_error = get_error;
	return (KDriver*) driver;
}

KARROT_EXPORT void
k_driver_free(KDriver *driver)
{
	g_slice_free(Driver, (Driver*) driver);
}
