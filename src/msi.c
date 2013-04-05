/*
 * Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt
 */

#include "lemonade.h"

#ifdef G_OS_WIN32

#include <windows.h>
#include <msi.h>

#define TYPE_MSI_DRIVER (msi_driver_get_type ())
#define MSI_DRIVER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_MSI_DRIVER, MsiDriver))
#define MSI_DRIVER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_MSI_DRIVER, MsiDriverClass))
#define IS_MSI_DRIVER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_MSI_DRIVER))
#define IS_MSI_DRIVER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_MSI_DRIVER))
#define MSI_DRIVER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_MSI_DRIVER, MsiDriverClass))

typedef struct _MsiDriver MsiDriver;
typedef struct _MsiDriverClass MsiDriverClass;
typedef struct _MsiDriverPrivate MsiDriverPrivate;

struct _MsiDriver
  {
  GObject parent_instance;
  MsiDriverPrivate * priv;
  };

struct _MsiDriverClass
  {
  GObjectClass parent_class;
  };

static gpointer msi_driver_parent_class = NULL;
static DriverIface* msi_driver_driver_parent_iface = NULL;

GType msi_driver_get_type(void) G_GNUC_CONST;

static INT CALLBACK msi_handle_ui(LPVOID self, UINT type, LPCTSTR message)
  {
  return 0;
  }

MsiDriver* msi_driver_construct(GType object_type, GError** error)
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
  MsiDriver *self = (MsiDriver*) g_object_new(object_type, NULL);
  MsiSetExternalUI(msi_handle_ui, msg_filter, self);
  MsiSetInternalUI(INSTALLUILEVEL_NONE | INSTALLUILEVEL_SOURCERESONLY, NULL);
  return self;
  }

MsiDriver* msi_driver_new(GError** error)
  {
  return msi_driver_construct(TYPE_MSI_DRIVER, error);
  }

static const gchar* msi_driver_name(Driver* base)
  {
  return "msi";
  }

static gchar** msi_driver_fields(Driver* base, int* result_length)
  {
  static const gchar* fields[] =
    {
    "product", NULL,
    "feature", "",
    "href", ""
    };
  if (result_length)
    {
    *result_length = G_N_ELEMENTS(fields);
    }
  return (gchar**) fields;
  }

static void msi_driver_filter(
    Driver* base,
    const KDictionary* fields,
    KAddFun add_fun,
    void* add_fun_target)
  {
  MsiDriver *self = (MsiDriver*) base;
  g_return_if_fail(fields != NULL);

  LPCTSTR product = k_dictionary_lookup(fields, "product");
  LPCTSTR feature = k_dictionary_lookup(fields, "feature");
  LPCTSTR href = k_dictionary_lookup(fields, "href");

  INSTALLSTATE state;
  state = MsiQueryProductState(product);
  state = MsiQueryFeatureState(product, feature);

  DWORD length = 0;
  UINT ret = MsiGetProductInfo(
      product,
      INSTALLPROPERTY_VERSIONSTRING,
      NULL,
      &length);

  ret = MsiGetProductInfo(
      product,
      INSTALLPROPERTY_INSTALLLOCATION,
      NULL,
      &length);
  }

static void msi_driver_download(
    Driver* base,
    const KImplementation* impl,
    gboolean requested,
    GError** error)
  {
  MsiDriver * self = (MsiDriver*) base;
  g_return_if_fail(impl != NULL);

  KDictionary const *values = k_implementation_get_values(impl);
  LPCTSTR href = k_dictionary_lookup(values, "href");

  UINT ret = MsiInstallProduct(href, "ADDLOCAL=ALL");
  }

static void msi_driver_class_init(MsiDriverClass * klass)
  {
  msi_driver_parent_class = g_type_class_peek_parent(klass);
  }

static void msi_driver_driver_interface_init(DriverIface * iface)
  {
  msi_driver_driver_parent_iface = g_type_interface_peek_parent(iface);
  iface->name = msi_driver_name;
  iface->fields = msi_driver_fields;
  iface->filter = msi_driver_filter;
  iface->download = msi_driver_download;
  }

static void msi_driver_instance_init(MsiDriver * self)
  {
  }

GType msi_driver_get_type(void)
  {
  static volatile gsize msi_driver_type_id__volatile = 0;
  if (g_once_init_enter(&msi_driver_type_id__volatile))
    {
    static const GTypeInfo g_define_type_info =
      {
      sizeof(MsiDriverClass),
      (GBaseInitFunc) NULL,
      (GBaseFinalizeFunc) NULL,
      (GClassInitFunc) msi_driver_class_init,
      (GClassFinalizeFunc) NULL,
      NULL,
      sizeof(MsiDriver),
      0,
      (GInstanceInitFunc) msi_driver_instance_init,
      NULL
      };
    static const GInterfaceInfo driver_info =
      {
      (GInterfaceInitFunc) msi_driver_driver_interface_init,
      (GInterfaceFinalizeFunc) NULL,
      NULL
      };
    GType msi_driver_type_id;
    msi_driver_type_id = g_type_register_static(
      G_TYPE_OBJECT,
      "MsiDriver",
      &g_define_type_info,
      0);
    g_type_add_interface_static(msi_driver_type_id, TYPE_DRIVER, &driver_info);
    g_once_init_leave(&msi_driver_type_id__volatile, msi_driver_type_id);
    }
  return msi_driver_type_id__volatile;
  }

#endif
