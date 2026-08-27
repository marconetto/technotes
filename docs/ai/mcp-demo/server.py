import os
import signal
from fastmcp import FastMCP

# Instantiate the server
mcp = FastMCP("System Admin Tools")


@mcp.tool()
def terminate_process(pid: int) -> str:
    """Terminates a local process running on the host machine using its PID.

    Args:
        pid: The Process ID to terminate.
    """
    try:
        os.kill(pid, signal.SIGTERM)
        return f"Successfully sent SIGTERM to process {pid}."
    except ProcessLookupError:
        return f"Error: Process ID {pid} was not found."
    except PermissionError:
        return f"Error: Permission denied to terminate process {pid}."
    except Exception as e:
        return f"Error terminating process: {str(e)}"


if __name__ == "__main__":
    mcp.run()
