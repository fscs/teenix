{
  crabfit-frontend,
  ...
}:
crabfit-frontend.overrideAttrs (
  final: prev: {
    pname = "crabrave-fit-frontend";

    patches = prev.patches ++ [
      ./crab-rave.patch
    ];
  }
)
