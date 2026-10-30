_default:
    @just --list

[group('checks')]
fmt:
    nix fmt

[group('checks')]
check:
    nix flake check

# Update selected inputs, or every input when none are specified
[group('flake')]
update *inputs:
    nix flake update {{ inputs }} --commit-lock-file
