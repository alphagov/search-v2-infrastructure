### TO DO
### Partition Date needs to be included in BigQuerySource
### Better exception handling
### Add error config to store error logs in gcs
### Change project name variable name to project id 

import functions_framework
@functions_framework.http
def import_user_events_vertex(request):
    '''
    '''
    from google.cloud import discoveryengine
    from google.type import date_pb2
    from datetime import datetime 
    import os
    
    env_project_name = os.environ.get("PROJECT_NAME")
    gcs_error_logs_url = os.environ.get("GCS_ERROR_LOGS_URL") + "/" + datetime.now().isoformat(timespec='seconds')

    request_json = request.get_json(silent=True)
    event_type = request_json.get("event_type") # `view-item` or `search`

    def yesterday():
        from datetime import datetime, timedelta
        yesterday = datetime.now() - timedelta(days=1)
        return yesterday.strftime('%Y-%m-%d')

    source_date = yesterday() if request_json.get("date") is None else request_json.get("date")
    source_date_datetime = datetime.strptime(source_date, '%Y-%m-%d')
    source_date = date_pb2.Date(year= source_date_datetime.year, month = source_date_datetime.month, day=source_date_datetime.day)

    bq_client = discoveryengine.BigQuerySource(
        project_id = f'{env_project_name}', 
        dataset_id= 'analytics_events_vertex', 
        table_id = f'{event_type}-event',
        partition_date = source_date
        )

    client = discoveryengine.UserEventServiceClient()
    error_config= discoveryengine.ImportErrorConfig()
    error_config.gcs_prefix=gcs_error_logs_url

    import_request = discoveryengine.ImportUserEventsRequest(
        bigquery_source = bq_client,
        parent = f'projects/{env_project_name}/locations/global/collections/default_collection/dataStores/govuk_content' 
    )


    try:
        operation = client.import_user_events(request=import_request)
        result = operation.result()
        return result
    except Exception as e:
        raise e
