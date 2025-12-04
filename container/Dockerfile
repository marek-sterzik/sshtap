FROM debian:bookworm

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		iptables \
        curl \
        openssh-server \
        openssh-client \
        net-tools \
        bridge-utils \
        iproute2 \
        iputils-ping \
        iw \
	    && \
	rm -rf /var/lib/apt/lists/* /etc/ssh/ssh_host_* /etc/ssh/sshd_config.d && \
    mkdir -p /run/sshd


COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /usr/local/bin/
COPY server-connect /usr/local/bin/

RUN mkdir /root/.ssh /persistent && chmod 0700 /root/.ssh

EXPOSE 22

ENTRYPOINT ["entrypoint.sh"]
CMD []
