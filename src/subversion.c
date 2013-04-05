/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#include "lemonade.h"

#define SVN_DEPRECATED
#include <svn_client.h>
#include <svn_cmdline.h>
#include <svn_path.h>
#include <svn_pools.h>
#include <svn_config.h>
#include <svn_fs.h>

#define TYPE_SUBVERSION (subversion_get_type ())
#define SUBVERSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_SUBVERSION, Subversion))
#define SUBVERSION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_SUBVERSION, SubversionClass))
#define IS_SUBVERSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_SUBVERSION))
#define IS_SUBVERSION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_SUBVERSION))
#define SUBVERSION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_SUBVERSION, SubversionClass))

typedef struct _Subversion Subversion;
typedef struct _SubversionClass SubversionClass;
typedef struct _SubversionPrivate SubversionPrivate;

struct _Subversion
  {
  GObject parent_instance;
  SubversionPrivate * priv;
  };

struct _SubversionClass
  {
  GObjectClass parent_class;
  };

struct _SubversionPrivate
  {
  apr_pool_t* pool;
  svn_client_ctx_t* ctx;
  };

static gpointer subversion_parent_class = NULL;
static DriverIface* subversion_driver_parent_iface = NULL;

GType subversion_get_type(void) G_GNUC_CONST;

#define SUBVERSION_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), TYPE_SUBVERSION, SubversionPrivate))

Subversion* subversion_construct(GType object_type)
  {
  Subversion *self = NULL;
  apr_pool_t *pool = NULL;
  svn_error_t *error = NULL;
  svn_client_ctx_t *ctx = NULL;
  self = (Subversion*) g_object_new(object_type, NULL);
  if (svn_cmdline_init("lem", NULL) != EXIT_SUCCESS)
    {
    return self;
    }
  pool = svn_pool_create(NULL);
  /* Initialize the FS library. */
  error = svn_fs_initialize(pool);
  if (error)
    {
    puts(error->message);
    return self;
    }
  /* Make sure the ~/.subversion run-time config files exist */
  error = svn_config_ensure(0, pool);
  if (error)
    {
    puts(error->message);
    return self;
    }
  /* Initialize and allocate the client_ctx object. */
  error = svn_client_create_context(&ctx, pool);
  if (error)
    {
    puts(error->message);
    return self;
    }
  /* Load the run-time config file into a hash */
  error = svn_config_get_config(&ctx->config, 0, pool);
  if (error)
    {
    puts(error->message);
    return self;
    }
  /* Make the client_ctx capable of authenticating users */
  error = svn_cmdline_create_auth_baton(
      &ctx->auth_baton,
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
    puts(error->message);
    return self;
    }
  self->priv->pool = pool;
  self->priv->ctx = ctx;
  return self;
  }

Subversion* subversion_new(void)
  {
  return subversion_construct(TYPE_SUBVERSION);
  }

static const gchar* subversion_name(Driver* base)
  {
  return "subversion";
  }

static gchar** subversion_fields(Driver *driver, int *result_length)
  {
  if (result_length)
    {
    *result_length = 0;
    }
  return NULL;
  }

static void subversion_filter(
    Driver *driver,
    const KDictionary *fields,
    KAddFun add,
    void *target)
  {
  }

struct InfoBaton
  {
  char const *url;
  svn_revnum_t rev;
  gboolean url_ok, rev_ok;
  };

static svn_error_t* info_receiver(
    void* baton,
    const char* path,
    const svn_info_t* info,
    apr_pool_t *pool)
  {
  struct InfoBaton* info_baton = (struct InfoBaton*) baton;
  info_baton->url_ok = strcmp(info_baton->url, info->URL) == 0;
  info_baton->rev_ok = info_baton->rev == info->rev;
  return 0;
  }

