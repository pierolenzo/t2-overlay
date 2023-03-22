# t2 overlay
Hi! This is the portage overlay for T2 macs. Further information can be found at the [t2linux wiki](https://wiki.t2linux.org/).

To add this repository to portage:

```
emerge -av app-eselect/eselect-repository dev-vcs/git
eselect repository add t2 git https://codeberg.org/vimproved/t2-overlay.git
```
