#include "caml/config.h"
#include "caml/mlvalues.h"
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/types.h>
#define CAML_NAME_SPACE
#include "caml/alloc.h"
#include "caml/misc.h"
#include "caml/memory.h"
#include "caml/callback.h"
#include "aeron/aeron-client/src/main/c/aeronc.h"

inline void* as_ptr(value v) {
  return (void *) (v & ~1);
}

inline value as_value(void *p) {
  assert (((uintptr_t) p & 1) == 0);  // check correct alignment
  return (value) p | 1;
}

#define CAMLreturn_result_error() {                \
    const char *error_msg = aeron_errmsg();        \
    CAMLlocal1(ocaml_error_msg);                   \
    ocaml_error_msg = caml_copy_string(error_msg); \
    CAMLlocal1(error);                             \
    error = caml_alloc(1, 1);                      \
    Store_field(error, 0, ocaml_error_msg);        \
    CAMLreturn(error);                             \
}

#define CAMLreturn_result_ok(VALUE) { \
  CAMLlocal1(ok);                     \
  ok = caml_alloc(1, 0);              \
  Store_field(ok, 0, VALUE);          \
  CAMLreturn(ok);                     \
}

CAMLprim value aeron_ocaml_context_init_byte() {
  CAMLparam0();
  aeron_context_t *context = NULL; 

  if (aeron_context_init(&context) < 0) {
    CAMLreturn_result_error();
  }

  CAMLlocal1(context_as_value);
  context_as_value = as_value(context);
  CAMLreturn_result_ok(context_as_value);
}

CAMLprim void aeron_ocaml_context_close_byte(value ctx) {
  CAMLparam1(ctx);
  aeron_context_t *context = (aeron_context_t*) as_ptr(ctx);
  aeron_context_close(context);
  CAMLreturn0;
}

CAMLprim value aeron_ocaml_context_set_dir_byte(value ctx, value dir_name) {
  CAMLparam2(ctx, dir_name);
  aeron_context_t *context = (aeron_context_t*) as_ptr(ctx);
  const char *dir_name_on_c_heap = String_val(dir_name);
  
  if (aeron_context_set_dir(context, dir_name_on_c_heap) < 0) {
    CAMLreturn_result_error();
  }

  CAMLreturn_result_ok(Val_unit);
}

CAMLprim value aeron_ocaml_client_init_byte(value ctx) {
  CAMLparam1(ctx);
  aeron_context_t *context = (aeron_context_t*) as_ptr(ctx);
  aeron_t *client = NULL;

  if (aeron_init(&client, context) < 0) {
    CAMLreturn_result_error();
  }

  CAMLlocal1(client_as_value);
  client_as_value = as_value(client);
  CAMLreturn_result_ok(client_as_value);
}

CAMLprim value aeron_ocaml_client_start_byte(value c) {
  CAMLparam1(c);
  aeron_t *client = (aeron_t*) as_ptr(c);

  if (aeron_start(client) < 0) {
    CAMLreturn_result_error();
  }

  CAMLreturn_result_ok(Val_unit);
}

CAMLprim void aeron_ocaml_client_idle(value c, intnat work_count) {
  aeron_t *client = (aeron_t*) as_ptr(c);
  aeron_main_idle_strategy(client, work_count);
}

CAMLprim void aeron_ocaml_client_idle_byte(value c, value work_count) {
  CAMLparam2(c, work_count);
  aeron_ocaml_client_idle(c, Int_val(work_count));
  CAMLreturn0;
}

CAMLprim void aeron_ocaml_client_close_byte(value c) {
  CAMLparam1(c);
  aeron_t *client = (aeron_t*) as_ptr(c);
  aeron_close(client);
  CAMLreturn0;
}

