module System = Sys
open Core
open Aeron_ocaml
open Shapeshifter

let offer_loop publication =
  let is_running = ref true in
  let terminate _ = is_running := false in
  System.set_signal System.sigint (System.Signal_handle terminate) ;
  let buffer = Unsafe_buffer.acquire ~byte_length:64l in
  Unsafe_buffer.set_i32 ~offset:0l ~value:42l buffer ;
  Unsafe_buffer.set_i32 ~offset:4l ~value:43l buffer ;
  Unsafe_buffer.set_i32 ~offset:8l ~value:44l buffer ;
  let rec offer_loop_aux () =
    let module Publication = Aeron_client.Publication in
    if !is_running then (
      let result =
        Publication.offer ~buffer ~offset:0 ~length:12 publication
      in
      (* TODO call idle strategy here *)
      ignore result ; offer_loop_aux () )
    else ()
  in
  offer_loop_aux () ;
  Unsafe_buffer.release buffer

let run_publisher () =
  let open Result.Let_syntax in
  let module Context = Aeron_client.Context in
  let ctx =
    Context.default |> Context.with_aeron_dir "/dev/shm/example-driver"
  in
  let%bind client = Aeron_client.start ctx in
  let%map publication =
    Aeron_client.add_exclusive_publication
    (* ~channel_uri:"aeron:udp?endpoint=localhost:20121" *)
      ~channel_uri:"aeron:ipc" ~stream_id:1001 client
  in
  offer_loop publication ; Aeron_client.close client

let () =
  match run_publisher () with
  | Ok _ -> ()
  | Error msg -> print_endline ("Error: " ^ msg)
