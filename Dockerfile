FROM alpine:3.20

LABEL name="azure-rest-api-token" \
      vendor="Densify" \
      maintainer="support@densify.com" \
      version="1.0.1" \
      release="1.0.1" \
      summary="Azure REST API token" \
      description="Gets a bearer token for a Microsoft Entra app for usage with Azure REST API"

# add required packages and remove apk completely
RUN apk --no-cache add curl jq && rm -f /sbin/apk

RUN addgroup -g 3000 densify && adduser -h /home/densify -s /bin/sh -u 3000 -G densify -g "" -D densify && chmod 755 /home/densify

COPY --chown=densify:densify --chmod=644 ./LICENSE /licenses/LICENSE

WORKDIR /home/densify
COPY --chown=densify:densify --chmod=755 ./get-token.sh bin/
USER 3000
CMD ["/home/densify/bin/get-token.sh"]
