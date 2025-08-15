#!/usr/bin/env python3

import os
import signal
import sys
from threading import Event
from pathlib import Path
from dataclasses import dataclass

from pywayland.client.display import Display
from pywayland.protocol.idle_inhibit_unstable_v1.zwp_idle_inhibit_manager_v1 import (
    ZwpIdleInhibitManagerV1,
)
from pywayland.protocol.wayland.wl_compositor import WlCompositor
from pywayland.protocol.wayland.wl_registry import WlRegistryProxy
from pywayland.protocol.wayland.wl_surface import WlSurface

# === CONFIG ===
PIDFILE = Path("/tmp/wayland_idle_inhibitor.pid")

@dataclass
class GlobalRegistry:
    surface: WlSurface | None = None
    inhibit_manager: ZwpIdleInhibitManagerV1 | None = None

def is_running() -> int | None:
    if PIDFILE.exists():
        try:
            with PIDFILE.open() as f:
                pid = int(f.read())
            os.kill(pid, 0)
            return pid
        except (OSError, ValueError):
            PIDFILE.unlink()
    return None

def start_inhibitor():
    print("Starting idle inhibitor...")
    done = Event()
    signal.signal(signal.SIGINT, lambda *_: done.set())
    signal.signal(signal.SIGTERM, lambda *_: done.set())

    def write_pid():
        with PIDFILE.open("w") as f:
            f.write(str(os.getpid()))

    def remove_pid():
        if PIDFILE.exists():
            PIDFILE.unlink()

    write_pid()

    global_registry = GlobalRegistry()
    display = Display()
    display.connect()

    registry = display.get_registry()
    registry.user_data = global_registry
    registry.dispatcher["global"] = handle_registry_global

    def shutdown():
        display.dispatch()
        display.roundtrip()
        display.disconnect()

    display.dispatch()
    display.roundtrip()

    if not global_registry.surface or not global_registry.inhibit_manager:
        print("Wayland does not support idle_inhibit_unstable_v1.")
        shutdown()
        remove_pid()
        sys.exit(1)

    inhibitor = global_registry.inhibit_manager.create_inhibitor(global_registry.surface)
    print("Inhibitor activated.")
    os.system("eww update idle_inhibit=true")  # Update eww *immediately* on start
    done.wait()

    print("Shutting down idle inhibitor...")
    inhibitor.destroy()
    shutdown()
    remove_pid()
    os.system("eww update idle_inhibit=false")  # Update eww on exit as well (optional)

def handle_registry_global(wl_registry: WlRegistryProxy, id_num: int, iface_name: str, version: int):
    global_registry: GlobalRegistry = wl_registry.user_data or GlobalRegistry()
    if iface_name == "wl_compositor":
        compositor = wl_registry.bind(id_num, WlCompositor, version)
        global_registry.surface = compositor.create_surface()
    elif iface_name == "zwp_idle_inhibit_manager_v1":
        global_registry.inhibit_manager = wl_registry.bind(id_num, ZwpIdleInhibitManagerV1, version)

def main():
    pid = is_running()
    if pid:
        print(f"Inhibitor running (PID {pid}) – terminating.")
        os.kill(pid, signal.SIGTERM)
        os.system("eww update idle_inhibit=false")  # Update eww immediately on stop
        sys.exit(1)  # Indicates inhibitor stopped
    else:
        start_inhibitor()
        sys.exit(0)  # Indicates inhibitor started

if __name__ == "__main__":
    main()
