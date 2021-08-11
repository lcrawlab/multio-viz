import pandas as pd
import networkx as nx
import numpy as np
import itertools
import plotly.offline as py
import plotly.graph_objects as go

# create sheet 1 from sheet 2
data1 = pd.read_csv('/Users/helen/Downloads/nodes2b.csv')
data2 = []

prev_id = None
length = len(data1.index)
d2_row = -1

for i in range(length):
  cur_id = data1.iloc[i][1]
  cur_cpg = data1.iloc[i][0]
  cur_pip = data1.iloc[i][2]
  # if i = 0 or if cur_id =/ prev_id or --> make new row \ else change existing row
  if i == 0 or cur_id != prev_id:
    data2.append([cur_id, cur_pip, cur_cpg])
    d2_row += 1
  else:
    data2[d2_row][2] = data2[d2_row][2] + ", " + cur_cpg
  prev_id = cur_id

nodes = pd.DataFrame(data2)
nodes.columns = ['id', 'pip', 'cpg']

# creating edgelist from node data
nodeids = nodes['id'].tolist()

rownumber = 0
length = len(nodeids)
iterations_float = length*(length-1)/2
iterations = int(iterations_float)

edgelist = []
for i in range(iterations):
  edgelist.append([None, None])

for i in range(length-1):
  val = nodeids[i]
  for j in range(length-i-1):
    val2 = nodeids[j+i]
    edgelist[rownumber][0] = val
    edgelist[rownumber][1] = val2
    rownumber = rownumber + 1
edges = pd.DataFrame(edgelist, columns = ['from', 'to'])

# create graph
H = nx.from_pandas_edgelist(edges, 'from', 'to')

# setting node attributes
nx.set_node_attributes(H, nodes.set_index('id')['cpg'].to_dict(), 'cpg')
nx.set_node_attributes(H, nodes.set_index('id')['pip'].to_dict(), 'pip')

# filter nodes by pip score threshold and create subgraph
selected_nodes = [n for n,v in H.nodes(data=True) if v['pip'] >= 0.55]
G = H.subgraph(selected_nodes)

# setting node attributes
nx.set_node_attributes(G, nodes.set_index('id')['cpg'].to_dict(), 'cpg')
nx.set_node_attributes(G, nodes.set_index('id')['pip'].to_dict(), 'pip')

# set node positions and graph layout
pos = nx.spring_layout(G)
for node in G.nodes:
    G.nodes[node]['pos'] = list(pos[node])

# add edge trace
edge_x = []
edge_y = []
for edge in G.edges():
    x0, y0 = G.nodes[edge[0]]['pos']
    x1, y1 = G.nodes[edge[1]]['pos']
    edge_x.append(x0)
    edge_x.append(x1)
    edge_x.append(None)
    edge_y.append(y0)
    edge_y.append(y1)
    edge_y.append(None)

edge_trace = go.Scatter(
    x=edge_x, y=edge_y,
    line=dict(width=0.5, color='#888'),
    hoverinfo='none',
    mode='lines')

# add node trace
node_x = []
node_y = []
hover = []
size = []
for node in G.nodes():
    x, y = G.nodes[node]['pos']
    hovertext = "CpG Sites: " + str(G.nodes[node]['cpg'])
    s = float(G.nodes[node]['pip'])
    node_x.append(x)
    node_y.append(y)
    hover.append(hovertext)
    size.append(s)

size_scaled = [element * 1000000 for element in size]

node_trace = go.Scatter(
    x=node_x, y=node_y,
    hovertext = hover,
    mode='markers+text',
    textposition="bottom center",
    hoverinfo='text',
    marker=dict(
        showscale=True,
        colorscale='YlGnBu',
        color=[],
        size=[],
        colorbar=dict(
            thickness=15,
            title='Pip Score',
            xanchor='left',
            titleside='right'),
        ))

# set text as node id
index = 0
node_text = []
for node in G.nodes():
    node_text.append(nodes['id'][index])
    index = index + 1
node_trace.text = node_text

# color node by pip score
i = 0
col = []
for node in G.nodes():
  col.append(nodes['pip'][i])
  i = i + 1
node_trace['marker']['color'] = col

# size node by pip score
j = 0
size = []
for node in G.nodes():
  size.append(nodes['pip'][j])
  j = j + 1
size_scaled = [n * 50 for n in size]
node_trace['marker']['size'] = size_scaled

fig = go.Figure(data=[edge_trace, node_trace], layout = go.Layout(title='An interactive app for multi-omics gene regulatory network visualization', showlegend=False, hovermode='closest',
                        margin={'b': 40, 'l': 40, 'r': 40, 't': 40},
                        xaxis={'showgrid': False, 'zeroline': False, 'showticklabels': False},
                        yaxis={'showgrid': False, 'zeroline': False, 'showticklabels': False},
                        height=600,
                        clickmode='event+select'))

# create dash layout components
import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.express as px
import pandas as pd

external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']

app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

app.layout = html.Div(children=[
    html.H1(children='Multioviz'),

    dcc.Graph(
        id='plotly',
        figure=fig
    )
])

if __name__ == '__main__':
    app.run_server(debug=True)
    
