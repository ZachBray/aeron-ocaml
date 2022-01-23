module System = Sys
open Core
open Aeron_ocaml
open Shapeshifter

let fragment_handler buffer length header =
  let module H = Aeron_client.Header in
  let expected_message =
    length = 12
    && Unsafe_buffer.get_i32 ~offset:0 buffer = 42
    && Unsafe_buffer.get_i32 ~offset:4 buffer = 43
    && Unsafe_buffer.get_i32 ~offset:8 buffer = 44
  in
  if not expected_message then
    print_endline
      ( "Unexpected message. length=" ^ Int.to_string length ^ ", position="
      ^ Int.to_string (H.position header) )
  else ()

let consume_loop subscription =
  let is_running = ref true in
  let terminate _ = is_running := false in
  System.set_signal System.sigint (System.Signal_handle terminate) ;
  let rec consume_loop_aux () =
    let module S = Aeron_client.Subscription in
    if !is_running then (
      let result = S.poll ~fragment_limit:1 fragment_handler subscription in
      (* TODO call idle strategy here *)
      ignore result ; consume_loop_aux () )
    else ()
  in
  consume_loop_aux ()

let run_subscriber () =
  let open Result.Let_syntax in
  let module Context = Aeron_client.Context in
  let ctx =
    Context.default |> Context.with_aeron_dir "/dev/shm/example-driver"
  in
  let%bind client = Aeron_client.start ctx in
  let%map subscription =
    Aeron_client.add_subscription
    (* ~channel_uri:"aeron:udp?endpoint=localhost:20121" *)
      ~channel_uri:"aeron:ipc" ~stream_id:1001 client
  in
  consume_loop subscription ; Aeron_client.close client

let () =
  match run_subscriber () with
  | Ok _ -> ()
  | Error msg -> print_endline ("Error: " ^ msg)
