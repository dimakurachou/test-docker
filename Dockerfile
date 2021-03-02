FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

ARG ANDROID_HOME=/usr/local/android-sdk

# setup global environment
# setup environment variables for android sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    ANDROID_PLATFORM_VERSION=28 \
    ANDROID_BUILD_TOOLS_VERSION=29.0.3 \
    ANDROID_EMULATOR_ARCH=x86_64 \
    ANDROID_EMULATOR_TYPE=google_apis \
    TOOLS_HOME=/usr/local/tools \
    PATH=${PATH}:${TOOLS_HOME} \
    LD_LIBRARY_PATH="$ANDROID_HOME/emulator/lib64:$ANDROID_HOME/emulator/lib64/qt/lib"

# Expect requires tzdata, which requires a timezone specified
RUN ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

RUN apt-get -qq update && \
       apt-get install -qqy --no-install-recommends \
       bridge-utils \
       bzip2 \
       curl \
       # expect: Passing commands to telnet
       expect \
       git-core \
       html2text \
       lib32gcc1 \
       lib32ncurses5 \
       lib32stdc++6 \
       lib32z1 \
       libc6-i386 \
       libqt5svg5 \
       libqt5widgets5 \
       # libvirt-bin: Virtualisation for emulator
       libvirt-bin \
       openjdk-8-jdk \
       # qemu-kvm: Hardware acceleration for emulator
       qemu-kvm \
       # telnet: Communicating with emulator
       telnet \
       # ubuntu-vm-builder: Building VM for emulator
       ubuntu-vm-builder \
       unzip \
     && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV DISPLAY=:20

# Configurating Java
RUN rm -f /etc/ssl/certs/java/cacerts; /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN mkdir -p $ANDROID_SDK_HOME/.android/ \
  &&  touch $ANDROID_SDK_HOME/.android/repositories.cfg

ENV PATH ${PATH}:${TOOLS_HOME}

RUN wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk-tools.zip \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
    && rm android-sdk-tools.zip

#RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip -O android-sdk-tools.zip \
#    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
#    && rm android-sdk-tools.zip

ENV ADB_INSTALL_TIMEOUT 120
ENV PATH=${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

RUN yes | sdkmanager --licenses && sdkmanager tools platform-tools

RUN wget -q https://dl.google.com/android/repository/emulator-linux-5598178.zip -O emulator.zip \
    && rm -rf ${ANDROID_HOME}/emulator \
    && unzip -q emulator.zip -d ${ANDROID_HOME} \
    && rm emulator.zip

RUN sdkmanager \
  "build-tools;29.0.1" \
  "build-tools;29.0.2" \
  "build-tools;29.0.3" \
  "build-tools;30.0.0" \
  "build-tools;30.0.1" \
  "build-tools;30.0.2"

RUN yes | sdkmanager "platforms;android-$ANDROID_PLATFORM_VERSION" "extras;google;m2repository" \
    && yes | sdkmanager "system-images;android-$ANDROID_PLATFORM_VERSION;$ANDROID_EMULATOR_TYPE;$ANDROID_EMULATOR_ARCH" \
    && echo no | avdmanager create avd -n android_emulator -k "system-images;android-$ANDROID_PLATFORM_VERSION;$ANDROID_EMULATOR_TYPE;$ANDROID_EMULATOR_ARCH"

RUN touch /etc/ld.so.conf.d/android_libs.conf \
    && echo "$ANDROID_SDK_HOME/emulator/lib64/qt/lib" >> /etc/ld.so.conf.d/android_libs.conf \
    && echo "$ANDROID_SDK_HOME/emulator/lib64" >> /etc/ld.so.conf.d/android_libs.conf
