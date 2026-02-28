from datetime import datetime, timedelta
from airflow.decorators import dag
from airflow.providers.standard.operators.bash import BashOperator

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


@dag(
    dag_id="generate_customer_marketing_metrics",
    description="A DAG to extract data, load into db and generate customer marketing metrics",
    schedule="@daily",  # More explicit than timedelta(days=1)
    start_date=datetime(2023, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["marketing", "analytics", "dbt"],
)
def generate_customer_marketing_metrics():
    transform_data = BashOperator(
        task_id="dbt_run",
        bash_command="cd $AIRFLOW_HOME && uv run dbt run --profiles-dir /home/airflow/tpch_analytics/ --project-dir /home/airflow/tpch_analytics/",
    )

    quality_check = BashOperator(
        task_id="dbt_test",
        bash_command="cd $AIRFLOW_HOME && uv run dbt test --profiles-dir /home/airflow/tpch_analytics/ --project-dir /home/airflow/tpch_analytics/",
    )

    generate_docs = BashOperator(
        task_id="dbt_docs_gen",
        bash_command="cd $AIRFLOW_HOME && uv run dbt docs generate --profiles-dir /home/airflow/tpch_analytics/ --project-dir /home/airflow/tpch_analytics/",
    )

    generate_dashboard = BashOperator(
        task_id="generate_dashboard",
        bash_command="cd $AIRFLOW_HOME && uv run python3 /home/airflow/tpch_analytics/dashboard.py",
    )

    transform_data >> quality_check >> generate_docs >> generate_dashboard


generate_customer_marketing_metrics()
