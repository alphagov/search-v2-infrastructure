### TO DO
### Partition Date needs to be included in BigQuerySource
### Better exception handling
### Add error config to store error logs in gcs
### Parameterise the parent string

import functions_framework
@functions_framework.http
def import_user_events_vertex(request):
    '''
    '''
    from google.cloud import discoveryengine
    from google.protobuf import timestamp_pb2
    from datetime import datetime 

    request_json = request.get_json(silent=True)
    event_type = request_json.get("event_type") # `view-item` or `search`

    def yesterday():
        from datetime import datetime, timedelta
        yesterday = datetime.now() - timedelta(days=1)
        return yesterday.strftime('%Y-%m-%d')

    source_date = yesterday() if request_json.get("date") is None else request_json.get("date")
    timestamp = timestamp_pb2.Timestamp()
    timestamp.FromDatetime(datetime.strptime(source_date, '%Y-%m-%d'))

    bq_client = discoveryengine.BigQuerySource(
        project_id = 'search-api-v2-integration', 
        dataset_id= 'analytics_events_vertex', 
        table_id = f'{event_type}-event',
        partition_date = timestamp
        )

    client = discoveryengine.UserEventServiceClient()

    import_request = discoveryengine.ImportUserEventsRequest(
        bigquery_source = bq_client,
        parent = 'projects/search-api-v2-integration/locations/global/collections/default_collection/dataStores/govuk_content'
    )


    try:
        client.import_user_events(request=import_request)
        return 'Success'
    except Exception as e:
        raise e
