FROM alpine:3 as base
RUN echo hi

FROM base AS final
COPY --from=base /etc/hostname /tmp/
CMD echo done
