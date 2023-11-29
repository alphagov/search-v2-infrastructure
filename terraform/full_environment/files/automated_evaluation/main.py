import functions_framework
@functions_framework.http
def automated_evaluation(request):
    request_json = request.get_json(silent=True)
    return 'hello world'
