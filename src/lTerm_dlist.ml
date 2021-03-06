(* OCaml promise library
 * http://www.ocsigen.org/lwt
 * Copyright (C) 2009 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

type 'a t = {
  mutable prev : 'a t;
  mutable next : 'a t;
}

type 'a node = {
  mutable node_prev : 'a t;
  mutable node_next : 'a t;
  mutable node_data : 'a;
  mutable node_active : bool;
}

external seq_of_node : 'a node -> 'a t = "%identity"
external node_of_seq : 'a t -> 'a node = "%identity"

(* +-----------------------------------------------------------------+
   | Operations on nodes                                             |
   +-----------------------------------------------------------------+ *)

let remove node =
  if node.node_active then begin
    node.node_active <- false;
    let seq = seq_of_node node in
    seq.prev.next <- seq.next;
    seq.next.prev <- seq.prev
  end

(* +-----------------------------------------------------------------+
   | Operations on sequences                                         |
   +-----------------------------------------------------------------+ *)

let create () =
  let rec seq = { prev = seq; next = seq } in
  seq

let add_l data seq =
  let node = { node_prev = seq; node_next = seq.next; node_data = data; node_active = true } in
  seq.next.prev <- seq_of_node node;
  seq.next <- seq_of_node node;
  node

let iter_l f seq =
  let rec loop curr =
    if curr != seq then begin
      let node = node_of_seq curr in
      if node.node_active then f node.node_data;
      loop node.node_next
    end
  in
  loop seq.next

let fold_l f seq acc =
  let rec loop curr acc =
    if curr == seq then
      acc
    else
      let node = node_of_seq curr in
      if node.node_active then
        loop node.node_next (f node.node_data acc)
      else
        loop node.node_next acc
  in
  loop seq.next acc