static void subversion_download(
    Driver* base,
    const KImplementation* impl,
    gboolean requested,
    GError** error)
  {
  Subversion *self = (Subversion*) base;
  apr_pool_t *pool = self->priv->pool;
  svn_client_ctx_t *ctx = self->priv->ctx;

  svn_error_t* svnerr = NULL;
  svn_revnum_t result_rev;
  svn_opt_revision_t revision;
  svn_opt_revision_t peg_revision;
  peg_revision.kind = svn_opt_revision_unspecified;

  KDictionary const *values = k_implementation_get_values(impl);
  char const *url = k_dictionary_lookup(values, "href");
  char const *tag = k_dictionary_lookup(values, "tag");
  char const *path = k_implementation_get_name(impl);

  char *revchr = strrchr(tag, '@');
  if (revchr != NULL)
    {
    revision.kind = svn_opt_revision_number;
    revision.value.number = apr_atoi64(revchr + 1);
    tag = apr_pstrndup(pool, tag, revchr - tag);
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
    url = apr_pstrcat(pool, url, "/tags/", tag);
    }

  apr_finfo_t finfo;
  apr_status_t statcode;
  statcode = apr_stat(&finfo, path /*TODO: ".svn"*/, APR_FINFO_TYPE, pool);
  if (statcode != APR_SUCCESS)
    {
    char buffer[256];
    puts(apr_strerror(statcode, buffer, sizeof(buffer)));
    return;
    }
  if (finfo.filetype == APR_NOFILE)
    {
    svnerr = svn_client_checkout3(
        &result_rev,
        url,
        path,
        &peg_revision,
        &revision,
        svn_depth_infinity,
        TRUE,  // ignore_externals
        FALSE, // allow_unver_obstructions
        ctx,
        pool);
    if (svnerr)
      {
//    char buffer[256];
//    k_error_set(kerror, svn_err_best_message(error, buffer, sizeof(buffer)));
      puts(svnerr->message);
      return;
      }
    return;
    }
  struct InfoBaton info_baton = {url, revision.value.number, FALSE, FALSE};
  svnerr = svn_client_info2(
      path,
      NULL,  // peg_revision
      NULL,  // revision
      info_receiver,
      &info_baton,
      svn_depth_empty,
      NULL,  // changelists
      ctx,
      pool);
  if (svnerr)
    {
    puts(svnerr->message);
    return;
    }
  if (!info_baton.url_ok)
    {
    svnerr = svn_client_switch2(
        &result_rev,
        path,
        url,
        &peg_revision,
        &revision,
        svn_depth_infinity,
        TRUE,  // depth_is_sticky,
        TRUE,  // ignore_externals
        FALSE, // allow_unver_obstructions
        ctx,
        pool);
    if (svnerr)
      {
      puts(svnerr->message);
      return;
      }
    }
  else if(revision.kind == svn_opt_revision_number && !info_baton.rev_ok)
    {
    apr_array_header_t *paths = apr_array_make(pool, 1, sizeof(const char*));
    apr_array_header_t *result_revs;
    APR_ARRAY_PUSH(paths, const char*) = path;
    svnerr = svn_client_update3(
        &result_revs,
        paths,
        &revision,
        svn_depth_infinity,
        TRUE,  // depth_is_sticky,
        TRUE,  // ignore_externals
        FALSE, // allow_unver_obstructions
        ctx,
        pool);
    if (svnerr)
      {
      puts(svnerr->message);
      return;
      }
    }
  }

static void subversion_finalize(GObject* obj)
  {
  Subversion *self;
  self = G_TYPE_CHECK_INSTANCE_CAST(obj, TYPE_SUBVERSION, Subversion);
  G_OBJECT_CLASS(subversion_parent_class)->finalize(obj);
  }

static void subversion_class_init(SubversionClass *klass)
  {
  subversion_parent_class = g_type_class_peek_parent(klass);
  g_type_class_add_private(klass, sizeof(SubversionPrivate));
  G_OBJECT_CLASS(klass)->finalize = subversion_finalize;
  }

static void subversion_driver_interface_init(DriverIface *iface)
  {
  subversion_driver_parent_iface = g_type_interface_peek_parent(iface);
  iface->name = subversion_name;
  iface->fields = subversion_fields;
  iface->filter = subversion_filter;
  iface->download = subversion_download;
  }

static void subversion_instance_init(Subversion * self)
  {
  self->priv = SUBVERSION_GET_PRIVATE (self);
  }

GType subversion_get_type(void)
  {
  static volatile gsize subversion_type_id__volatile = 0;
  if (g_once_init_enter(&subversion_type_id__volatile))
    {
    static const GTypeInfo g_define_type_info =
      {
      sizeof(SubversionClass),
      (GBaseInitFunc) NULL,
      (GBaseFinalizeFunc) NULL,
      (GClassInitFunc) subversion_class_init,
      (GClassFinalizeFunc) NULL,
      NULL,
      sizeof(Subversion),
      0,
      (GInstanceInitFunc) subversion_instance_init,
      NULL
      };
    static const GInterfaceInfo driver_info =
      {
      (GInterfaceInitFunc) subversion_driver_interface_init,
      (GInterfaceFinalizeFunc) NULL,
      NULL
      };
    GType subversion_type_id;
    subversion_type_id = g_type_register_static(
      G_TYPE_OBJECT,
      "Subversion",
      &g_define_type_info,
      0);
    g_type_add_interface_static(subversion_type_id, TYPE_DRIVER, &driver_info);
    g_once_init_leave(&subversion_type_id__volatile, subversion_type_id);
    }
  return subversion_type_id__volatile;
  }
