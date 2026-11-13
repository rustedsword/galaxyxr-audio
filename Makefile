M4 ?= m4
ALSATPLG ?= alsatplg
DESTDIR ?=

card := Samsung-Galaxy-XR
firmware := $(DESTDIR)/usr/lib/firmware/qcom/sm8450
ucm := $(DESTDIR)/usr/share/alsa/ucm2

all: obj/$(card)-tplg.bin

obj/$(card).conf: topology/$(card).m4
	mkdir -p obj
	$(M4) -I topology/audioreach-topology $< > $@

obj/$(card)-tplg.bin: obj/$(card).conf
	$(ALSATPLG) -c $< -o $@

install: all
	install -D -m 644 obj/$(card)-tplg.bin $(firmware)/$(card)-tplg.bin
	install -D -m 644 -t $(ucm)/Samsung/galaxy-xr ucm2/Samsung/galaxy-xr/$(card).conf ucm2/Samsung/galaxy-xr/HiFi.conf
	install -d $(ucm)/conf.d/sm8450
	ln -sf ../../Samsung/galaxy-xr/$(card).conf $(ucm)/conf.d/sm8450/$(card).conf
	install -D -m 755 -t $(DESTDIR)/usr/libexec/galaxyxr-audio libexec/amp-calibration
	install -D -m 644 -t $(DESTDIR)/usr/lib/systemd/system systemd/galaxyxr-amp-calibration.service
	install -D -m 644 -t $(DESTDIR)/usr/lib/udev/rules.d udev/80-galaxyxr-audio.rules

clean:
	rm -rf obj

.PHONY: all install clean
