Module:    graphviz-renderer
Synopsis:  We want to see graphs
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define sealed class <graph> (<object>)
  constant slot nodes :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot edges :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot attributes :: <string-table> = make(<string-table>);
end;

define sealed class <node> (<object>)
  constant slot graph, required-init-keyword: graph:;
  constant slot label :: <string> = "", init-keyword: label:;
  constant slot outgoing-edges :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot incoming-edges :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot attributes :: <string-table> = make(<string-table>);
  constant slot id :: <integer>, required-init-keyword: id:;
end;

define sealed class <edge> (<object>)
  constant slot graph, required-init-keyword: graph:;
  constant slot label :: <string> = "", init-keyword: label:;
  constant slot source :: <node>, required-init-keyword: source:;
  constant slot target :: <node>, required-init-keyword: target:;
  constant slot attributes :: <string-table> = make(<string-table>);
end;

define function create-node (graph :: <graph>, #key label)
 => (node :: <node>)
  let node = make(<node>,
                  graph: graph,
                  label: label | integer-to-string(graph.nodes.size),
                  id: graph.nodes.size);
  add!(graph.nodes, node);
  node
end;

define function create-edge
 (graph :: <graph>, source :: <node>, target :: <node>, #key label)
 => (edge :: <edge>);
  let edge = make(<edge>,
                  graph: graph,
                  source: source,
                  target: target,
                  label: label | integer-to-string(graph.edges.size));
  if (label)
    edge.attributes["label"] := label;
  end;
  add!(graph.edges, edge);
  add!(source.outgoing-edges, edge);
  add!(target.incoming-edges, edge);
  edge
end;

define function maybe-create-nodes (graph :: <graph>, pres :: <collection>)
 => (res :: <collection>)
  let all = graph.nodes;
  let nodes-to-connect = choose-by(rcurry(member?, pres, test: \=),
                                   map(label, all),
                                   all);
  let missing-nodes = choose(complement(curry(find-node, graph)), pres);
  let new-nodes = map(curry(create-node, graph, label:), missing-nodes);
  concatenate(new-nodes, nodes-to-connect);
end;

define function find-node (graph :: <graph>, name :: <string>)
 => (res :: false-or(<node>))
  let res = choose(compose(curry(\=, name), label), graph.nodes);
  if (res & res.size = 1)
    res[0];
  end;
end;

define function find-node! (graph :: <graph>, name :: <string>) => (res :: <node>)
  find-node(graph, name) | create-node(graph, label: name)
end;

define function add-successors (node :: <node>, pres :: <collection>) => ()
  let nodes-to-connect = maybe-create-nodes(node.graph, pres);
  map(curry(create-edge, node.graph, node), nodes-to-connect);
end;

define function add-predecessors (node :: <node>, succs :: <collection>) => ()
  let nodes-to-connect = maybe-create-nodes(node.graph, succs);
  map(rcurry(curry(create-edge, node.graph), node), nodes-to-connect);
end;

define function adjacent-edges (node :: <node>)
 => (edges :: <collection>);
  concatenate(node.incoming-edges, node.outgoing-edges)
end;

define function remove-edge (graph :: <graph>,
                           edge :: <edge>)
  remove!(edge.source.outgoing-edges, edge);
  remove!(edge.target.incoming-edges, edge);
  remove!(graph.edges, edge);
end;

define function predecessors (node :: <node>)
 => (predecessors :: <collection>);
  map(source, node.incoming-edges)
end;

define function successors (node :: <node>)
 => (predecessors :: <collection>);
  map(target, node.outgoing-edges)
end;

define function neighbours (node :: <node>)
 => (predecessors :: <collection>);
  concatenate(node.predecessors, node.successors)
end;
