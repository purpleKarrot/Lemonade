/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#include <msi.h>
#include <karrot.h>

static INT CALLBACK install_ui(LPVOID context, UINT msg_type, LPCTSTR message)
{
}

static int fields(void *self, KDictionary *dict)
{
	k_dictionary_set(dict, ":xmlns", "http://purplekarrot.net/2013/msi");
	k_dictionary_set(dict, "product", NULL);
	k_dictionary_set(dict, "feature", "-");
	k_dictionary_set(dict, "href", "-");
	return 0;
}

static int filter(void *self, KDictionary const *fields, KAdd add, void *target)
{
	char const *product = k_dictionary_get(fields, "product");
	char const *feature = k_dictionary_get(fields, "feature");
	char const *href = k_dictionary_get(fields, "href");

	INSTALLSTATE state;
	state = MsiQueryProductState(product);
	state = MsiQueryFeatureState(product, feature);

	char version[256];
	char instloc[256];

	MsiGetProductInfo(product, INSTALLPROPERTY_VERSION, version, NULL);
	MsiGetProductInfo(product, INSTALLPROPERTY_INSTALLLOCATION, instloc, NULL);

	printf("%s version %s\n", product, version);
	printf("%s instloc %s\n", product, instloc);
}

static int handle(void *ctx, KImplementation const *impl, int requested)
{
	KDictionary const *values = k_implementation_get_values(impl);
	char const *href = k_dictionary_get(values, "href");
	MsiInstallProduct(href, "ADDLOCAL=ALL");
	return 0;
}

static void finalize(void *ctx)
{
}

static char const* get_error_message(void *ctx)
{
	return "Unknown Error";
}

KARROT_EXPORT int k_driver_init(KDriver *driver)
{
	DWORD msg_filter
		= INSTALLLOGMODE_PROGRESS
		| INSTALLLOGMODE_FATALEXIT
		| INSTALLLOGMODE_ERROR
		| INSTALLLOGMODE_WARNING
		| INSTALLLOGMODE_USER
		| INSTALLLOGMODE_INFO
		| INSTALLLOGMODE_RESOLVESOURCE
		| INSTALLLOGMODE_OUTOFDISKSPACE
		| INSTALLLOGMODE_ACTIONSTART
		| INSTALLLOGMODE_ACTIONDATA
		| INSTALLLOGMODE_COMMONDATA
		| INSTALLLOGMODE_PROGRESS
		| INSTALLLOGMODE_INITIALIZE
		| INSTALLLOGMODE_TERMINATE
		| INSTALLLOGMODE_SHOWDIALOG
		;

	MsiSetExternalUI(install_ui, msg_filter, NULL);
	MsiSetInternalUI(INSTALLUILEVEL_NONE | INSTALLUILEVEL_SOURCERESONLY, NULL);

	driver->fields = fields;
	driver->handle = handle;
	driver->finalize = finalize;
	driver->get_error_message = get_error_message;
	driver->ctx = subversion;

	return 0;
}
