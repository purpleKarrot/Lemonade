/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#include <karrot.h>

#define SVN_DEPRECATED
#include <svn_client.h>
#include <svn_cmdline.h>
#include <svn_path.h>
#include <svn_pools.h>
#include <svn_config.h>
#include <svn_fs.h>

typedef struct Subversion Subversion;

struct Subversion
{
	KDriver driver;
	apr_pool_t *pool;
	svn_client_ctx_t *client;
	svn_error_t *error;
};

struct InfoBaton
{
	char const *url;
	svn_revnum_t rev;
	int url_ok, rev_ok;
};

static svn_error_t *
info_receiver(void* baton, const char* path, const svn_info_t* info, apr_pool_t *pool)
{
	struct InfoBaton* info_baton = (struct InfoBaton*) baton;
	info_baton->url_ok = strcmp(info_baton->url, info->URL) == 0;
	info_baton->rev_ok = info_baton->rev == info->rev;
	return 0;
}

static int
handle(KDriver const *driver, KImplementation const *impl, int requested)
{
	Subversion *self = (Subversion*) driver;

	svn_revnum_t result_rev;
	svn_opt_revision_t revision;
	svn_opt_revision_t peg_revision;
	peg_revision.kind = svn_opt_revision_unspecified;

	char const *url = k_dictionary_get(k_implementation_get_values(impl), "href");
	char const *tag = k_dictionary_get(k_implementation_get_values(impl), "tag");
	char const *path = k_dictionary_get(k_implementation_get_meta(impl), "name");

	char *revchr = strrchr(tag, '@');
	if (revchr != NULL)
	{
		revision.kind = svn_opt_revision_number;
		revision.value.number = apr_atoi64(revchr + 1);
		tag = apr_pstrndup(self->pool, tag, revchr - tag);
	}
	else
	{
		revision.kind = svn_opt_revision_head;
		revision.value.number = 0;
	}

	if (strstr(tag, "://") == NULL)
	{
		url = tag;
	}
	else
	{
		url = apr_pstrcat(self->pool, url, "/tags/", tag);
	}

	apr_finfo_t finfo;
	apr_status_t statcode;
	statcode = apr_stat(&finfo, path /*TODO: ".svn"*/, APR_FINFO_TYPE, self->pool);
	if (statcode != APR_SUCCESS)
	{
		char buffer[256];
		puts(apr_strerror(statcode, buffer, sizeof(buffer)));
		return;
	}

	if (finfo.filetype == APR_NOFILE)
	{
		self->error = svn_client_checkout3(
			&result_rev,
			url,
			path,
			&peg_revision,
			&revision,
			svn_depth_infinity,
			TRUE,  // ignore_externals
			FALSE, // allow_unver_obstructions
			self->client,
			self->pool);
		if (self->error)
		{
			return -1;
		}

		return 0;
	}

	struct InfoBaton info_baton = {url, revision.value.number, FALSE, FALSE};
	self->error = svn_client_info2(
		path,
		NULL,  // peg_revision
		NULL,  // revision
		info_receiver,
		&info_baton,
		svn_depth_empty,
		NULL,  // changelists
		self->client,
		self->pool);
	if (self->error)
	{
		return -1;
	}

	if (!info_baton.url_ok)
	{
		self->error = svn_client_switch2(
			&result_rev,
			path,
			url,
			&peg_revision,
			&revision,
			svn_depth_infinity,
			TRUE,  // depth_is_sticky,
			TRUE,  // ignore_externals
			FALSE, // allow_unver_obstructions
			self->client,
			self->pool);
		if (self->error)
		{
			return -1;
		}
	}
	else if(revision.kind == svn_opt_revision_number && !info_baton.rev_ok)
	{
		apr_array_header_t *paths = apr_array_make(self->pool, 1, sizeof(const char*));
		apr_array_header_t *result_revs;
		APR_ARRAY_PUSH(paths, const char*) = path;
		self->error = svn_client_update3(
			&result_revs,
			paths,
			&revision,
			svn_depth_infinity,
			TRUE,  // depth_is_sticky,
			TRUE,  // ignore_externals
			FALSE, // allow_unver_obstructions
			self->client,
			self->pool);
		if (self->error)
		{
			return -1;
		}
	}

	return 0;
}

static char const *
get_error(KDriver const *driver)
{
	Subversion *self = (Subversion*) driver;

	if (!self->error)
	{
		return "No Error";
	}

	return self->error->message;
}

KARROT_EXPORT KDriver*
k_driver_new(void)
{
	svn_error_t *error = NULL;

	if (svn_cmdline_init("lem", NULL) != EXIT_SUCCESS)
	{
		goto error;
	}

	apr_pool_t *pool = svn_pool_create(NULL);
	Subversion *svn = apr_pcalloc(pool, sizeof(Subversion));
	svn->driver.handle = handle;
	svn->driver.get_error = get_error;
	svn->pool = pool;

	/* Initialize the FS library. */
	error = svn_fs_initialize(pool);
	if (error)
	{
		goto error;
	}

	/* Make sure the ~/.subversion run-time config files exist */
	error = svn_config_ensure(0, pool);
	if (error)
	{
		goto error;
	}

	/* Initialize and allocate the client_ctx object. */
	error = svn_client_create_context(&svn->client, pool);
	if (error)
	{
		goto error;
	}

	/* Load the run-time config file into a hash */
	error = svn_config_get_config(&svn->client->config, 0, pool);
	if (error)
	{
		goto error;
	}

	/* Make the client_ctx capable of authenticating users */
	error = svn_cmdline_create_auth_baton(
		&svn->client->auth_baton,
		FALSE,
		NULL,
		NULL,
		NULL,
		FALSE,
		FALSE,
		NULL,
		NULL,
		NULL,
		pool);
	if (error)
	{
		goto error;
	}

	return (KDriver*) svn;

error:
	svn_pool_destroy(pool);
	return NULL;
}

KARROT_EXPORT void
k_driver_free(KDriver *self)
{
	Subversion *svn = (Subversion*) self;
	apr_pool_t *pool = svn->pool;
	svn_pool_destroy(pool);
}
