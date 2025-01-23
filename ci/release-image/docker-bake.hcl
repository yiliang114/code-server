# Use this file from the top of the repo, with `-f ci/release-image/docker-bake.hcl`

# Uses env var VERSION if set;
# normally, this is set by ci/lib.sh
variable "VERSION" {
    default = "latest"
}

variable "DOCKER_REGISTRY" {
    default = "docker.io/codercom/code-server"
}

variable "GITHUB_REGISTRY" {
    default = "ghcr.io/coder/code-server"
}

group "default" {
    targets = [
        "code-server-debian-12",
        "code-server-ubuntu-focal",
    ]
}

function "prepend_hyphen_if_not_null" {
    params = [tag]
    result = notequal("","${tag}") ? "-${tag}" : "${tag}"
}

# use empty tag (tag="") to generate default tags
function "gen_tags" {
    params = [registry, tag]
    result = notequal("","${registry}") ? [
        notequal("", "${tag}") ? "${registry}:${tag}" : "${registry}:latest",
        notequal("latest",VERSION) ? "${registry}:${VERSION}${prepend_hyphen_if_not_null(tag)}" : "",
    ] : []
}

# helper function to generate tags for docker registry and github registry.
# set (DOCKER|GITHUB)_REGISTRY="" to disable corresponding registry
function "gen_tags_for_docker_and_ghcr" {
    params = [tag]
    result = concat(
        gen_tags("${DOCKER_REGISTRY}", "${tag}"),
        gen_tags("${GITHUB_REGISTRY}", "${tag}"),
    )
}

target "code-server-debian-12" {
    dockerfile = "ci/release-image/Dockerfile"
    tags = concat(
        gen_tags_for_docker_and_ghcr(""),
        gen_tags_for_docker_and_ghcr("debian"),
        gen_tags_for_docker_and_ghcr("bookworm"),
    )
    platforms = ["linux/amd64", "linux/arm64"]
}

target "code-server-ubuntu-focal" {
    dockerfile = "ci/release-image/Dockerfile"
    tags = concat(
        gen_tags_for_docker_and_ghcr("ubuntu"),
        gen_tags_for_docker_and_ghcr("focal"),
    )
    args = {
        BASE = "ubuntu:focal"
    }
    platforms = ["linux/amd64", "linux/arm64"]
}
