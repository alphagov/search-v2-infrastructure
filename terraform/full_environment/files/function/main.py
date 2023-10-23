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
    from concurrent.futures import ThreadPoolExecutor, as_completed
    client = bigquery.Client(project="gds-search")
    # Perform a query.
    QUERY = (
        '''
        INSERT INTO `gds-search.GA4_transfer.search-event`
        SELECT 
        'hello' as eventType,
        'world' as userPseudoId,
        'my' as eventTime,
        [STRUCT(STRUCT('name' AS id, 'null' as name) as documentDesctiptor)] AS documents,
        NULL as searchQuery,
        [cast('' as string)] as pageCategories

        ''')
    executor = ThreadPoolExecutor(1)
    job = client.query(QUERY)

    for future in as_completed([executor.submit(job.done)]):
      return 'success'
