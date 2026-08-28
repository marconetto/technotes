# MCP

MCP (Model Context Protocol) was created initially by Anthropic and it is
considered to be the "USB-C port for AI applications". MCP provides a secure and
standardized "language" for LLMs to communicate with external data, apps, and
services. Using MCP, AI applications can connect to data sources (e.g. local
files, databases), tools (e.g. search engines, calculators) and workflows (e.g.
specialized prompts)—enabling them to access key information and perform tasks.

Without MCP: (i) each AI app had custom integrations; (ii) tools were tightly coupled to one app; (iii) reuse was hard; and (iv) security boundaries were unclear.

With MCP: (i) tools run as separate servers; (ii) models communicate using a well-defined protocol; (iii) tools can be reused by any MCP-compatible model; (iv) permissions are explicit and controlled.


The key participants in the MCP architecture are:

- *MCP Host:* The AI application that coordinates and manages one or multiple MCP clients
- *MCP Client:* A component that maintains a connection to an MCP server and obtains context from an MCP server for the MCP host to use
- *MCP Server:* A program that provides context to MCP clients


MCP defines three core primitives that servers can expose:

- *Tools:* Executable functions that AI applications can invoke to perform actions (e.g., file operations, API calls, database queries)
- *Resources:* Data sources that provide contextual information to AI applications (e.g., file contents, database records, API responses)
- *Prompts:* Reusable templates that help structure interactions with language models (e.g., system prompts, few-shot examples)

For instance, an MCP server can provide context about a database. It can expose
tools for querying the database, a resource that contains the schema of the
database, and a prompt that includes few-shot examples for interacting with the
tools.

To build an MCP server, one can use different frameworks. For python, one can
use, for instance, [FastMCP](https://pypi.org/project/fastmcp/) or [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk).

### Example with FastMCP

Install framework:

```
# 1. Create a project directory and step into it
mkdir mcp-demo && cd mcp-demo

# 2. Create an isolated virtual environment named .venv
python3 -m venv .venv

# 3. Activate the virtual environment
source .venv/bin/activate

# 4. Upgrade pip and install FastMCP
pip install --upgrade pip
pip install fastmcp
```


Show details of FastMCP:
```
fastmcp version
```


Create `server.py` file inside `mcp-demo` folder

```python title="Dockerfile"
--8<-- "docs/ai/mcp/mcp-demo/server.py"
```



Show some details of the server
```
fastmcp inspect server.py
```



Call tool without LLM.
```
fastmcp call server.py terminate_process pid=99999
```

This basically:

- Client simulation: The FastMCP CLI acts as the MCP client (taking the place of the LLM).
- Schema validation: It checks pid=99999 against your function signature (pid: int).
- Execution: It spins up your server over stdio, executes terminate_process(pid=99999), and returns the raw output string or JSON payload.



##### Adding LLM + MCP

If one is using claude CLI (assume already installed, setup, etc):

```
DIR=<mcp-demo directory>
claude mcp add system-admin -- $DIR/.venv/bin/python $DIR/server.py
```

`system-admin` is the local name given to this MCP server connection

Claude will say `"Added stdio MCP server system-admin...`"


See list of mcp servers:

```
claude mcp list
```

One can also check for details of the server

```
claude mcp get system-admin
```


Once Claude CLI is started ask "terminate process 9999 using system-admin mcp".
If one does not specify, claude will suggest some bash commands for doing so,
ignoring the mcp.


To remove the mpc server server:

```
claude mcp remove system-admin
```



### References

- Anthropic MCP Announcement: <https://www.anthropic.com/news/model-context-protocol>
- Model Context Protocol docs:
<https://modelcontextprotocol.io/docs/getting-started/intro>
- FastMCP: <https://pypi.org/project/fastmcp/>
- FastMCP quick start: <https://gofastmcp.com/getting-started/quickstart>
- MCP Python SDK: <https://github.com/modelcontextprotocol/python-sdk>
