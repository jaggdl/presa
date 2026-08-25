# frozen_string_literal: true

# FastMcp::Transports::RackTransport caches "filtered copies" of the server
# (the per-request view with tools filtered for a workspace). The cache key is
# derived only from request path/params/headers, so editing a workspace's
# services never changes the key and the cached filtered copy (with stale,
# pre-built tool classes) is reused across requests.
#
# Since our tools are derived live from Current.workspace.services in the
# filter_tools block, we bypass the filtered-copy cache entirely: each request
# rebuilds the filtered server, so new/edited services are reflected
# immediately — no dev-server or MCP-client restart required.
module FastMcpRackTransportNoFilterCache
  def get_server_for_request(request, env)
    if env[FastMcp::Transports::RackTransport::SERVER_ENV_KEY]
      return env[FastMcp::Transports::RackTransport::SERVER_ENV_KEY]
    end

    return @server unless @server.contains_filters?

    @logger.debug("Server has filters, building a fresh filtered copy (cache bypassed)")
    @server.create_filtered_copy(request)
  end
end

FastMcp::Transports::RackTransport.prepend(FastMcpRackTransportNoFilterCache)
