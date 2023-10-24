import functions_framework
@functions_framework.http
def hello_http(request):
    """HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    """
    from google.cloud import bigquery
    import os
    from concurrent.futures import ThreadPoolExecutor, as_completed
    env_project_name = os.environ.get("project_name")
    env_dataset_name = os.environ.get("dataset_name")
    client = bigquery.Client(project=env_project_name)
    # Perform a query.
    QUERY = (
       
        f'''
        INSERT INTO `{env_project_name}.{env_dataset_name}.view-item-event`
        SELECT
        'view-item' AS eventType,
            ga.user_pseudo_id AS userPseudoId,
            FORMAT_TIMESTAMP("%FT%TZ",TIMESTAMP_MICROS(ga.event_timestamp)) AS eventTime,
        (case when params.value.string_value is not null then [STRUCT(STRUCT(params.value.string_value AS id, CAST(NULL as string) as name) as documentDescriptor)] end) AS documents,
        CAST(NULL as string) as searchQuery,
        [''] as pageCategories
        FROM `ga4-analytics-352613.analytics_330577055.events_20230603` ga,
        UNNEST(event_params) AS params
        WHERE
        ga.event_name='page_view' AND
        params.key='content_id'


        ''')
    executor = ThreadPoolExecutor(1)
    job = client.query(QUERY)

    for future in as_completed([executor.submit(job.done)]):
      return 'success'
