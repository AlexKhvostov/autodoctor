from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "openapi.yaml"
HTTP_METHODS = {"get", "post", "put", "patch", "delete"}
MUTATION_METHODS = {"post", "put", "patch", "delete"}


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def resolve_pointer(document, pointer):
    value = document
    for part in pointer.removeprefix("#/").split("/"):
        value = value[part.replace("~1", "/").replace("~0", "~")]
    return value


def main():
    document = yaml.safe_load(SOURCE.read_text(encoding="utf-8"))
    assert document["openapi"] == "3.1.0"

    references = [
        node["$ref"]
        for node in walk(document)
        if "$ref" in node and node["$ref"].startswith("#/")
    ]
    for reference in references:
        resolve_pointer(document, reference)

    operation_ids = []
    mutations = 0
    for path, path_item in document["paths"].items():
        for method, operation in path_item.items():
            if method not in HTTP_METHODS:
                continue
            operation_ids.append(operation["operationId"])
            if method in MUTATION_METHODS:
                mutations += 1
                parameters = operation.get("parameters", [])
                assert any(
                    parameter.get("$ref")
                    == "#/components/parameters/IdempotencyKey"
                    for parameter in parameters
                ), f"{method.upper()} {path} has no Idempotency-Key"

    assert len(operation_ids) == len(set(operation_ids)), "Duplicate operationId"
    print(
        f"OpenAPI valid: {len(document['paths'])} paths, "
        f"{len(operation_ids)} operations, {mutations} mutations, "
        f"{len(references)} internal references"
    )


if __name__ == "__main__":
    main()
