FROM ubuntu:latest

# install dev tools
RUN apt-get update
RUN apt-get install -y curl tar sudo openssh-server openssh-client rsync

# python and snakebite 
RUN apt-get update \
  && apt-get install -y python3-pip python3-dev \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 --no-cache-dir install --upgrade pip \
  && rm -rf /var/lib/apt/lists/*
RUN pip3 install snakebite-py3

# passwordless ssh
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


# java
RUN apt-get install -y openjdk-8-jdk 
# RUN mkdir -p /usr/java/default && \
#     curl -Ls 'https://www.oracle.com/webapps/redirect/signon?nexturl=https://download.oracle.com/otn/java/jdk/8u333-b02/2dee051a5d0647d5be72a7c0abff270e/jdk-8u333-linux-aarch64.tar.gz' -H 'Cookie: oraclelicense=accept-securebackup-cookie' | \
#     tar --strip-components=1 -xz -C /usr/java/default/
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/default

ENV PATH $PATH:$JAVA_HOME/bin

# hadoop
RUN wget  https://downloads.apache.org/hadoop/common/hadoop-3.3.2/hadoop-3.3.2.tar.gz
RUN tar -xvf  hadoop-3.3.2.tar.gz -C /usr/local/
RUN cd /usr/local && ln -s ./hadoop-3.3.2 hadoop

ENV HADOOP_HOME /usr/local/hadoop
RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/default\nexport HADOOP_HOME=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN . $HADOOP_HOME/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_HOME/input
RUN cp $HADOOP_HOME/etc/hadoop/*.xml $HADOOP_HOME/input

# pseudo distributed
ADD core-site.xml.template $HADOOP_HOME/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

RUN $HADOOP_HOME/bin/hdfs namenode -format


ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config




# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

# Hadoop User
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/default
# Hadoop Start Service
RUN service ssh start && $HADOOP_HOME/etc/hadoop/hadoop-env.sh && $HADOOP_HOME/sbin/start-dfs.sh && $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/root
RUN service ssh start && $HADOOP_HOME/etc/hadoop/hadoop-env.sh && $HADOOP_HOME/sbin/start-dfs.sh && $HADOOP_HOME/bin/hdfs dfs -put $HADOOP_HOME/etc/hadoop/ input

CMD ["/etc/bootstrap.sh", "-d"]
