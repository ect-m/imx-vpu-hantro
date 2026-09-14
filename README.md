# imx-vpu-hantro

Combined NXP i.MX8MP VPU userspace package for Pi.MX8.

Package contains VC8000E encoder, Hantro G1/G2 libraries, and `vsiv4l2daemon`.
Target kernel ABI: NXP `linux-imx` `lf-6.18.y`, Pi.MX8 `6.18.20-ecd-imx8m`.

## Build

Build uses Docker only:

```bash
./scripts/build-deb.sh
```

Output: `out/imx-vpu-hantro_<version>_arm64.deb`.

The source archives are pinned by filename and SHA256 in `sources.env`. The
daemon build consumes NXP UAPI headers from `kernel-uapi/`; CI refreshes and
checks these against the selected kernel source before compiling.

## Release

Push a tag such as `v1.9.0`. GitHub Actions builds the package, runs ELF and
package-content checks, and publishes the `.deb` as a GitHub Release asset.
`ect-m/images` pins that release tag and downloads the asset; image builds do
not compile VPU sources.
