default:
    @just --list

fmt:
    nix fmt

check:
    nix flake check

update input:
    nix flake update {{input}}
