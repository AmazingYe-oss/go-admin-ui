# go-admin-ui

Frontend SPA for the go-admin platform. Vue 2 + Element UI. Deployed together with the backend ([go-admin](https://github.com/AmazingYe-oss/go-admin)) on the same ArgoCD ApplicationSet cadence, so image tags stay aligned across releases.

- Framework: Vue 2.7 + Element UI
- Build: Vue CLI 4 / webpack 4 / Babel
- Default dev port: `:8080`
- Production bundle: served by `nginx:alpine`

## Layout

```
src/                     Source (views / api / components / router / store / layout)
public/                  Static assets (favicon, index.html, etc.)
build/                   Build scripts
plop-templates/          CRUD page skeleton generator
docker/nginx.conf        Nginx config (reverse proxy to backend, gzip, cache headers)
Dockerfile               Multi-stage build (node builder + nginx runtime)
.github/workflows/ci.yml CI pipeline (lint -> build -> gitops-bump)
```

## Docker build

```dockerfile
# syntax=docker/dockerfile:1.7
FROM node:18-alpine AS builder
WORKDIR /app
RUN apk add --no-cache python3 make g++      # node-sass build deps
COPY package.json ./
RUN npm install --registry=https://registry.npmmirror.com --legacy-peer-deps
COPY . .
RUN NODE_OPTIONS=--openssl-legacy-provider npm run build:prod

FROM nginx:alpine AS runtime
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

Resulting image is ~107 MB. The runtime stage contains only the compiled `dist/` and an Nginx config — `node_modules` is not shipped.

### Why these flags

- `--legacy-peer-deps`: the project's pinned ESLint v6 has unresolved peer-dep conflicts with newer webpack; the flag bypasses the install-time check.
- `NODE_OPTIONS=--openssl-legacy-provider`: Node 18 ships OpenSSL 3.0, which removed the legacy MD4 hash that webpack 4's `crypto.createHash` calls. Without this flag the build dies with `error:0308010C`.
- `registry.npmmirror.com`: cuts install time on Aliyun-region runners roughly 3x vs the public registry.

## CI

`.github/workflows/ci.yml` runs three stages:

| Stage         | Tool                                       | On failure |
|---------------|--------------------------------------------|------------|
| `lint`        | ESLint                                     | block      |
| `build`       | `docker buildx`                            | block      |
| `gitops-bump` | `yq` patches Helm `image.tag` in `infra-gitops` | warn, do not block |

There is no `test` stage — this is a UI bundle, not a service.

## Deployment

Helm chart lives in [infra-gitops/go-admin-ui-chart](https://github.com/AmazingYe-oss/infra-gitops/tree/main/go-admin-ui-chart). `gitops-bump` writes the new `sha-<short>` tag into `values-ui-{dev,staging,prod}.yaml`. ArgoCD picks it up within ~30-60 s.

To make sure UI and backend release in lockstep, the backend CI and the frontend CI both bump the same Helm release name (`go-admin-<env>` / `go-admin-ui-<env>`) within a couple of minutes of each other. In practice the gap is < 5 min; the user-visible effect is that UI deploys do not run ahead of the backend binary they call.

## Local development

```bash
git clone https://github.com/AmazingYe-oss/go-admin-ui.git
cd go-admin-ui
npm install --legacy-peer-deps
npm run serve                 # dev server on :8080, proxies /api to backend
npm run build:prod            # production build, output in dist/
```

Backend address is selected via `.env.development` / `.env.staging` / `.env.production`.

## Known limitations

- Vue 2 is end-of-life. Upgrading to Vue 3 + Element Plus is on the roadmap but not started — the diff would touch every `.vue` file's `slot-scope` syntax.
- `node-sass` is deprecated upstream. The build works today but is fragile; long-term the project should switch to `sass` (Dart Sass).
- Nginx config does not currently emit Prometheus-format access logs, so request rate / 5xx rate from the UI layer is not observable end-to-end.

## Related repos

| Repo | Role |
|------|------|
| [go-admin](https://github.com/AmazingYe-oss/go-admin) | Backend service |
| [infra-gitops](https://github.com/AmazingYe-oss/infra-gitops) | ArgoCD + Helm config |

## License

MIT