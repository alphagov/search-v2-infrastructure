### TO DO
### Docstring
### Add time partitioning and time argument features
### Add logic to evaluate whether the query has been successful
### Document format of date
import functions_framework
@functions_framework.http
def function_analytics_events_transfer(request):
    """
    """
    from google.cloud import bigquery
    import os
    
    env_project_name = os.environ.get("PROJECT_NAME")
    env_dataset_name = os.environ.get("DATASET_NAME")
    env_analytics_project_name = os.environ.get("ANALYTICS_PROJECT_NAME")
    bq_location = os.environ.get("BQ_LOCATION")

    def yesterday():
        from datetime import datetime, timedelta
        yesterday = datetime.now() - timedelta(days=1)
        return yesterday.strftime('%Y%m%d')


    from datetime import date
    source_date = yesterday() if request.args.get("date") is not None else request.args.get("date")
    event_type = request.args.get("event_type")

    client = bigquery.Client(project=env_project_name)

    all_queries = {
        'view-item' : {
            'query' : f'''
                INSERT INTO `{env_project_name}.{env_dataset_name}.view-item-event` (eventType, userPseudoId, eventTime, documents)
                SELECT
                'view-item' AS eventType,
                ga.user_pseudo_id AS userPseudoId,
                FORMAT_TIMESTAMP("%FT%TZ",TIMESTAMP_MICROS(ga.event_timestamp)) AS eventTime,
                (case when params.value.string_value is not null then [STRUCT(STRUCT(params.value.string_value AS id, CAST(NULL as string) as name) as documentDescriptor)] end) AS documents
                FROM `{env_analytics_project_name}.analytics_330577055.events_{source_date}` ga,
                UNNEST(event_params) AS params
                WHERE
                ga.event_name='page_view' AND
                params.key='content_id'

            '''},
        'search': {'query': 'search_query'}
    }

    try:
        job = client.query(all_queries.get(event_type).query, location=bq_location)
        output = job.result()
        print(job.done())
        return 'Success'
    except Exception as e:
        raise(e)
