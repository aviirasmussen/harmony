FROM alpine:3.12.1
RUN apk update
RUN apk add gcc g++ make git patch perl perl-dev curl wget perl-app-cpanminus
RUN apk add --no-cache bash
RUN cpanm Mojolicious Readonly Carp Data::Dumper FindBin
# Receive user and group from composer
ARG HARMONY_USER
ARG HARMONY_GROUP
# Create a group and user
RUN addgroup -S ${HARMONY_GROUP} && adduser -S ${HARMONY_USER} -G root ${HARMONY_GROUP}
# Tell docker that all future commands should run as the appuser user
USER ${HARMONY_USER}
WORKDIR /home/${HARMONY_USER}
ENV PERL5LIB=/usr/local/lib/perl5
ENV PATH=/usr/local/bin:$PATH
# perl harmony-app-start daemon -m production -p -l http://*:8080
#CMD ["perl", "harmony-app-start", "daemon", "-m production", "-p", "-l http://*:8080"]
CMD exec /bin/bash -c "trap : TERM INT; sleep 9999999999d & wait"
# expose port, let container see local interface to reach eachother OR let each container define a common network to talk and reach eachother.