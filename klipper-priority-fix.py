import os
import time
import sys

import psutil

KLIPPY_PROCESS_NAME = "klippy.py"
KLIPPY_NICE_VALUE = -20

def set_high_priority(pid, method="nice"):
    if method == "chrt": # https://man7.org/linux/man-pages/man1/chrt.1.html
        ## FIXME: This is fairly dangerous, so hopefully nice is all we need...
        cmd = f"chrt --verbose --all-tasks --pid 1 {pid} || sudo chrt --verbose --all-tasks --pid 1 {pid}"
    elif method == "nice": # https://man7.org/linux/man-pages/man1/renice.1.html
        # Check if current priority is already set to KLIPPY_NICE_VALUE
        if psutil.Process(pid).nice() == KLIPPY_NICE_VALUE:
            return
        print(f"Setting priority of {KLIPPY_PROCESS_NAME} with pid {pid} to {KLIPPY_NICE_VALUE}")
        cmd = f"renice -n {KLIPPY_NICE_VALUE} -p {pid} || sudo renice -n {KLIPPY_NICE_VALUE} -p {pid}"
    else:
        raise ValueError(f"Unsupported priority method: {method}")

    os.system(cmd)

def main(method="nice"):
    while True:
        try:
            # Check if Klippy is running
            # klippy_process = None
            for process in psutil.process_iter(["pid", "name", "cmdline"]):
                if KLIPPY_PROCESS_NAME in process.info["name"] or KLIPPY_PROCESS_NAME in ' '.join(process.info["cmdline"]):
                    # klippy_process = process
                    # break
                    # Apply to all Klippy processes
                    if process:
                        set_high_priority(process.info["pid"], method=method)

            # if klippy_process:
                # set_high_priority(klippy_process.info["pid"], method=method)
                
        except Exception as e:
            print(f"Error: {e}")

        time.sleep(5)  # check every 5 seconds

if __name__ == "__main__":
    allowed_methods = ["chrt", "nice"]
    method = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in allowed_methods else "nice"
    main(method=method)
