# checkov:skip=CKV_DOCKER_7:Ensure the base image uses a non latest version tag
FROM registry.access.redhat.com/ubi9-minimal

RUN microdnf -y module enable nginx:1.22 && \
    microdnf -y --nodocs install python3.11 mariadb-connector-c libpq \
    nginx-core tar glibc-langpack-en && \
    microdnf -y --nodocs update && \
    microdnf clean all

EXPOSE 8080
COPY ./httpd-foreground /httpd-foreground
CMD /httpd-foreground

ENV PATH=/venv/bin:${PATH} \
    VIRTUAL_ENV=/venv      \
    LC_ALL=en_US.UTF-8     \
    LANG=en_US.UTF-8       \
    LANGUAGE=en_US.UTF-8

# copy virtualenv dir which has been built inside the kiwitcms/buildroot container
# this helps keep -devel dependencies outside of this image
COPY ./dist/venv/ /venv

COPY ./manage.py /Kiwi/
# create directories so we can properly set ownership for them
RUN mkdir -p /Kiwi/static /Kiwi/uploads /Kiwi/etc/cron.jobs
COPY ./etc/*.conf /Kiwi/etc/
COPY ./etc/cron.jobs/* /Kiwi/etc/cron.jobs/

RUN sed -i "s/tcms.settings.devel/tcms.settings.product/" /Kiwi/manage.py

# collect static files
RUN /Kiwi/manage.py collectstatic --noinput --link

# from now on execute as non-root
RUN chown -R 1001 /Kiwi/ /venv/
USER 1001
