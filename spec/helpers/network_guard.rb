# frozen_string_literal: true

# Hermetic-network guard for the test suite.
#
# The suite must never open a real outbound connection. On the CI runner a
# stray connect - e.g. Net::SMTP reaching a test IP on the blocked port 25 (our
# Net::SMTP#tcp_socket override uses a plain TCPSocket.open with no connect
# timeout), or an unstubbed DNS lookup - black-holes and hangs the entire run
# unkillably. Intercept Ruby-level TCP connects and raise immediately for any
# non-loopback target, turning a silent hang into a fast, named failure that
# points straight at the offending spec.
#
# The database is unaffected: mysql2 connects in its C extension, below this
# Ruby-level layer.
require "socket"

module TestNetworkGuard

  LOOPBACK = ["localhost", "ip6-localhost", "::1", "0.0.0.0", "::"].freeze

  module_function

  def allowed?(host)
    h = host.to_s
    LOOPBACK.include?(h) || h.start_with?("127.")
  end

  def forbid!(host, port)
    site = caller.grep(/\/(spec|app|lib|config)\//).first(12)
    raise "Hermetic test violation: real network connect to #{host}:#{port}. " \
          "Stub this DNS/SMTP/HTTP call so the suite stays self-contained.\n  " +
          site.join("\n  ")
  end

end

class TCPSocket

  class << self

    [:open, :new].each do |m|
      orig = "__guard_orig_#{m}"
      alias_method orig, m
      define_method(m) do |host, *args, **kwargs|
        TestNetworkGuard.forbid!(host, args.first) unless TestNetworkGuard.allowed?(host)
        send(orig, host, *args, **kwargs)
      end
    end

  end

end

class Socket

  class << self

    alias __guard_orig_tcp tcp
    def tcp(host, port, *args, **kwargs, &block)
      TestNetworkGuard.forbid!(host, port) unless TestNetworkGuard.allowed?(host)
      __guard_orig_tcp(host, port, *args, **kwargs, &block)
    end

  end

end
