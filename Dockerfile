# 1. Airflow 공식 이미지를 기반으로 시작합니다.
FROM apache/airflow:2.11.0

# 2. 루트 사용자로 전환하여 Oracle Instant Client 등 시스템 라이브러리를 설치합니다.
USER root

# Oracle Instant Client 설치에 필요한 패키지
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libaio1 \
        unzip \
        curl \
        unixodbc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. Oracle Instant Client 19c 다운로드 및 설치
ARG ORACLE_CLIENT_VERSION="19.18"
ENV ORACLE_HOME=/opt/oracle/instantclient_19_18

# 기존 LD_LIBRARY_PATH 값($LD_LIBRARY_PATH)을 유지하면서 앞에 $ORACLE_HOME을 추가
ENV LD_LIBRARY_PATH=${ORACLE_HOME}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

RUN mkdir -p /opt/oracle && \
    curl -o instantclient-basic.zip https://download.oracle.com/otn_software/linux/instantclient/1918000/instantclient-basic-linux.x64-19.18.0.0.0dbru.zip && \
    unzip instantclient-basic.zip -d /opt/oracle/ && \
    rm instantclient-basic.zip && \
    echo ${ORACLE_HOME} > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

# 4. 다시 Airflow 사용자로 전환합니다.
USER airflow

# 5. 제약 조건 파일을 사용하여 DB Provider 설치
# Python 3.12 버전에 맞는 제약 조건 파일 사용
RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.11.0/constraints-3.12.txt" \
    apache-airflow-providers-oracle \
    apache-airflow-providers-microsoft-mssql \
    apache-airflow-providers-mysql \
    apache-airflow-providers-mongo \
    apache-airflow-providers-postgres

# 추가: Oracle 환경변수를 Airflow 사용자 환경에도 설정
ENV ORACLE_HOME=/opt/oracle/instantclient_19_18
ENV LD_LIBRARY_PATH=${ORACLE_HOME}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}