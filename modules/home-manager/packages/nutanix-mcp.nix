# Nutanix V4 API MCP server (github.com/nutanix/ntnx-api-mcp-server).
#
# Built from source rather than installed with uvx/pipx: the console script
# is named `nutanix-mcp`, which on PyPI belongs to an unrelated third-party
# project (github.com/veg-salad/nutanix_mcp). Fetching by that name would
# hand Prism Central credentials to code Nutanix doesn't publish.
{lib, python3Packages, fetchFromGitHub}:
python3Packages.buildPythonApplication rec {
  pname = "ntnx-api-mcp-server";
  version = "0.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "nutanix";
    repo = "ntnx-api-mcp-server";
    tag = "v${version}";
    hash = "sha256-qHObOIAgmlI5YIEJIeO+vkwWIJgMOZDQ8Bs8RjagbEA=";
  };

  build-system = [python3Packages.hatchling];

  dependencies = with python3Packages; [
    mcp
    httpx
    pyyaml
    pydantic
    pydantic-settings
    python-dotenv
    tenacity
  ];

  # No test suite ships in the tag
  doCheck = false;

  pythonImportsCheck = ["src.cli"];

  meta = {
    description = "Nutanix Prism Central V4 API MCP server (Technical Preview)";
    homepage = "https://github.com/nutanix/ntnx-api-mcp-server";
    license = lib.licenses.asl20;
    mainProgram = "nutanix-mcp";
  };
}
