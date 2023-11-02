### TO DO
### Docstring
### WILL empty pageCategories field cause issues?
### Add time partitioning and time argument features
### Add logic to evaluate whether the query has been successful
import functions_framework
@functions_framework.http
def function_analytics_events_transfer(request):
    """
    """
    from google.cloud import bigquery
    import os
    from concurrent.futures import as_completed
    env_project_name = os.environ.get("PROJECT_NAME")
    env_dataset_name = os.environ.get("DATASET_NAME")
    env_analytics_project_name = os.environ.get("ANALYTICS_PROJECT_NAME")
    client = bigquery.Client(project=env_project_name)
    # Perform a query.
    QUERY = (
       
        f'''
            INSERT INTO `{env_project_name}.{env_dataset_name}.view-item-event` (eventType, userPseudoId, eventTime, documents)
            SELECT
            'view-item' AS eventType,
            ga.user_pseudo_id AS userPseudoId,
            FORMAT_TIMESTAMP("%FT%TZ",TIMESTAMP_MICROS(ga.event_timestamp)) AS eventTime,
            (case when params.value.string_value is not null then [STRUCT(STRUCT(params.value.string_value AS id, CAST(NULL as string) as name) as documentDescriptor)] end) AS documents
            FROM `{env_analytics_project_name}.analytics_330577055.events_20230603` ga,
            UNNEST(event_params) AS params
            WHERE
            ga.event_name='page_view' AND
            params.key='content_id'

        ''')
    bq_location = os.environ.get("BQ_LOCATION")
    try:
        job = client.query(QUERY, location=bq_location)
        output = job.result()
        print(job.done())
        return 'Success'
    except Exception as e:
        raise(e)
