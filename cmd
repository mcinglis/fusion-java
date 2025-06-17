#!/bin/sh

set -eu

# Determine the script's source path and directory:
CMD_PATH="$0"
CMD_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

# Determine the container CLI to use:
for CONTAINER in "${CONTAINER:-}" container podman nerdctl finch docker; do
    if command -v "$CONTAINER" >/dev/null; then
        break
    fi
done

VERBOSE=0

_print_usage() {
    cat <<EOF
$CMD_PATH [OPTION..] [--] COMMAND [ARG..]

Commands for working with the Ion Fusion source tree.

Options:
  -h        Print available options and commands.
  -x        Run with 'set -x' and verbose output.

Commands:
$(< "$CMD_PATH" sed -n '/^## /p' | sed 's/^## /  /')
EOF
}

_error() {
    printf >&2 "$CMD_PATH: error: %s\n" "$*"
    exit 1
}

_require() {
    if [ -z "$1" ]; then
        _error "$2"
    fi
}

## ctrbuild             Build an Ion Fusion container.
cmd_ctrbuild() {
    # set default option values:
    _base="corretto-8"
    _target="sdk"
    # parse arguments and options:
    OPTIND=1
    while getopts ':b:t:' opt; do
        case "$opt" in
            b)
                _base="$OPTARG"
                ;;
            t)
                _target="$OPTARG"
                ;;
            \?)
                _error "invalid option for ctrbuild: -$OPTARG"
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    #
    # for arg; do
    #     echo $arg
    #     case "$arg" in
    #         -b|--base)
    #             _base="${2:-}"
    #             _require "$_base" "'ctrbuild --base' requires an argument"
    #             shift 2
    #             ;;
    #         -t|--target)
    #             _target="${2:-}"
    #             _require "$_target" "'ctrbuild --target' requires an argument"
    #             shift 2
    #             ;;
    #         *)
    #             _error "unrecognized argument '$arg'"
    #             ;;
    #     esac
    # done
    # run the container build:
    "$CONTAINER" build \
        --target sdk \
        --build-arg BASE="$_base" \
        --tag "fusion:sdk-$_base" \
        "$CMD_DIR"


    # for _base in corretto-8 temurin-8 zulu-8 alpine-openjdk-8 ubuntu-openjdk-8 rhel-openjdk-8; do
    #     ctr build -t "fusion:sdk-$base" --target sdk --build-arg BASE="$_base" .
    #     ctr run --rm --entrypoint sh fusion-sdk-$base -c '
    #     echo "public class Example {
    #         public static void main(String[] args) {
    #             dev.ionfusion.fusion.cli.Cli.main(args);
    #             System.out.println(\"Hello, Fusion integration!\");
    #         }
    #     }" >Example.java
    #     cp="$(echo /opt/fusion/lib/*.jar | tr " " :)"
    #     javac -cp "$cp" Example.java
    #     java -cp ".:$cp" Example eval "(+ 1 1)"'
    #     ctr build -t fusion-$base --build-arg BASE=$base .
    #     ctr run --rm fusion-$base eval '(+ 123 456)'
    # done
}

cmd() {
    OPTIND=1
    while getopts ':hx' opt; do
        case "$opt" in
            h)
                _print_usage
                exit 0
                ;;
            x)
                set -x
                VERBOSE=1
                ;;
            \?)
                _error "invalid global option: -$OPTARG"
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    if [ $# -eq 0 ]; then
        _print_usage >&2
        exit 1
    else
        command="$1"
        shift
        "cmd_$command" "$@"
    fi
}

cmd "$@"

