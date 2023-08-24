import psutil
import os
import time
import sys

KLIPPY_PROCESS_NAME = "klippy.py"

def set_high_priority(pid, method="nice"):
    if method == "chrt":
        cmd = f"sudo chrt --verbose --all-tasks --pid 1 {pid}"
    elif method == "nice":
        cmd = f"sudo renice -n -20 -p {pid}"
    else:
        raise ValueError(f"Unsupported priority method: {method}")
    
    os.system(cmd)

def main(method="nice"):
    while True:
        try:
            # Check if Klippy is running
            klippy_process = None
            for process in psutil.process_iter(["pid", "name", "cmdline"]):
                if KLIPPY_PROCESS_NAME in process.info["name"] or KLIPPY_PROCESS_NAME in ' '.join(process.info["cmdline"]):
                    klippy_process = process
                    break

            if klippy_process:
                set_high_priority(klippy_process.info["pid"], method=method)
                
        except Exception as e:
            print(f"Error: {e}")

        time.sleep(5)  # check every 5 seconds

if __name__ == "__main__":
    allowed_methods = ["chrt", "nice"]
    method = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in allowed_methods else "nice"
    main(method=method)
