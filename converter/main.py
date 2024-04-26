import json
import os
import requests_html

DOCS_URL = ("http://package.elm-lang.org/packages/"
            "%(user)s/"
            "%(namespace)s/"
            "%(version)s/documentation.json")

LIBS = [
    { "user": "elm-lang",
      "namespace": "core",
      "versions": ["5.1.1","5.1.0","5.0.0","4.0.5","4.0.4","4.0.3",
                   "4.0.2","4.0.1","4.0.0","3.0.0","2.1.0","2.0.1",
                   "2.0.0","1.1.1","1.1.0","1.0.0"]
    },
    { "user": "elm-lang",
      "namespace": "http",
      "versions": ["1.0.0"]
    },
    { "user": "elm-lang",
      "namespace": "html",
      "versions": ["1.0.0", "1.1.0", "2.0.0"]
    },
]

MAIN_LIBS = [
    {"user": "elm-lang",
     "namespace": "core",
     "version": "5.1.1"
    },
    {"user": "elm-lang",
     "namespace": "http",
     "version": "1.0.0"
    },
    {"user": "elm-lang",
     "namespace": "html",
     "version": "2.0.0"
    },
    {"user": "elm-lang",
     "namespace": "svg",
     "version": "2.0.0"
    },
    {"user": "evancz",
     "namespace": "elm-markdown",
     "version": "3.0.2"
    },
    {"user": "elm-lang",
     "namespace": "dom",
     "version": "1.1.1"
    },
    {"user": "elm-lang",
     "namespace": "navigation",
     "version": "2.1.0"
    },
    {"user": "elm-lang",
     "namespace": "geolocation",
     "version": "1.0.2"
    },
    {"user": "elm-lang",
     "namespace": "page-visibility",
     "version": "1.0.1"
    },
    {"user": "elm-lang",
     "namespace": "websocket",
     "version": "1.0.2"
    },
    {"user": "elm-lang",
     "namespace": "mouse",
     "version": "1.0.1"
    },
    {"user": "elm-lang",
     "namespace": "window",
     "version": "1.0.1"
    },
    {"user": "elm-lang",
     "namespace": "keyboard",
     "version": "1.0.1"
    }
]


def get_docs(user, namespace, version):
    session = requests_html.HTMLSession()
    url_config = {"user": user, "namespace": namespace, "version": version}
    response = session.get(DOCS_URL % url_config)

    return response.json()
    #write_response(user, namespace, version, response)


def write_response(user, namespace, version, response):
    path = "%s_%s" % (user, namespace)

    try:
        os.mkdir(path)
    except FileExistsError:
        pass

    with open("%s/%s.json" % (path, version), "w") as f:
        f.write(response.text)


def main():
    packages = []

    for lib in MAIN_LIBS:
        name = "%s/%s" % (lib["user"], lib["namespace"])
        docs = get_docs(lib["user"], lib["namespace"], lib["version"])
        package = {"name": name, "modules": docs}
        packages.append(package)

    with open("full-db.json", "w") as f:
        f.write(json.dumps({"docs": packages}))

    """
    for lib in LIBS:
        if lib["namespace"] == "core":
            continue

        for version in lib["versions"]:
            print("Retrieving %s/%s" % (lib["user"], lib["namespace"]))
            get_docs(lib["user"], lib["namespace"], version)
    """


if __name__ == '__main__':
    main()
