open Base
open Shapeshifter

type context

type t

external ctx_init : unit -> (context, string) Result.t
  = "aeron_ocaml_context_init_byte"

external ctx_close : context -> unit = "aeron_ocaml_context_close_byte"

external ctx_set_dir : context -> string -> (unit, string) Result.t
  = "aeron_ocaml_context_set_dir_byte"

external client_init : context -> (t, string) Result.t
  = "aeron_ocaml_client_init_byte"

external client_start : t -> (unit, string) Result.t
  = "aeron_ocaml_client_start_byte"

external client_idle : (int[@untagged]) -> t -> unit
  = "aeron_ocaml_client_idle_byte" "aeron_ocaml_client_idle"
  [@@noalloc]

external client_close : t -> unit = "aeron_ocaml_client_close_byte"

module Context = struct
  type t = {aeron_dir: string option; rest: unit}

  let default = {aeron_dir= None; rest= ()}

  let with_aeron_dir name s = {s with aeron_dir= Some name}
end

let ( >>+ ) (m, clean_up) f =
  let open Result.Let_syntax in
  let%bind a = m in
  let fa = f a in
  Result.iter_error ~f:(fun _ -> clean_up a) fa ;
  fa

let start {Context.aeron_dir; _} =
  let open Result.Monad_infix in
  (ctx_init (), ctx_close)
  >>+ fun ctx ->
  Option.fold aeron_dir ~init:(Ok ()) ~f:(fun _ aeron_dir ->
      ctx_set_dir ctx aeron_dir )
  >>= fun () ->
  (client_init ctx, client_close)
  >>+ fun client -> client_start client >>| fun () -> client

let close = client_close

module Publication = struct
  module Code = struct
    type t = int

    let was_successful code = code > 0
  end

  type t

  external exclusive_publication_offer :
       t
    -> Unsafe_buffer.t
    -> (int[@untagged])
    -> (int[@untagged])
    -> (int[@untagged])
    = "aeron_ocaml_exclusive_publication_offer_byte" "aeron_ocaml_exclusive_publication_offer"
    [@@noalloc]

  external exclusive_publication_close : t -> unit
    = "aeron_ocaml_exclusive_publication_close_byte"

  let offer ~buffer ~offset ~length publication =
    exclusive_publication_offer publication buffer offset length

  let close = exclusive_publication_close
end

external client_add_exclusive_publication :
  t -> string -> int -> (Publication.t, string) Result.t
  = "aeron_ocaml_client_add_exclusive_publication_byte"

let add_exclusive_publication ~channel_uri ~stream_id client =
  client_add_exclusive_publication client channel_uri stream_id

let idle ~work_count client = client_idle work_count client

module Header = struct
  type t

  external position : t -> (int[@untagged])
    = "aeron_ocaml_header_position_byte" "aeron_ocaml_header_position"
    [@@noalloc]
end

type fragment_handler = Unsafe_buffer.t -> int -> Header.t -> unit

module Subscription = struct
  type t

  external subscription_poll : t -> int -> fragment_handler -> int
    = "aeron_ocaml_subscription_poll_byte"

  let poll ~fragment_limit fragment_handler subscription =
    subscription_poll subscription fragment_limit fragment_handler

  external close : t -> unit = "aeron_ocaml_subscription_close_byte"
end

external client_add_subscription :
  t -> string -> int -> (Subscription.t, string) Result.t
  = "aeron_ocaml_client_add_subscription_byte"

let add_subscription ~channel_uri ~stream_id client =
  client_add_subscription client channel_uri stream_id
