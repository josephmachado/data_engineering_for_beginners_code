FROM apache/airflow:2.9.2
RUN pip install uv

COPY requirements.txt $AIRFLOW_HOME
RUN uv pip install -r $AIRFLOW_HOME/requirements.txt

COPY run_ddl.py $AIRFLOW_HOME
COPY generate_data.py $AIRFLOW_HOME

User root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    default-jdk

RUN curl https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -o spark-3.5.1-bin-hadoop3.tgz

# Change permissions of the downloaded tarball
RUN chmod 755 spark-3.5.1-bin-hadoop3.tgz

# Create the target directory and extract the tarball to it
RUN mkdir -p /opt/spark && tar xvzf spark-3.5.1-bin-hadoop3.tgz --directory /opt/spark --strip-components=1

ENV JAVA_HOME='/usr/lib/jvm/java-17-openjdk-amd64'
ENV PATH=$PATH:$JAVA_HOME/bin
ENV SPARK_HOME='/opt/spark'
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
