Public CA-only fixtures for MLH-118; no leaf certificates or private keys.

- Intermediate and anchor PEMs: https://emudhra.we-have-a-problem.com/impacted-intermediates.json and https://emudhra.we-have-a-problem.com/roots.json
- The cross-signed TLS issuer is the CA certificate from `chains/regular/dv-g3b-emudhra.we-have-a-problem.com.pem` in https://emudhra.we-have-a-problem.com/chains.zip. The leaf was discarded.
- Fingerprints corroborated against https://bugzilla.mozilla.org/show_bug.cgi?id=2083449 and https://support.apple.com/en-us/149555 on 2026-11-12.

The two `EM DV TLS CA - G3B` certificates share the compromised public key but use distinct issuer paths: emSign TLS G3 → ECC G3, and the Sectigo AAA cross-sign. The tests verify the original CA certificates offline, without generating forged certificates or opening sockets.
