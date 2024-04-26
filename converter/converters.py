import typing


def convert_construct(construct):
    return ("{ name = %s, definition = %s, explanation = %s"
            % construct)


class TypedConstruct(typing.NamedTuple):
    name: str
    comment: str
    args: typing.List[str]
    cases: typing.List[typing.Tuple[str, typing.List[str]]]


def convert_alias(alias):
    doc = ["type alias", alias["name"]]

    if len(alias["args"]) > 0:
        doc.extend(alias["args"])

    definition = " ".join(doc)
    line = "= %s" % (alias["type"],)
    type_ = indent(line)

    definition = "%s %s" % (definition, type_)

    return make_record(alias["name"], definition, alias["comment"])


def convert_type(type_):
    doc = ["type", type_["name"]]

    if len(type_["args"]) > 0:
        doc.extend(type_["args"])

    definition = ' '.join(doc)

    if len(type_["cases"]) > 0:
        definition = "%s %s" % (definition, convert_union(type_["cases"]))

    return make_record(type_["name"], definition, type_["comment"])


def convert_union(tags: TypedConstruct.cases):
    union = []

    for index, tag in enumerate(tags):
        name, args = tag

        if index == 0:
            prefix = "="
        else:
            prefix = "|"

        if len(args) > 0:
            str_args = " ".join(args)
            line = "%s %s %s" % (prefix, name, str_args)
        else:
            line = "%s %s" % (prefix, name)

        union.append(indent(line))

    return " ".join(union)


def convert_function(fun):
    return make_record(fun["name"], fun["type"], fun["comment"])


def convert_module(module):
    types = []
    functions = []

    for alias in module["aliases"]:
        types.append(convert_alias(alias))

    for type_ in module["types"]:
        types.append(convert_type(type_))

    for fun in module["values"]:
        functions.append(convert_function(fun))

    definition = (
        "{ name = \"%s\", types = [ %s ], functions = [ %s ] }" %
        (module["name"], ", ".join(types), ", ".join(functions))
    )

    return definition


def convert_version(version):
    modules = []

    for module in version["modules"]:
        modules.append(convert_module(module))

    definition = (
        "{ number = \"%s\", modules = [ %s ] }" %
        (version["number"], ", ".join(modules))
    )

    return definition


def indent(line):
    return "%s%s" % (4 * " ", line)


def make_record(name, definition, explanation):
    return (
        "{ name = \"\"\"%s\"\"\", definition = \"\"\"%s\"\"\", explanation = "
        "\"\"\"%s\"\"\" }" %
        (name, definition, explanation)
    )
