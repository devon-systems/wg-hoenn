"""Validate the public IPv4 inventory before consumers update their locks."""

import ipaddress
import json
import sys

with open(sys.argv[1]) as source:
    network = json.load(source)

subnet = ipaddress.IPv4Network(network["subnet"])
assert subnet.prefixlen == network["prefixLength"], (
    "subnet prefix differs from prefixLength"
)
assert 1 <= network["listenPort"] <= 65535, "invalid listenPort"
host, port = network["endpoint"].rsplit(":", 1)
ipaddress.IPv4Address(host)
assert int(port) == network["listenPort"], "endpoint port differs from listenPort"
assert network["hub"] in network["nodes"], "hub is missing from inventory"
for name, node in network["nodes"].items():
    address = ipaddress.IPv4Address(node["address"])
    assert address in subnet, f"{name}: {address} is outside {subnet}"
    assert address not in (subnet.network_address, subnet.broadcast_address), (
        f"{name}: {address} is a network or broadcast address"
    )
