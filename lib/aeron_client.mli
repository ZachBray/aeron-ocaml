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

val idle : work_count:int32 -> t -> unit
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
      on the publication. *)

  val offer :
    buffer:Unsafe_buffer.t -> offset:int32 -> length:int32 -> t -> Code.t
  (** Attempts to publish a message encoded within the [buffer] at the
      supplied [offset] and with the given [length] in bytes. *)
end

val add_exclusive_publication :
     channel_uri:string
  -> stream_id:int32
  -> t
  -> (Publication.t, string) Result.t
(** Creates a new exclusive (i.e., single-threaded) publication for
    transmission of messages. Users should call [Publication.close] once
    finished using the publication. *)
