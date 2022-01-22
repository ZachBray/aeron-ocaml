open Base
open Shapeshifter

(** An Aeron client. Users must call [close] once finished with the client. *)
type t

(** {2 Configuration} *)

module Context : sig
  (** Configuration for an Aeron client *)
  type t

  val default : t
  (** The default configuration for an Aeron client. *)

  val with_aeron_dir : string -> t -> t
  (** Returns the same configuration but with the specified media driver
      directory. *)
end

(** {2 Lifecycle} *)

val start : Context.t -> (t, string) Result.t
(** Starts an Aeron client with the specified configuration [Context.t]. *)

val close : t -> unit
(** Closes an Aeron client and frees its resources, e.g., its conductor
    thread. Users must not perform any further operations on the client [t]. *)

val idle : work_count:int -> t -> unit
(** Waits for an operation to complete. *)

(** {2 Publishing} *)

module Publication : sig
  type t

  module Code : sig
    (** Represents whether a message was successfully written to the
        publication via [Publication.offer]. *)
    type t

    val was_successful : t -> bool
    (** Returns true if the code represents a successful write to the
        publication. *)
  end

  val close : t -> unit
  (** Closes the publication. Users must not perform any further operations
      on the publication after calling this method. *)

  val offer :
    buffer:Unsafe_buffer.t -> offset:int -> length:int -> t -> Code.t
  (** Attempts to publish a message encoded within the [buffer] at the
      supplied [offset] and with the given [length] in bytes. *)
end

val add_exclusive_publication :
     channel_uri:string
  -> stream_id:int
  -> t
  -> (Publication.t, string) Result.t
(** Creates a new exclusive (i.e., single-threaded) publication for
    transmission of messages. Users should call [Publication.close] once
    finished using the publication. *)

(** {2 Subscribing} *)

type fragment_handler = Unsafe_buffer.t -> int -> unit

module Subscription : sig
  type t

  val poll : fragment_limit:int -> fragment_handler -> t -> int
  (** Poll for new messages in a stream. If new messages are found beyond the
      last consumed position then they will be delivered to the handler up to
      a limited number of fragments as specified. Returns the number of
      fragments read. *)

  val close : t -> unit
  (** Closes the subscription. Users must not perform any further operations
      on the subscription after calling this method. *)
end

val add_subscription :
     channel_uri:string
  -> stream_id:int
  -> t
  -> (Subscription.t, string) Result.t
(** Creates a new subscription for the reception of messages. Users should
    call [Subscription.close] once finished using the subscription. *)
