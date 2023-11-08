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

    bq_client = discoveryengine.BigQuerySource(
        project_id = 'search-api-v2-integration', 
        dataset_id= 'analytics_events_vertex', 
        table_id = 'view-item-event'
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
