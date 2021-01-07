# The only way in which these Dockerfiles can't be normal Dockerfiles is that
# they must _not_ specify a FROM line, whereas it is normally obligatory as the
# first directive in any Dockerfile. Instead, the GNUmakefile must provide the
# inheritence relationship through a _TERMINATES or _EXTENDS attribute there.

RUN apt-get install -y kmod

COPY ["script.sh", "/"]
COPY ["delete-install.sh", "/"]
COPY ["delete-source.sh", "/"]
