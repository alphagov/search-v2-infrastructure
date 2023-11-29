import functions_framework
@functions_framework.http
def evaluate_search(request):
    request_json = request.get_json(silent=True)
    return 'hello world'
