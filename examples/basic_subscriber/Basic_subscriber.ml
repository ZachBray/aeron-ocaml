module System = Sys
open Core
open Aeron_ocaml
open Shapeshifter

let consume_loop subscription =
  let is_running = ref true in
  let terminate _ = is_running := false in
  System.set_signal System.sigint (System.Signal_handle terminate) ;
  let fragment_handler buffer length =
    let expected_message =
      length = 12
      &&
      let open Int32 in
      Unsafe_buffer.get_i32 ~offset:0l buffer = 42l
      && Unsafe_buffer.get_i32 ~offset:4l buffer = 43l
      && Unsafe_buffer.get_i32 ~offset:8l buffer = 44l
    in
    if not expected_message then
      print_endline ("Unexpected message. length=" ^ Int.to_string length)
    else ()
  in
  let rec consume_loop_aux () =
    let module S = Aeron_client.Subscription in
    if !is_running then (
      let result =
        S.poll ~fragment_limit:10 fragment_handler subscription
      in
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
