from django.http import HttpResponse


def index(request):
    return HttpResponse(
        '<!doctype html><html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        '<title>Hello World | CSCI 4830</title></head>'
        '<body><h1>Hello, world!</h1><p>CSCI 4830 — Tech Exercise T2</p></body></html>'
    )
