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
  cur_cpg = data1.iloc[i][0]
  cur_cpg_pip = data1.iloc[i][1]
  cur_id = data1.iloc[i][2]
  cur_pip = data1.iloc[i][3]

  # if i = 0 or if cur_id =/ prev_id or --> make new row \ else change existing row
  if i == 0 or cur_id != prev_id:
    data2.append([cur_id, cur_pip, cur_cpg, cur_cpg_pip])
    d2_row += 1
  else:
    data2[d2_row][2] = data2[d2_row][2] + ", " + cur_cpg
    data2[d2_row][3] = str(data2[d2_row][3]) + ", " + str(cur_cpg_pip)
  prev_id = cur_id

nodes = pd.DataFrame(data2)
nodes.columns = ['id', 'pip', 'cpg', 'cpg_pip']

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
nx.set_node_attributes(H, nodes.set_index('id')['cpg_pip'].to_dict(), 'cpg_pip')

# set node positions and graph layout
pos1 = nx.spring_layout(H)
for node in H.nodes:
    H.nodes[node]['pos'] = list(pos1[node])

# add edge trace
edge_x1 = []
edge_y1 = []
for edge in H.edges():
    x0, y0 = H.nodes[edge[0]]['pos']
    x1, y1 = H.nodes[edge[1]]['pos']
    edge_x1.append(x0)
    edge_x1.append(x1)
    edge_x1.append(None)
    edge_y1.append(y0)
    edge_y1.append(y1)
    edge_y1.append(None)

edge_trace1 = go.Scatter(
    x=edge_x1, y=edge_y1,
    line=dict(width=0.5, color='#888'),
    hoverinfo='none',
    mode='lines')

# add node trace
node_x1 = []
node_y1 = []
hover1 = []
for node in H.nodes():
    x, y = H.nodes[node]['pos']
    hovertext = "CpG Site(s): " + str(H.nodes[node]['cpg']) + "<br>" + "PIP Score(s): " + str(H.nodes[node]['cpg_pip'])
    node_x1.append(x)
    node_y1.append(y)
    hover1.append(hovertext)

node_trace1 = go.Scatter(
    x=node_x1, y=node_y1,
    hovertext = hover1,
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
            title='PIP Score',
            xanchor='left',
            titleside='right'),
        ))

# set text as node id
index1 = 0
node_text1 = []
for node in H.nodes():
    node_text1.append(nodes['id'][index1])
    index1 = index1 + 1
node_trace1.text = node_text1

# color node by pip score
i1 = 0
col1 = []
for node in H.nodes():
  col1.append(nodes['pip'][i1])
  i1 = i1 + 1
node_trace1['marker']['color'] = col1

# size node by pip score
j1 = 0
size1 = []
for node in H.nodes():
  size1.append(nodes['pip'][j1])
  j1 = j1 + 1
size_scaled1 = [n * 50 for n in size1]
node_trace1['marker']['size'] = size_scaled1

fig1 = go.Figure(data=[edge_trace1, node_trace1], layout = go.Layout(showlegend=False, hovermode='closest',
                        margin={'b': 40, 'l': 40, 'r': 40, 't': 40},
                        xaxis={'showgrid': False, 'zeroline': False, 'showticklabels': False},
                        yaxis={'showgrid': False, 'zeroline': False, 'showticklabels': False},
                        height=600,
                        clickmode='event+select'))

# filter nodes by pip score threshold and create subgraph
selected_nodes = [n for n,v in H.nodes(data=True) if v['pip'] >= 0.55]
G = H.subgraph(selected_nodes)

# setting node attributes
nx.set_node_attributes(G, nodes.set_index('id')['cpg'].to_dict(), 'cpg')
nx.set_node_attributes(G, nodes.set_index('id')['pip'].to_dict(), 'pip')
nx.set_node_attributes(G, nodes.set_index('id')['cpg_pip'].to_dict(), 'cpg_pip')

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
for node in G.nodes():
    x, y = G.nodes[node]['pos']
    hovertext = "CpG Site(s): " + str(G.nodes[node]['cpg']) + "<br>" + "PIP Score(s): " + str(G.nodes[node]['cpg_pip'])
    node_x.append(x)
    node_y.append(y)
    hover.append(hovertext)

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
            title='PIP Score',
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

fig = go.Figure(data=[edge_trace, node_trace], layout = go.Layout(showlegend=False, hovermode='closest',
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

app = dash.Dash()

fig_names = ['Default', '> 0.50']
fig_dropdown = html.Div([
    html.H5(children="Filter by PIP Score:"),
    dcc.Dropdown(
        id='fig_dropdown',
        options=[{'label': x, 'value': x} for x in fig_names],
        value=None
    )])
fig_plot = html.Div(id='fig_plot')
title = html.H1(children='Multioviz')
subtitle = html.H2(children='An interactive app for multi-omics gene regulatory network visualization')
app.layout = html.Div([title, subtitle, fig_dropdown, fig_plot])

@app.callback(
dash.dependencies.Output('fig_plot', 'children'),
[dash.dependencies.Input('fig_dropdown', 'value')])
def update_output(fig_name):
    return name_to_figure(fig_name)

def name_to_figure(fig_name):
    figure = fig1
    if fig_name == 'Default':
        figure = fig1
    if fig_name == '> 0.50':
        figure = fig
    return dcc.Graph(figure=figure)

app.run_server(debug=True, use_reloader=False)
