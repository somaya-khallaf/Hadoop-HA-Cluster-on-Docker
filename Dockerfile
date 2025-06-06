# Stage 1: Base image with common Hadoop setup
FROM ubuntu:22.04 

ARG HADOOP_USER=hadoop
ARG HADOOP_GROUP=hadoop
ARG HADOOP_VERSION=3.3.6
ARG ZOOKEEPER_VERSION=3.6.3

# 1. System setup
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y vim sudo ssh wget netcat openjdk-8-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. User setup
RUN addgroup $HADOOP_GROUP && \
    adduser --disabled-password --ingroup $HADOOP_GROUP $HADOOP_USER && \
    echo "$HADOOP_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG sudo $HADOOP_USER 


ADD https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz /tmp/ 
RUN tar -xzf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop && \
    rm -f /tmp/hadoop-${HADOOP_VERSION}.tar.gz


ADD https://archive.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz -C /usr/local/ && \
    mv /usr/local/apache-zookeeper-${ZOOKEEPER_VERSION}-bin /usr/local/zookeeper && \
    rm -f /tmp/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz

# Create directories
RUN mkdir -p /hadoopdata/namenode && \
    mkdir -p /hadoopdata/journalnode && \
    mkdir -p /hadoopdata/datanode && \
    mkdir -p /usr/local/zookeeper/data && \
    mkdir -p /usr/local/zookeeper/logs && \
    mkdir -p /usr/local/config && \
    chown -R hadoop:hadoop /hadoopdata /usr/local/hadoop /usr/local/zookeeper && \
    chmod -R 755 /hadoopdata/

ENV HADOOP_HOME=/usr/local/hadoop 
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:/usr/local/zookeeper/bin
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV HADOOP_YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
RUN echo 'JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> $HADOOP_CONF_DIR/hadoop-env.sh 

COPY --chown=$HADOOP_USER:$HADOOP_GROUP zookeeper/zoo.cfg /usr/local/zookeeper/conf/zoo.cfg
COPY --chown=$HADOOP_USER:$HADOOP_GROUP ./scripts/entrypoint.sh /usr/local/scripts/
COPY --chown=$HADOOP_USER:$HADOOP_GROUP code/ /code/
COPY --chown=$HADOOP_USER:$HADOOP_GROUP ./hadoop/* $HADOOP_CONF_DIR/
RUN chmod +x /usr/local/scripts/*.sh


USER $HADOOP_USER 
WORKDIR /home/$HADOOP_USER
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys  && \
    chmod 640 ~/.ssh/authorized_keys  

ENTRYPOINT ["/usr/local/scripts/entrypoint.sh"]