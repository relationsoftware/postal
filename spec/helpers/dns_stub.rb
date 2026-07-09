# frozen_string_literal: true

# Hermetic DNS for the test suite.
#
# Several code paths perform real DNS lookups during normal processing - most
# notably ReceivedHeader#generate does a reverse lookup (ip_to_hostname) for
# every received message, and the domain/return-path checks resolve TXT/MX/CNAME
# records. Left unstubbed these hit real external authoritative nameservers,
# which makes the suite non-hermetic: it depends on live DNS, is slow, and hangs
# on CI runners that block outbound DNS to arbitrary servers.
#
# This stubs DNSResolver everywhere so no example performs real DNS. The
# returned resolver answers every lookup with an empty result by default;
# examples that need specific records stub them explicitly (e.g.
# `allow(domain.resolver).to receive(:txt).and_return([...])`), which still
# works because those stubs are applied on top of this fake.
#
# Examples tagged `:external_dns` (the DNSResolver end-to-end specs) opt out and
# use the real resolver.
RSpec.configure do |config|
  config.before do |example|
    next if example.metadata[:external_dns]

    fake = instance_double(DNSResolver, nameservers: [], timeout: 5)
    allow(fake).to receive(:a).and_return([])
    allow(fake).to receive(:aaaa).and_return([])
    allow(fake).to receive(:txt).and_return([])
    allow(fake).to receive(:mx).and_return([])
    allow(fake).to receive(:cname).and_return([])
    allow(fake).to receive(:effective_ns).and_return([])
    allow(fake).to receive(:ip_to_hostname).and_return(nil)

    allow(DNSResolver).to receive(:local).and_return(fake)
    allow(DNSResolver).to receive(:for_domain).and_return(fake)
  end
end
