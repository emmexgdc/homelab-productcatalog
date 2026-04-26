# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

RUN adduser -D -g '' appuser

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -o /go/bin/productcatalog .

# ---- Stage 2: Runtime ----
FROM gcr.io/distroless/static AS runtime

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /go/bin/productcatalog /app/server
COPY --from=builder /src/products.json /app/products.json

WORKDIR /app
USER appuser
EXPOSE 3550
ENV GOTRACEBACK=single
ENTRYPOINT ["/app/server"]