CAMLprim value aeron_ocaml_client_add_exclusive_publication_byte(value c, value channel_uri, value stream_id) {
  CAMLparam3(c, channel_uri, stream_id);
  aeron_t *client = (aeron_t*) as_ptr(c);

  const char *channel_uri_on_c_heap = String_val(channel_uri);
  intnat stream_id_c = Int_val(stream_id);

  aeron_async_add_exclusive_publication_t *async;
  if (aeron_async_add_exclusive_publication(&async, client, channel_uri_on_c_heap, stream_id_c) < 0) {
    CAMLreturn_result_error();
  }

  aeron_exclusive_publication_t *publication = NULL;

  while (NULL == publication) {
    if (aeron_async_add_exclusive_publication_poll(&publication, async) < 0) {
      CAMLreturn_result_error();
    }

    if (NULL == publication) {
      aeron_main_idle_strategy(client, 0);
    }
  }

  CAMLlocal1(publication_as_value);
  publication_as_value = as_value(publication);
  CAMLreturn_result_ok(publication_as_value);
}

CAMLprim intnat aeron_ocaml_exclusive_publication_offer(value p, value b, intnat offset, intnat length) {
  aeron_exclusive_publication_t *publication = (aeron_exclusive_publication_t*) as_ptr(p);
  const uint8_t *buffer = (const uint8_t *) (as_ptr(b) + offset);
  return aeron_exclusive_publication_offer(publication, buffer, length, NULL, NULL);
}

CAMLprim value aeron_ocaml_exclusive_publication_offer_byte(value p, value b, value offset, value length) {
  CAMLparam4(p, b, offset, length);
  CAMLlocal1(result_code);
  result_code = Val_long(aeron_ocaml_exclusive_publication_offer(p, b, offset, length));
  CAMLreturn(result_code);
}

CAMLprim void aeron_ocaml_exclusive_publication_close_byte(value p) {
  CAMLparam1(p);
  aeron_exclusive_publication_t *publication = (aeron_exclusive_publication_t*) as_ptr(p);
  aeron_exclusive_publication_close(publication, NULL, NULL);
  CAMLreturn0;
}

CAMLprim value aeron_ocaml_client_add_subscription_byte(value c, value channel_uri, value stream_id) {
  CAMLparam3(c, channel_uri, stream_id);
  aeron_t *client = (aeron_t*) as_ptr(c);

  const char *channel_uri_on_c_heap = String_val(channel_uri);
  intnat stream_id_c = Int_val(stream_id);

  aeron_async_add_subscription_t *async;
  if (aeron_async_add_subscription(&async, client, channel_uri_on_c_heap, stream_id_c, NULL, NULL, NULL, NULL) < 0) {
    CAMLreturn_result_error();
  }

  aeron_subscription_t *subscription = NULL;

  while (NULL == subscription) {
    if (aeron_async_add_subscription_poll(&subscription, async) < 0) {
      CAMLreturn_result_error();
    }

    if (NULL == subscription) {
      aeron_main_idle_strategy(client, 0);
    }
  }

  CAMLlocal1(subscription_as_value);
  subscription_as_value = as_value(subscription);
  CAMLreturn_result_ok(subscription_as_value);
}

CAMLprim intnat aeron_ocaml_header_position(value header_value) {
  aeron_header_t *header = (aeron_header_t *) as_ptr(header_value);
  return aeron_header_position(header);
}

CAMLprim value aeron_ocaml_header_position_byte(value header_value) {
  return Val_int(aeron_ocaml_header_position(header_value));
}

void on_fragment_polled(void *clientd, const uint8_t *buffer, size_t length, aeron_header_t *header) {
  value fragment_handler = (value) clientd;
  // TODO how should we deal with exceptions here? The [@noalloc] annotation means we cannot throw.
  caml_callback3(fragment_handler, as_value((void *) buffer), Val_int(length), as_value((void *) header));
}

CAMLprim value aeron_ocaml_subscription_poll_byte(value p, value fragment_limit, value fragment_handler) {
  CAMLparam3(p, fragment_limit, fragment_handler);
  CAMLlocal1(result_code);
  aeron_subscription_t *subscription = (aeron_subscription_t*) as_ptr(p);
  int poll_result = aeron_subscription_poll(subscription, on_fragment_polled, (void *) fragment_handler, fragment_limit);
  result_code = Val_int(poll_result);
  CAMLreturn(result_code);
}

CAMLprim void aeron_ocaml_subscription_close_byte(value p) {
  CAMLparam1(p);
  aeron_subscription_t *publication = (aeron_subscription_t*) as_ptr(p);
  aeron_subscription_close(publication, NULL, NULL);
  CAMLreturn0;
}
