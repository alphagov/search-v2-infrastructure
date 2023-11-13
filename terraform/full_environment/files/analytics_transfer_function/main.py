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

    request_json = request.get_json(silent=True)

    source_date = yesterday() if request_json.get("date") is None else request_json.get("date")
    event_type = request_json.get("event_type")

    client = bigquery.Client(project=env_project_name)

    all_queries = {
        'view-item' : {
            'query' : f'''
                INSERT INTO `{env_project_name}.{env_dataset_name}.view-item-event` (eventType, userPseudoId, eventTime, documents)
                SELECT
                'view-item' AS eventType,
                ga.user_pseudo_id AS userPseudoId,
                FORMAT_TIMESTAMP("%FT%TZ",TIMESTAMP_MICROS(ga.event_timestamp)) AS eventTime,
                (case when params.value.string_value is not null then [STRUCT(params.value.string_value AS id, CAST(NULL as string) as name)] end) AS documents
                FROM `{env_analytics_project_name}.analytics_330577055.events_{source_date}` ga,
                UNNEST(event_params) AS params
                WHERE
                ga.event_name='page_view' AND
                params.key='content_id'

            '''},
        'search': {'query': f'''
                INSERT INTO `{env_project_name}.{env_dataset_name}.search-event` (_PARTITIONTIME, eventType, userPseudoId, eventTime, searchInfo, documents)
                with events AS
                (
                    SELECT
                        TIMESTAMP_MICROS(ga.event_timestamp) AS eventDate,
                        'search' AS eventType,
                        ga.user_pseudo_id AS userPseudoId,
                        FORMAT_TIMESTAMP("%FT%TZ",TIMESTAMP_MICROS(ga.event_timestamp)) AS eventTime,
                        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'search_term') AS searchQuery,
                        item_params.value.string_value as id,
                        max(item.item_id),
                        item.item_list_index
                    FROM `{env_analytics_project_name}.analytics_330577055.events_{source_date}`  ga
                    ,
                    UNNEST(items) AS item,
                    UNNEST(item.item_params) as item_params
                    WHERE
                        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'publishing_app') = "search-api" AND
                        EXISTS (SELECT 1 FROM UNNEST(event_params) WHERE key = 'search_term') AND
                        event_name='view_item_list'
                    GROUP BY eventDate, eventTime,userPseudoId,eventType,searchQuery, id, item_list_index
                )
                SELECT 
                    eventDate as _PARTITIONTIME,
                    eventType,
                    userPseudoId,
                    eventTime,
                    STRUCT(searchQuery) as searchInfo,
                    ARRAY_AGG(STRUCT(id as id, CAST(NULL as string) as name) ORDER BY SAFE_CAST(item_list_index AS INT64) ) as documents
                FROM events
                WHERE id IS NOT NULL AND
                    searchQuery IS NOT NULL AND
                    SAFE_CAST(item_list_index AS INT64)<=20
                group by eventDate, eventTime,userPseudoId,eventType,searchQuery
                   '''}
    }

    try:
        job = client.query(all_queries.get(event_type).get('query'), location=bq_location)
        output = job.result()
        print(job.done())
        return 'Success'
    except Exception as e:
        raise(e)
