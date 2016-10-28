from ubuntu:xenial

ARG zcash_version=v1.0.0

WORKDIR /root
VOLUME /root/.zcash

RUN 	apt-get update && \
	apt-get install -y \
      build-essential pkg-config libc6-dev m4 g++-multilib \
      autoconf libtool ncurses-dev unzip git python \
      zlib1g-dev wget bsdmainutils automake && \

	git clone https://github.com/zcash/zcash.git -b ${zcash_version} && \
	cd zcash && \
	./zcutil/fetch-params.sh && \
	./zcutil/build.sh -j$(nproc) && \
	apt purge -y build-essential automake autoconf

EXPOSE 8232
EXPOSE 8233
EXPOSE 18232
EXPOSE 18233

#CMD ["sh", "-c", "/root/zcash/src/zcashd -server -rest -listen; while true; do sleep 300; done"]
CMD ["sh", "-c", "/root/zcash/src/zcashd -server -rest -listen"]
