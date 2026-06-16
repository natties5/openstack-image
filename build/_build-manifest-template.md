# {App} Build Manifest

> Non-secret golden image build history. Do not record runtime/OpenStack context.

---

## Latest Build

| Field | Value |
|---|---|
| App | {app} |
| Status | pending |
| Build date | YYYY-MM-DD |
| Base OS | Ubuntu 26.04 |
| Source guide | `build/apps/{app}/{app}.md` |

## Host Packages

Keep this section minimal. Record only packages needed to reproduce the Docker stack.

| Package | Version |
|---|---|
| docker-ce | — |
| docker-ce-cli | — |
| containerd.io | — |
| docker-buildx-plugin | — |
| docker-compose-plugin | — |

## Runtime Tools

| Tool | Version |
|---|---|
| Docker Engine | — |
| Docker Compose | — |
| Docker Buildx | — |

## Container Images

| Image | Digest |
|---|---|
| image:tag | pending |

## Build Notes

- —

## Changelog

| Date | Change |
|---|---|
| YYYY-MM-DD | Initial build manifest template created |

## Do Not Record

- Image name
- Glance ID
- Server ID
- Floating IP or VM IP
- Hostname
- OpenStack project/user/auth context
- Passwords, tokens, private keys, or runtime credentials
