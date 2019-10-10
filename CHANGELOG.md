# Changelog

## Unreleased

_dust_

## 0.6.0 (2019-10-10)

- Add the `jrnd` (`0x06`) opcode, used in `(...)` aka maybe blocks. This avoids
  the overhead of `pick` lists for the simple behaviour of maybe blocks.
  ([@unleashy](https://github.com/unleashy))
- Fix self-references like `C = C/a` creating infinite loops in the compiled
  code; now they’re ignored and printed as-is.
  ([@unleashy](https://github.com/unleashy))

## 0.5.0 (2019-10-06)

- First official release of Koota
