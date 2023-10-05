import functions_framework

# Register an HTTP function with the Functions Framework
@functions_framework.http
def my_http_function(request,projectid,projectname,datasetname,tablename,query):
  # Your code here  
  from google.cloud import bigquery
  table_id="{}.{}.{}".format(projectname,datasetname,tablename)
  query = query.format(table_id)
  client = bigquery.Client()

  # Perform a query.
  QUERY = (
      'SELECT name FROM `bigquery-public-data.usa_names.usa_1910_2013` '
      'WHERE state = "TX" '
      'LIMIT 100')
  query_job = client.query(QUERY)  # API request

  # Return an HTTP response
  return 'OK'