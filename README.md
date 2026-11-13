# galaxyxr-audio

The Galaxy XR's sound card setup for mainline kernels: the files the
kernel and PipeWire need for the speakers, the microphones and
DisplayPort audio. The 5.10 kernel takes another road, Qualcomm's
userspace stack (`gxr-audio`). Both can be installed together: all of
this is tied to the mainline kernel's sound card (`SamsungGalaxyXR`)
and does nothing under 5.10, and `gxr-audio` starts only where the
vendor kernel's audio device exists.

| Installed file | Role |
|---|---|
| `/usr/lib/firmware/qcom/sm8450/Samsung-Galaxy-XR-tplg.bin` | AudioReach topology: the DSP graphs the kernel opens |
| `/usr/share/alsa/ucm2/Samsung/galaxy-xr/` | ALSA UCM profile: devices and mixer settings for PipeWire |
| `/usr/share/alsa/ucm2/conf.d/sm8450/Samsung-Galaxy-XR.conf` | Link by which alsa-lib finds the profile |
| `/usr/libexec/galaxyxr-audio/amp-calibration`, `galaxyxr-amp-calibration.service`, `80-galaxyxr-audio.rules` | Factory calibration for the speaker amplifiers' protection firmware, run when the sound card appears |

## Topology

`topology/Samsung-Galaxy-XR.m4`, built by `make` with m4 and alsatplg.
The macros in `topology/audioreach-topology` come from
[audioreach-topology](https://github.com/linux-msm/audioreach-topology)
(commit d6bb205).

| PCM | Stream | Backend |
|---|---|---|
| 0 | MultiMedia1, playback | Speakers: TDM on LPAIF_RXTX primary, four slots of 32 bits, through Samsung's speaker processing |
| 1 | MultiMedia2, playback | DisplayPort |
| 2 | MultiMedia3, capture | Microphones through the VA macro |

All streams are 48 kHz, 16 bit, stereo. Samsung's ADSP firmware takes
the container type of newer AudioReach (`110000` in the stream macros).

The speaker link carries 24 bit in four channels, one slot per
amplifier: woofer left, woofer right, tweeter left, tweeter right. In
front of it sits Samsung's speaker processing, a module built into its
ADSP firmware (0x10001f01): it splits the stereo stream between woofers
and tweeters near 2.4 kHz and compresses it, as on Android. The module
works only as Samsung runs it: behind an MFC that makes 24 bit and the
channels FL FR LB RB, in a specialized container of a low-power
subgraph, with its one parameter set. The macros for this are in
`topology/galaxyxr`; the kernel side (the older TDM sink, the MFC's
fixed format, the parameter) is on the `galaxy-xr-audio` branch.

## UCM profile

| Device | PCM | Sets up |
|---|---|---|
| Speaker | 0 | Enables the four CS35L45 amplifiers |
| DisplayPort | 1 | Follows the `DP0 Jack` control |
| Mic | 2 | Digital microphones 0 and 1, +16 dB |

Each amplifier plays its own TDM slot, which the kernel sets from the
link's slot mask.

## Speaker protection

Each amplifier (CS35L45) has a DSP that runs Cirrus Logic's protection
firmware with Samsung's tuning for its speaker: it models the coil
temperature and the cone excursion from the amplifier's voltage and
current monitors and limits the signal before the speaker is harmed. The
firmware and the two tunings (woofer, tweeter) are vendor files that
`galaxyxr-firmware` links into `/usr/lib/firmware/cirrus`.

The UCM profile routes the amplifiers through the firmware (`DACPCM
Source` DSP_TX1) at the gains of Samsung's mixer paths: 13 dB analog,
0 dB digital. Its boot sequence sets that up, and the Speaker device
sets the path and the gains again whenever PipeWire enables it. With
`DACPCM Source` on ASP_RX1 or ASP_RX2 an amplifier plays unprotected.

`galaxyxr-amp-calibration.service` gives the firmware the factory
calibration of this unit, from `/run/platform/sec_efs/cirrus`:

| File | Value | Firmware control |
|---|---|---|
| `rdc_cal*` | Speaker resistance, 5.857 ohm / 8192 a step | `CAL_R`, with `CAL_STATUS` 1 and `CAL_CHECKSUM` |
| `temp_cal` | Temperature of that measurement, degrees C | `CAL_AMBIENT` |
| `vsc_cal*`, `isc_cal*` | Trims of the voltage and current sense | `VSC`, `ISC`, with `VIMON_CAL_STATE` 2 |

The file suffixes are `_b` (left woofer), `_br` (right woofer), none
(left tweeter) and `_r` (right tweeter). Without a factory file the
resistance is the default of Samsung's device tree, 4.6 ohm for a woofer
and 6.8 ohm for a tweeter. The firmware takes the resistance when it
starts, so the service restarts each amplifier's DSP; it leaves the
firmware loaded (`DSP1 Preload Switch`), 5 to 10 s in all.

At shutdown the service unloads the firmware before `alsactl` stores the
mixer. The firmware's controls include its whole working memory, and a
state stored with the firmware loaded brings that memory back at the
next boot, after which the kernel writes it at every start of the
firmware: an amplifier stored while paused stays silent. If that
happened (`alsactl store` by hand during playback), delete the
`state.SamsungGalaxyXR` block from `/var/lib/alsa/asound.state` and
reboot.

While sound plays, the firmware says what it uses:

    amixer -c 0 cget name='WooferL DSP1 Protection cd CAL_SET_STATUS'
    amixer -c 0 cget name='WooferL DSP1 Protection cd CAL_R_SELECTED'
    amixer -c 0 cget name='WooferL DSP1 Protection cd CSPL_TEMPERATURE'

`CAL_SET_STATUS` 2 is a calibrated firmware, 1 one on its tuning's
default resistance; `CSPL_TEMPERATURE` is the coil temperature in
1/16384 degrees C. An amplifier that sleeps (3 s after the sound stops)
answers these with "Operation not permitted".

## Publishing

`packaging/publish.sh` builds the source package in an Ubuntu container
and uploads it to `ppa:lightofmysoul/gxr`; `--no-upload --test-build`
builds the package without uploading.

## License

MIT; the topology and its macros are BSD-3-Clause.
