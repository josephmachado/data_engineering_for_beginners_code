FROM python:3.13-bookworm

WORKDIR /home/airflow

# Install Java
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    openjdk-17-jdk \
    wget \
    make \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Dynamically set Java home for amd64/arm64
RUN ln -s /usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture) /usr/lib/jvm/default-java
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Spark 
ENV SPARK_VERSION=4.0.1
ENV SPARK_HOME=/opt/spark
RUN wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz
ENV PATH=$PATH:$SPARK_HOME/bin
# Link for Iceberg from https://iceberg.apache.org/releases/
RUN wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-4.0_2.13/1.10.1/iceberg-spark-runtime-4.0_2.13-1.10.1.jar -P ${SPARK_HOME}/jars/
COPY ./spark_defaults.conf $SPARK_HOME/conf/spark-defaults.conf

# Install uv
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin/:$PATH"

# Airflow environment variables
ENV AIRFLOW_HOME=/home/airflow
ENV AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=true
ENV AIRFLOW__CORE__LOAD_EXAMPLES=false
ENV AIRFLOW__CORE__FERNET_KEY=''
ENV AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=true
ENV AIRFLOW__DAG_PROCESSOR__REFRESH_INTERVAL=3
ENV PYTHONDONTWRITEBYTECODE=1

# Install Airflow
ENV AIRFLOW_VERSION=3.1.3
ENV PYTHON_VERSION=3.13
ENV CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-no-providers-${PYTHON_VERSION}.txt"

RUN uv venv /home/airflow/.venv
RUN uv pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
RUN uv pip install pyspark==4.0.1 'pyspark[sql]==4.0.1'
RUN uv pip install ruff
RUN uv pip install jupyterlab
RUN uv pip install dbt dbt-core dbt-spark[session]
RUN uv pip install duckdb
RUN uv pip install plotly

# Copy IPython startup scripts
COPY ./ipython_scripts/startup/ /root/.ipython/profile_default/startup/

# mkdir warehouse and spark-events folder 
RUN mkdir -p /home/airflow/warehouse
RUN mkdir -p /home/airflow/spark-events

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

CMD ["/startup.sh"]
