# net_address versions

## 0.1.0

- basic IP, IP.Range, and IP.Subnet modules with proper Enum features
- IPv6 features missing from many Range and Subnet functions.

## 0.1.1

- includes Mac module for mac addresses

## 0.1.2

- ability to generate matching sigil-i
- random mac addresses

## 0.1.3

- add prefix, bitlength, and netmask to IP.Subnet

## 0.1.4

- support for arista/cisco style mac address strings
- support for generic is_ip guard

## 0.2.0

- support for IPv6 ranges and CIDRs
- support for ports (IPv4)
- support for the `:socket` module `:sockaddr_in4` type
- IP.random

## 0.2.1

- fix mix project to have the correct name
- enable bang functions for mac address

## 0.2.2
- add ~i//config mode that returns a ip/subnet tuple.


## FUTURE VERSIONS

- support for ports (IPv6) with `:sockaddr_in6`
- better `IP.random/1,2` algorithms
